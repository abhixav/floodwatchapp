import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'area_model.dart';

class Report {
  final String id;
  final Uint8List? imageBytes; // may be null (demo)
  final String? note;
  final LatLng location;
  final RiskLevel severity;
  final DateTime createdAt;

  Report({
    required this.id,
    this.imageBytes,
    this.note,
    required this.location,
    required this.severity,
    required this.createdAt,
  });
}
