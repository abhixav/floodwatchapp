import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'area_model.dart';

class Report {
  final String id;
  final String? note;
  final LatLng location;
  final RiskLevel severity;
  final DateTime createdAt;

  Report({
    required this.id,
    this.note,
    required this.location,
    required this.severity,
    required this.createdAt,
  });

  // Convert Report to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'location': GeoPoint(location.latitude, location.longitude),
      'severity': severity.label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Firestore snapshot to Report
  factory Report.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      note: data['note'],
      location: LatLng(
        (data['location'] as GeoPoint).latitude,
        (data['location'] as GeoPoint).longitude,
      ),
      severity: _getRiskLevelFromLabel(data['severity']),
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Map string to RiskLevel enum
  static RiskLevel _getRiskLevelFromLabel(String label) {
    switch (label) {
      case 'Moderate':
        return RiskLevel.moderate;
      case 'High':
        return RiskLevel.high;
      case 'Severe':
        return RiskLevel.severe;
      case 'Safe':
        return RiskLevel.safe;
      default:
        return RiskLevel.safe;
    }
  }
}
