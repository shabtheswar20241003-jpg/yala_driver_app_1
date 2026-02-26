// lib/features/map/screens/live_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class LiveMapScreen extends StatefulWidget {
  final String driverId;
  final String databaseUrl;

  const LiveMapScreen({
    super.key,
    required this.driverId,
    this.databaseUrl =
        "https://yala-driver-app1-default-rtdb.asia-southeast1.firebasedatabase.app/",
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  late final FirebaseDatabase _db;
  StreamSubscription<DatabaseEvent>? _driversAddedSub;
  StreamSubscription<DatabaseEvent>? _driversChangedSub;
  StreamSubscription<DatabaseEvent>? _driversRemovedSub;
  StreamSubscription<DatabaseEvent>? _ownLocationSub;

  LatLng? _ownLocation;
  final Map<String, LatLng> _otherJeeps = {};
  final List<_Zone> _restrictedZones = [];

  bool _hasShownZoneWarning = false;
  String? _currentZoneId;
  bool _hasCenteredOnce =
      false; // NEW: ensures first recenter only happens once

  @override
  void initState() {
    super.initState();
    _db = FirebaseDatabase(databaseURL: widget.databaseUrl);
    _listenRestrictedZones();
    _listenOtherJeeps();
    _listenOwnLocation();
  }

  @override
  void dispose() {
    _driversAddedSub?.cancel();
    _driversChangedSub?.cancel();
    _driversRemovedSub?.cancel();
    _ownLocationSub?.cancel();
    super.dispose();
  }

  // ---------- Firebase listeners ----------

  void _listenOtherJeeps() {
    final ref = _db.ref('drivers');

    _driversAddedSub = ref.onChildAdded.listen((event) {
      final id = event.snapshot.key;
      final loc = event.snapshot.child('location').value;
      if (id == null || loc == null) return;
      _updateJeepFromSnapshot(id, event.snapshot);
    });

    _driversChangedSub = ref.onChildChanged.listen((event) {
      final id = event.snapshot.key;
      if (id == null) return;
      _updateJeepFromSnapshot(id, event.snapshot);
    });

    _driversRemovedSub = ref.onChildRemoved.listen((event) {
      final id = event.snapshot.key;
      if (id == null) return;
      setState(() {
        _otherJeeps.remove(id);
      });
    });
  }

  void _updateJeepFromSnapshot(String id, DataSnapshot snapshot) {
    final locSnap = snapshot.child('location');
    if (!locSnap.exists) return;
    final data = locSnap.value as Map<Object?, Object?>?;
    if (data == null) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    if (id == widget.driverId) {
      setState(() {
        _ownLocation = LatLng(lat, lng);
      });
      _checkRestrictedZones(LatLng(lat, lng));
      _centerMapOnce(); // NEW: recenter map on first location
      return;
    }

    setState(() {
      _otherJeeps[id] = LatLng(lat, lng);
    });
  }

  void _listenOwnLocation() {
    final ref = _db.ref('drivers/${widget.driverId}/location');
    print('[MapScreen] listening to drivers/${widget.driverId}/location');

    _ownLocationSub = ref.onValue.listen(
      (event) {
        final v = event.snapshot.value as Map<Object?, Object?>?;
        print('[MapScreen] own location snapshot: ${event.snapshot.value}');
        if (v == null) return;
        final lat = (v['lat'] as num?)?.toDouble();
        final lng = (v['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;

        setState(() {
          _ownLocation = LatLng(lat, lng);
        });
        _checkRestrictedZones(LatLng(lat, lng));
        _centerMapOnce(); // NEW: recenter map on first location
      },
      onError: (err) {
        print('[MapScreen] ownLocationSub error: $err');
      },
    );
  }

  // ---------- Center map helper ----------
  void _centerMapOnce() {
    if (_ownLocation != null && !_hasCenteredOnce) {
      _mapController.move(_ownLocation!, 15.0);
      _hasCenteredOnce = true;
      print('[MapScreen] Map centered to $_ownLocation');
    }
  }

  // ---------- Restricted zones ----------
  void _listenRestrictedZones() async {
    final ref = _db.ref('restricted_zones');
    final snap = await ref.get();
    if (snap.exists) {
      final map = snap.value as Map<Object?, Object?>;
      map.forEach((key, value) {
        final v = value as Map<Object?, Object?>?;
        if (v == null) return;
        final poly = <LatLng>[];
        final rawPoly = v['polygon'] as List<dynamic>?;
        if (rawPoly != null) {
          for (final p in rawPoly) {
            final m = p as Map<Object?, Object?>;
            final lat = (m['lat'] as num?)?.toDouble();
            final lng = (m['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) poly.add(LatLng(lat, lng));
          }
        }
        final zone = _Zone(
          id: key.toString(),
          name: v['name']?.toString() ?? 'Zone',
          polygon: poly,
          active: (v['active'] ?? true) == true,
        );
        _restrictedZones.add(zone);
      });
      setState(() {});
    }

    ref.onChildChanged.listen((event) {
      _restrictedZones.clear();
      _listenRestrictedZones();
    });
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  void _checkRestrictedZones(LatLng location) {
    for (final z in _restrictedZones.where((z) => z.active)) {
      final inside = _pointInPolygon(location, z.polygon);
      if (inside && _currentZoneId != z.id) {
        _currentZoneId = z.id;
        _showRestrictedZoneWarning(z);
        return;
      } else if (!inside && _currentZoneId == z.id) {
        _currentZoneId = null;
        _hasShownZoneWarning = false;
      }
    }
  }

  void _showRestrictedZoneWarning(_Zone zone) {
    if (_hasShownZoneWarning) return;
    _hasShownZoneWarning = true;
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restricted Zone'),
        content: Text(
          'You entered restricted area: ${zone.name}. Please stop and follow rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _recenterToOwnLocation() async {
    if (_ownLocation != null) {
      _mapController.move(_ownLocation!, 15.0);
      return;
    }
    try {
      final p =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(p.latitude, p.longitude), 15.0);
    } catch (_) {}
  }

  List<Marker> _buildJeepMarkers() {
    final markers = <Marker>[];

    if (_ownLocation != null) {
      markers.add(
        Marker(
          width: 100,
          height: 100,
          point: _ownLocation!,
          child: const _OwnMarkerWidget(),
        ),
      );
    }

    _otherJeeps.forEach((id, latlng) {
      markers.add(
        Marker(
          width: 50,
          height: 50,
          point: latlng,
          child: _OtherJeepMarker(driverId: id),
        ),
      );
    });

    return markers;
  }

  // paste inside _LiveMapScreenState (add imports at top: import 'dart:math';)
  Timer? _simTimer;
  final List<Map<String, dynamic>> _simJeeps = [];
  bool _simRunning = false;

  /// Start in-app simulation of `count` jeeps (writes to /drivers/{id}/location)
  void _startInAppSimulation({
    int count = 6,
    int intervalMs = 3000,
    double spread = 0.01,
  }) {
    if (_simRunning) return;
    final rnd = Random();
    _simJeeps.clear();

    // base around own location if available, otherwise map center
    final base = _ownLocation ?? LatLng(6.905, 79.861);

    for (var i = 0; i < count; i++) {
      final id = 'sim_inapp_${i + 1}';
      // random initial offset within 'spread' degrees (~0.01 ≈ 1km roughly)
      final lat = base.latitude + (rnd.nextDouble() - 0.5) * spread;
      final lng = base.longitude + (rnd.nextDouble() - 0.5) * spread;
      _simJeeps.add({
        'id': id,
        'lat': lat,
        'lng': lng,
        'angle': rnd.nextDouble() * 360,
      });
    }

    // start periodic updates
    _simTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) async {
      final now = DateTime.now().toIso8601String();
      for (var s in _simJeeps) {
        // small random movement
        final jitterLat = (rnd.nextDouble() - 0.5) * 0.0003; // ~30m
        final jitterLng = (rnd.nextDouble() - 0.5) * 0.0003;
        s['lat'] = (s['lat'] as double) + jitterLat;
        s['lng'] = (s['lng'] as double) + jitterLng;

        final payload = {
          'lat': (s['lat'] as double),
          'lng': (s['lng'] as double),
          'accuracy': 5 + rnd.nextDouble() * 10,
          'speed': rnd.nextDouble() * 4,
          'timestamp': now,
        };

        try {
          await _db.ref('drivers/${s['id']}/location').set(payload);
          // optional: write small meta once
          await _db.ref('drivers/${s['id']}/meta').set({
            'jeep_id': s['id'],
            'display_name': 'Sim ${s['id']}',
          });
        } catch (e) {
          debugPrint('[Sim] write error for ${s['id']}: $e');
        }
      }
    });

    setState(() => _simRunning = true);
    debugPrint('[Sim] started $count sims');
  }

  /// Stop the in-app simulation and optionally remove nodes
  Future<void> _stopInAppSimulation({bool cleanupNodes = true}) async {
    _simTimer?.cancel();
    _simTimer = null;
    setState(() => _simRunning = false);

    if (cleanupNodes) {
      for (var s in _simJeeps) {
        try {
          await _db.ref('drivers/${s['id']}').remove();
        } catch (e) {
          debugPrint('[Sim] cleanup error for ${s['id']}: $e');
        }
      }
    }
    _simJeeps.clear();
    debugPrint('[Sim] stopped and cleaned up: cleanupNodes=$cleanupNodes');
  }

  @override
  Widget build(BuildContext context) {
    final center = _ownLocation ?? LatLng(6.905, 79.861);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Map (Driver)')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: center,
              zoom: 13.0,
              maxZoom: 18.0,
              minZoom: 5.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.yala_driver_app',
              ),
              MarkerLayer(markers: _buildJeepMarkers()),
              PolygonLayer(
                polygons: _restrictedZones.map((z) {
                  return Polygon(
                    points: z.polygon,
                    borderStrokeWidth: 2,
                    color: z.active
                        ? Colors.red.withOpacity(0.18)
                        : Colors.grey.withOpacity(0.10),
                    borderColor: z.active ? Colors.red : Colors.grey,
                  );
                }).toList(),
              ),
            ],
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: _recenterToOwnLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () => _mapController.move(
                    _mapController.center,
                    _mapController.zoom + 1,
                  ),
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1,
                  ),
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 18,
            right: 18,
            child: FloatingActionButton.extended(
              heroTag: 'report_incident',
              onPressed: () {
                Navigator.pushNamed(context, '/incident');
              },
              icon: const Icon(Icons.report),
              label: const Text('Report'),
            ),
          ),

          Positioned(
            bottom: 18,
            left: 18,
            child: FloatingActionButton.extended(
              heroTag: 'simulator',
              backgroundColor: Colors.black,
              onPressed: () async {
                if (!_simRunning) {
                  _startInAppSimulation(
                    count: 8,
                    intervalMs: 2000,
                    spread: 0.02,
                  );
                } else {
                  await _stopInAppSimulation(cleanupNodes: true);
                }
              },
              icon: Icon(_simRunning ? Icons.stop : Icons.directions_car),
              label: Text(_simRunning ? "Stop Jeeps" : "Simulate Jeeps"),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- Marker Widgets ----------------------

class _OwnMarkerWidget extends StatelessWidget {
  const _OwnMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.directions_bus, color: Colors.white, size: 28),
      ),
    );
  }
}

class _OtherJeepMarker extends StatelessWidget {
  final String driverId;
  const _OtherJeepMarker({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: const EdgeInsets.all(12),
            child: Text("Jeep: $driverId"),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(6.0),
          child: Icon(Icons.directions_car, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

// ---------------------- Restricted Zone Model ----------------------

class _Zone {
  final String id;
  final String name;
  final List<LatLng> polygon;
  final bool active;

  _Zone({
    required this.id,
    required this.name,
    required this.polygon,
    required this.active,
  });
}
