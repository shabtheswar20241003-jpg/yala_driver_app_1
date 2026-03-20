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

  Future<String?> uploadImage() async {
    if (imageFile == null) return null;

    try {
      final fileName = const Uuid().v4();

      final ext = path.extension(imageFile!.path);

      final filePath = "incidents/$fileName$ext";

      await SupabaseConfig.client.storage
          .from("incident-images")
          .upload(filePath, imageFile!);

      final imageUrl = SupabaseConfig.client.storage
          .from("incident-images")
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint("Image upload error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image upload failed")));

      return null;
    }
  }

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
  
}
