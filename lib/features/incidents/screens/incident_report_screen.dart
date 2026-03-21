import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/supabase_client.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? incidentType;

  final TextEditingController noteController = TextEditingController();

  File? imageFile;

  final picker = ImagePicker();

  bool loading = false;

  double? latitude;
  double? longitude;

  final List<String> incidentTypes = [
    "Wildlife Sighting",
    "Animal Attack",
    "Road Block",
    "Vehicle Breakdown",
    "Emergency",
    "Illegal Entry",
    "Fire",
    "Flood",
    "Other",
  ];

  // ---------------- LOCATION ----------------

  Future<void> getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      latitude = pos.latitude;
      longitude = pos.longitude;
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // ---------------- IMAGE PICKER ----------------

  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ---------------- IMAGE UPLOAD ----------------

  // ---------------- SUBMIT INCIDENT ----------------

  Future<void> submitIncident() async {
    if (incidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an incident type")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await getLocation();

      String? imageUrl = await uploadImage();

      final title = "${incidentType!} - ${DateTime.now().toIso8601String()}";

      await SupabaseConfig.client.from('incidents').insert({
        "title": title,
        "type": incidentType,
        "note": noteController.text,
        "image_url": imageUrl,
        "latitude": latitude ?? 0.0,
        "longitude": longitude ?? 0.0,
        "created_at": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incident Reported Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Submit error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Incident"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Incident Type",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: incidentType,

                  hint: const Text("Select incident type"),

                  items: incidentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      incidentType = value;
                    });
                  },

                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                if (imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(imageFile!, height: 200),
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text("Gallery"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: noteController,

                  maxLines: 4,

                  decoration: const InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: loading ? null : submitIncident,

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Incident"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
