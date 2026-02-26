// lib/features/dashboard/driver_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../features/map/screens/live_map_screen.dart'; // adjust path if your file is elsewhere
import '../../../core/services/location_service.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String driverId; // pass driver ID from login

  const DriverDashboardScreen({super.key, required this.driverId});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();

    _locationService = LocationService(); // uses default DB URL inside service
    _locationService.startTracking(widget.driverId);
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
        title: const Text("Driver Dashboard"),
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

            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_car, color: Colors.green),
                title: Text("Jeep ID"),
                subtitle: Text("JEEP-12"),
              ),
            ),
            const SizedBox(height: 10),

            const Card(
              child: ListTile(
                leading: Icon(Icons.map, color: Colors.green),
                title: Text("Assigned Block"),
                subtitle: Text("Block A"),
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
                      const SnackBar(content: Text("Driver ID is missing")),
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
                label: const Text("Open Live Map"),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.report),
                label: const Text("Report Incident"),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message),
                label: const Text("View Messages"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
