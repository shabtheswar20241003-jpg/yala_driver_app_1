// lib/core/services/location_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final String databaseUrl;
  FirebaseDatabase? _db;
  Timer? _timer;

  /// Whether periodic tracking is active
  bool get isTracking => _timer != null;

  LocationService({
    this.databaseUrl =
        "https://yala-driver-app1-default-rtdb.asia-southeast1.firebasedatabase.app/",
  });

  /// Start periodic tracking.
  /// - driverId: id to write to under /drivers/{driverId}/location
  /// - intervalSeconds: how often to write (default 10s)
  /// This method now requests permissions immediately and does a first write.
  Future<void> startTracking(
    String driverId, {
    int intervalSeconds = 10,
  }) async {
    _db = FirebaseDatabase(databaseURL: databaseUrl);
    print('[LocationService] startTracking for $driverId, DB: $databaseUrl');

    // Ensure we have permission before starting the timer
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LocationService] location services disabled');
        // Do not start the timer if services are off.
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('[LocationService] permission request result: $permission');
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] permission deniedForever');
        return;
      }
    } catch (e) {
      print('[LocationService] permission check error: $e');
      return;
    }

    // Do an immediate send so UI updates quickly
    await sendLocationNow(driverId);

    // Cancel any existing timer
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      await sendLocationNow(driverId);
    });
  }

  /// Force a single immediate location read+write to Firebase.
  /// Useful for debugging or manual triggers.
  Future<void> sendLocationNow(String driverId) async {
    _db ??= FirebaseDatabase(databaseURL: databaseUrl);

    try {
      // Double-check services & permissions before reading
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LocationService] location services disabled (sendNow)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print(
          '[LocationService] permission request result (sendNow): $permission',
        );
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] permission deniedForever (sendNow)');
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      final payload = {
        "lat": pos.latitude,
        "lng": pos.longitude,
        "accuracy": pos.accuracy,
        "speed": pos.speed,
        "timestamp": DateTime.now().toIso8601String(),
      };

      print(
        '[LocationService] POSITION: lat=${pos.latitude}, lng=${pos.longitude}',
      );
      print(
        '[LocationService] SENDING -> drivers/$driverId/location : $payload',
      );

      await _db!.ref('drivers/$driverId/location').set(payload);
      // optionally you could also write meta under /drivers/$driverId/meta here
    } catch (e, st) {
      print('[LocationService] sendLocationNow error: $e\n$st');
    }
  }

  /// Stop periodic tracking
  void stopTracking() {
    print('[LocationService] stopTracking');
    _timer?.cancel();
    _timer = null;
  }
}
