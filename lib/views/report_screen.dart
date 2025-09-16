import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 NEW

import '../utils/app_colors.dart';
import '../services/data_service.dart';
import '../models/report_model.dart';
import '../models/area_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _locCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  RiskLevel _severity = RiskLevel.moderate;

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (_) {}
  }

  void _useDemoLatLng() {
    _locCtrl.text = '8.4871, 76.9520';
  }

  Future<void> _submit() async {
    final svc = context.read<DataService>();
    final parts = _locCtrl.text.split(',');
    double lat = 8.4871, lng = 76.9520;
    if (parts.length >= 2) {
      lat = double.tryParse(parts[0].trim()) ?? lat;
      lng = double.tryParse(parts[1].trim()) ?? lng;
    }

    final r = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageBytes: _imageBytes,
      note: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      location: LatLng(lat, lng),
      severity: _severity,
      createdAt: DateTime.now(),
    );

    // Add to local DataService
    svc.addReport(r);

    // 👇 Save to Firebase Firestore
    try {
      await FirebaseFirestore.instance.collection("flood_reports").add({
        "description": r.note ?? "",
        "lat": r.location.latitude,
        "lng": r.location.longitude,
        "severity": r.severity.label,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving to Firestore: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted ✅')),
    );
    _locCtrl.clear();
    _descCtrl.clear();
    setState(() => _imageBytes = null);
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double pad = 16;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Report Flood Incident'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(pad, pad, pad, pad + 80),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: DottedBorder(
              color: Colors.blueGrey.shade200,
              dashPattern: const [6, 6],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
                ),
                alignment: Alignment.center,
                child: _imageBytes == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.camera_alt_outlined,
                              size: 40, color: Colors.black45),
                          SizedBox(height: 10),
                          Text('Tap to attach photo (optional)',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('Location *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locCtrl,
                  decoration: InputDecoration(
                    hintText: 'lat, lng',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _useDemoLatLng,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.my_location),
              )
            ],
          ),
          const SizedBox(height: 20),
          _label('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Optional',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          _label('Severity'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              _severityChip(RiskLevel.moderate),
              _severityChip(RiskLevel.high),
              _severityChip(RiskLevel.severe),
              _severityChip(RiskLevel.safe),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('Submit Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      );

  Widget _severityChip(RiskLevel level) {
    final selected = _severity == level;
    return GestureDetector(
      onTap: () => setState(() => _severity = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [
                  level.color.withOpacity(.7),
                  level.color.withOpacity(.5)
                ])
              : null,
          color: selected ? null : level.color.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: level.color.withOpacity(selected ? .7 : .3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 12, color: level.color),
            const SizedBox(width: 8),
            Text(
              level.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
