import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum RiskLevel { safe, moderate, high, severe }

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.severe:
        return 'Severe';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.safe:
        return AppColors.safe;
      case RiskLevel.moderate:
        return AppColors.moderate;
      case RiskLevel.high:
        return AppColors.high;
      case RiskLevel.severe:
        return AppColors.severe;
    }
  }
}

class Area {
  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;
  final int population;
  final DateTime updatedAt;
  RiskLevel risk;
  double rainfall;

  /// ✅ NEW FIELD — store 7-day rainfall predictions
  List<double> forecast;

  Area({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    required this.population,
    required this.updatedAt,
    required this.risk,
    this.rainfall = 0.0,
    this.forecast = const [], // default empty list
  });
}
