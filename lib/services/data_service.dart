import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../models/area_model.dart';
import '../models/report_model.dart';

class DataService extends ChangeNotifier {
  final List<Area> _areas = [];
  List<Area> get areas => List.unmodifiable(_areas);

  bool isApiData = false;

  // Firestore collection reference
  final CollectionReference _reportCol =
      FirebaseFirestore.instance.collection('reports');

  // Initialize ApiService with OpenWeatherMap API key
  final ApiService apiService = ApiService(
    weatherApiKey: '83a929f084dd247bf70f6fbb7f3bdba7',
  );

  // ---------------- Load areas with rule-based risk ----------------
  Future<void> fetchAreasFromApi() async {
    try {
      final cityRainfall = await apiService.fetchRainfall(8.5241, 76.9366);

      final List<Area> apiAreas = [
        Area(
          id: 'tvm_central',
          name: 'Thiruvananthapuram Central',
          center: LatLng(8.4871, 76.9520),
          radiusMeters: 700,
          population: 75000,
          updatedAt: DateTime.now(),
          risk: _calculateRisk('tvm_central', cityRainfall),
        ),
        Area(
          id: 'kazhakkoottam',
          name: 'Kazhakkoottam',
          center: LatLng(8.5735, 76.8642),
          radiusMeters: 700,
          population: 45500,
          updatedAt: DateTime.now(),
          risk: _calculateRisk('kazhakkoottam', cityRainfall),
        ),
        Area(
          id: 'technopark',
          name: 'Technopark Area',
          center: LatLng(8.5580, 76.8795),
          radiusMeters: 600,
          population: 32100,
          updatedAt: DateTime.now(),
          risk: _calculateRisk('technopark', cityRainfall),
        ),
        Area(
          id: 'kovalam',
          name: 'Kovalam',
          center: LatLng(8.4020, 76.9787),
          radiusMeters: 650,
          population: 18800,
          updatedAt: DateTime.now(),
          risk: _calculateRisk('kovalam', cityRainfall),
        ),
      ];

      _areas.clear();
      _areas.addAll(apiAreas);
      isApiData = true;
      notifyListeners();
    } catch (e) {
      print('Error fetching areas: $e');
      loadDummyData();
    }
  }

  // ---------------- Risk calculation ----------------
  RiskLevel _calculateRisk(String areaId, double rainfall) {
    switch (areaId) {
      case 'tvm_central':
        if (rainfall > 20) return RiskLevel.severe;
        if (rainfall > 10) return RiskLevel.high;
        if (rainfall > 2) return RiskLevel.moderate;
        return RiskLevel.safe;
      case 'kazhakkoottam':
        if (rainfall > 25) return RiskLevel.severe;
        if (rainfall > 12) return RiskLevel.high;
        if (rainfall > 3) return RiskLevel.moderate;
        return RiskLevel.safe;
      case 'technopark':
        if (rainfall > 18) return RiskLevel.severe;
        if (rainfall > 8) return RiskLevel.high;
        if (rainfall > 2) return RiskLevel.moderate;
        return RiskLevel.safe;
      case 'kovalam':
        if (rainfall > 15) return RiskLevel.severe;
        if (rainfall > 7) return RiskLevel.high;
        if (rainfall > 2) return RiskLevel.moderate;
        return RiskLevel.safe;
      default:
        return RiskLevel.safe;
    }
  }

  // ---------------- Dummy fallback ----------------
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

    isApiData = false;
    notifyListeners();
  }

  // ---------------- Reports ----------------
  final List<Report> _reports = [];
  List<Report> get reports => List.unmodifiable(_reports);

  // Add report to local list AND Firebase
  Future<void> addReport(Report r) async {
    _reports.add(r);
    notifyListeners();

    try {
      await _reportCol.doc(r.id).set(r.toMap());
      print('Report saved to Firestore successfully');
    } catch (e) {
      print('Error saving report to Firestore: $e');
      throw e;
    }
  }

  // Fetch reports from Firebase
  Future<List<Report>> fetchReportsFromFirebase() async {
    try {
      final snapshot = await _reportCol.get();
      return snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error fetching reports from Firestore: $e');
      return [];
    }
  }
}
