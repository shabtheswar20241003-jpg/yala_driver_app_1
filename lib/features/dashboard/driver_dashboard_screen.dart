// lib/features/dashboard/driver_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../features/map/screens/live_map_screen.dart'; // adjust path if your file is elsewhere
import '../../../core/services/location_service.dart';
import '../../../features/incidents/screens/incident_report_screen.dart';
import '../../../core/translations/app_translations.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String driverId; // pass driver ID from login
  final String jeepId; // new: assigned jeep id (from backend)
  final String block; // new: assigned block (from backend)

  const DriverDashboardScreen({
    super.key,
    required this.driverId,
    this.jeepId = 'Unknown', // default value if not passed
    this.block = 'Unknown', // default value if not passed
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();

    _locationService = LocationService(); // uses default DB URL inside service
    _location_service_start();
  }

  // small helper to start tracking and guard against empty driverId
  void _location_service_start() {
    if (widget.driverId.isEmpty) {
      debugPrint('[Dashboard] driverId is empty; not starting tracking');
      return;
    }
    try {
      _locationService.startTracking(widget.driverId);
      debugPrint('[Dashboard] started tracking for ${widget.driverId}');
    } catch (e, st) {
      debugPrint('[Dashboard] startTracking error: $e\n$st');
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.t('driver_dashboard')),
        automaticallyImplyLeading: false,
      ),
    );
  }
}
