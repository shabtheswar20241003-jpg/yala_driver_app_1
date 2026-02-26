// lib/core/services/location_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final String databaseUrl;
  FirebaseDatabase? _db;
  Timer? _timer;

  LocationService({
    this.databaseUrl =
        "https://yala-driver-app1-default-rtdb.asia-southeast1.firebasedatabase.app/",
  });

  // Start sending location
  void startTracking(String driverId, {int intervalSeconds = 10}) {
    _db = FirebaseDatabase(databaseURL: databaseUrl);
    print('[LocationService] startTracking for $driverId, DB: $databaseUrl');

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('[LocationService] location services disabled');
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

        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
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
      } catch (e, st) {
        print('[LocationService] Location update error: $e\n$st');
      }
    });
  }

  // Stop sending location
  void stopTracking() {
    print('[LocationService] stopTracking');
    _timer?.cancel();
    _timer = null;
  }
}
