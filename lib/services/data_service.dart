import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area_model.dart';
import '../models/report_model.dart';

class DataService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Area> _areas = [];
  List<Area> get areas => List.unmodifiable(_areas);

  Stream<List<Report>> get reportsStream {
    return _firestore.collection('flood_reports').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList();
    });
  }

  void loadDummyData() {
    if (_areas.isNotEmpty) return;
    _areas.addAll([
      Area(
        id: 'tvm_central',
        name: 'Thiruvananthapuram Central',
        center: LatLng(8.4871, 76.9520),
        radiusMeters: 700,
        population: 75000,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        risk: RiskLevel.severe,
      ),
      Area(
        id: 'kazhakkoottam',
        name: 'Kazhakkoottam',
        center: LatLng(8.5735, 76.8642),
        radiusMeters: 700,
        population: 45500,
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        risk: RiskLevel.high,
      ),
      Area(
        id: 'technopark',
        name: 'Technopark Area',
        center: LatLng(8.5580, 76.8795),
        radiusMeters: 600,
        population: 32100,
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        risk: RiskLevel.moderate,
      ),
      Area(
        id: 'kovalam',
        name: 'Kovalam',
        center: LatLng(8.4020, 76.9787),
        radiusMeters: 650,
        population: 18800,
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        risk: RiskLevel.safe,
      ),
    ]);
    notifyListeners();
  }

  Future<void> addReport(Report r) async {
    // Simply add the document to Firestore
    await _firestore.collection('flood_reports').add({
      'note': r.note,
      'location': GeoPoint(r.location.latitude, r.location.longitude),
      'severity': r.severity.label,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}