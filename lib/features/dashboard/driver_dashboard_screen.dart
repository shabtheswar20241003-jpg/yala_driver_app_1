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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Driver Status",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Jeep ID card (now dynamic)
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.green),
                title: Text(('jeep_id')),
                subtitle: Text(widget.jeepId),
              ),
            ),
            const SizedBox(height: 10),

            // Assigned Block card (now dynamic)
            Card(
              child: ListTile(
                leading: const Icon(Icons.map, color: Colors.green),
                title: Text(('assigned_block')),
                subtitle: Text(widget.block),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Check that driverId exists before navigating
                  if (widget.driverId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(('driver_id_missing'))),
                    );
                    return;
                  }

                  // Navigate to LiveMapScreen and pass the driverId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LiveMapScreen(driverId: widget.driverId),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(('open_live_map')),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // debug print so we see the button press in logs
                  debugPrint('[Dashboard] Report Incident pressed');
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IncidentReportScreen(),
                      ),
                    );
                  } catch (e, st) {
                    debugPrint('[Dashboard] Navigator error: $e\n$st');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppTranslations.t('could_not_open_incident_screen') +
                              ': $e',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.report),
                label: Text(AppTranslations.t('report_incident')),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message),
                label: Text(AppTranslations.t('view_messages')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
