// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flood_risk_area.dart';

class ApiService {
  // Flood monitor API
  static const String _baseUrl = 'https://api.yourfloodmonitor.com/v1';

  // OpenWeatherMap API key
  final String weatherApiKey;

  ApiService({required this.weatherApiKey});

  // Fetch flood risk data (Trivandrum areas)
  Future<List<FloodRiskArea>> fetchFloodRiskData() async {
    final url = Uri.parse('$_baseUrl/trivandrum/risk_areas');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => FloodRiskArea.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load flood risk data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during API call: $e');
      throw Exception(
          'Network error: Could not connect to the flood monitoring service.');
    }
  }

  // Fetch live rainfall (mm) for a location
  Future<double> fetchRainfall(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check rainfall in 1h first, then 3h, else 0
        if (data['rain'] != null) {
          if (data['rain']['1h'] != null) {
            return (data['rain']['1h'] as num).toDouble();
          } else if (data['rain']['3h'] != null) {
            return (data['rain']['3h'] as num).toDouble();
          }
        }
        return 0.0;
      } else {
        throw Exception(
            'Failed to fetch weather. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return 0.0;
    }
  }
}
