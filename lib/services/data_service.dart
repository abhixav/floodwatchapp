import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../models/area_model.dart';
import '../models/report_model.dart';

/// Centralized data manager for both API and Firestore
class DataService extends ChangeNotifier {
  final List<Area> _areas = [];
  List<Area> get areas => List.unmodifiable(_areas);

  bool isApiData = false;

  // Firestore reports collection
  final CollectionReference _reportCol =
      FirebaseFirestore.instance.collection('reports');

  // Initialize ApiService
  final ApiService apiService = ApiService(
    weatherApiKey: '0234070d39f15419dcfe80aeeafaee06',
    fastApiBaseUrl: 'http://127.0.0.1:8000',
  );

  // ----------------------------------------------------------------------
  // Fetch rainfall + 7-day forecast + risk dynamically for each area
  // ----------------------------------------------------------------------
  Future<void> fetchAreasFromApi() async {
    try {
      final List<Map<String, dynamic>> places = [
        {
          'id': 'chackai',
          'name': 'Chackai',
          'lat': 8.4990,
          'lon': 76.9410,
          'population': 30000,
          'radius': 600
        },
        {
          'id': 'east_fort',
          'name': 'East Fort',
          'lat': 8.4859,
          'lon': 76.9470,
          'population': 25000,
          'radius': 600
        },
        {
          'id': 'kazhakkoottam',
          'name': 'Kazhakkoottam',
          'lat': 8.5735,
          'lon': 76.8642,
          'population': 45500,
          'radius': 700
        },
        {
          'id': 'manacaud',
          'name': 'Manacaud',
          'lat': 8.4765,
          'lon': 76.9515,
          'population': 28000,
          'radius': 600
        },
        {
          'id': 'nalanchira',
          'name': 'Nalanchira',
          'lat': 8.5201,
          'lon': 76.9602,
          'population': 32000,
          'radius': 650
        },
        {
          'id': 'pattom',
          'name': 'Pattom',
          'lat': 8.5169,
          'lon': 76.9410,
          'population': 36000,
          'radius': 600
        },
        {
          'id': 'peroorkkada',
          'name': 'Peroorkkada',
          'lat': 8.5280,
          'lon': 76.9615,
          'population': 34000,
          'radius': 650
        },
        {
          'id': 'petta',
          'name': 'Petta',
          'lat': 8.4820,
          'lon': 76.9500,
          'population': 21000,
          'radius': 600
        },
        {
          'id': 'sreekaryam',
          'name': 'Sreekaryam',
          'lat': 8.5440,
          'lon': 76.9170,
          'population': 33000,
          'radius': 700
        },
        {
          'id': 'thycaud',
          'name': 'Thycaud',
          'lat': 8.4802,
          'lon': 76.9495,
          'population': 29000,
          'radius': 600
        },
        {
          'id': 'ulloorr',
          'name': 'Ulloor',
          'lat': 8.5370,
          'lon': 76.9210,
          'population': 31000,
          'radius': 650
        },
        {
          'id': 'vanchiyoor',
          'name': 'Vanchiyoor',
          'lat': 8.4870,
          'lon': 76.9450,
          'population': 28000,
          'radius': 600
        },
        {
          'id': 'vattiyurkkavu',
          'name': 'Vattiyurkkavu',
          'lat': 8.5540,
          'lon': 76.9680,
          'population': 27000,
          'radius': 650
        },
        {
          'id': 'vellayambalam',
          'name': 'Vellayambalam',
          'lat': 8.5090,
          'lon': 76.9620,
          'population': 26000,
          'radius': 600
        },
      ];

      final List<Area> apiAreas = [];

      for (var place in places) {
        try {
          // 🌧️ Fetch 7-day rainfall forecast
          final weeklyRainfall = await apiService.fetch7DayRainfall(
            place['lat'],
            place['lon'],
          );

          // 🧮 Compute average rainfall
          final avgRainfall = weeklyRainfall.isNotEmpty
              ? weeklyRainfall.reduce((a, b) => a + b) / weeklyRainfall.length
              : 0.0;

          print("📍 ${place['name']} => 7-day: $weeklyRainfall, Avg: $avgRainfall mm");

          // 🔮 Predict flood risk using FastAPI model
          final riskString =
              await apiService.predictRisk(place['name'], avgRainfall);
          final risk = _riskFromString(riskString);

          // 📦 Create Area with forecast data
          final area = Area(
            id: place['id'],
            name: place['name'],
            center: LatLng(place['lat'], place['lon']),
            radiusMeters: place['radius'].toDouble(),
            population: place['population'],
            updatedAt: DateTime.now(),
            risk: risk,
            rainfall: avgRainfall,
          );

          // ✅ Attach 7-day forecast to area
          area.forecast = weeklyRainfall;

          apiAreas.add(area);
        } catch (e) {
          print('⚠️ Error fetching data for ${place['name']}: $e');
        }
      }

      if (apiAreas.isNotEmpty) {
        _areas
          ..clear()
          ..addAll(apiAreas);
        isApiData = true;
        notifyListeners();
      } else {
        loadDummyData();
      }
    } catch (e) {
      print('❌ Error fetching API data: $e');
      loadDummyData();
    }
  }

  // ----------------------------------------------------------------------
  // Risk conversion helper
  // ----------------------------------------------------------------------
  RiskLevel _riskFromString(String r) {
    switch (r.toLowerCase()) {
      case 'severe':
        return RiskLevel.severe;
      case 'high':
        return RiskLevel.high;
      case 'moderate':
        return RiskLevel.moderate;
      default:
        return RiskLevel.safe;
    }
  }

  // ----------------------------------------------------------------------
  // Dummy fallback data (if APIs fail)
  // ----------------------------------------------------------------------
  void loadDummyData() {
    if (_areas.isNotEmpty) return;

    _areas.addAll([
      Area(
        id: 'chackai',
        name: 'Chackai',
        center: LatLng(8.4990, 76.9410),
        radiusMeters: 600,
        population: 30000,
        rainfall: 12.0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        risk: RiskLevel.high,
      )..forecast = [10, 12, 9, 8, 14, 7, 11],
      Area(
        id: 'kazhakkoottam',
        name: 'Kazhakkoottam',
        center: LatLng(8.5735, 76.8642),
        radiusMeters: 700,
        population: 45500,
        rainfall: 10.0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        risk: RiskLevel.moderate,
      )..forecast = [8, 9, 7, 11, 10, 13, 9],
      Area(
        id: 'vellayambalam',
        name: 'Vellayambalam',
        center: LatLng(8.5090, 76.9620),
        radiusMeters: 600,
        population: 26000,
        rainfall: 5.0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        risk: RiskLevel.safe,
      )..forecast = [4, 5, 6, 4, 3, 5, 4],
    ]);

    isApiData = false;
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Firestore report handling
  // ----------------------------------------------------------------------
  final List<Report> _reports = [];
  List<Report> get reports => List.unmodifiable(_reports);

  Future<void> addReport(Report r) async {
    _reports.add(r);
    notifyListeners();

    try {
      await _reportCol.doc(r.id).set(r.toMap());
      print('✅ Report saved to Firestore');
    } catch (e) {
      print('⚠️ Error saving report: $e');
    }
  }

  Future<List<Report>> fetchReportsFromFirebase() async {
    try {
      final snapshot = await _reportCol.get();
      return snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList();
    } catch (e) {
      print('⚠️ Error fetching reports: $e');
      return [];
    }
  }
}
