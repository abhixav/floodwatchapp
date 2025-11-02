import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles both OpenWeather API and local FastAPI model communication
class ApiService {
  final String weatherApiKey;
  final String fastApiBaseUrl;

  ApiService({
    required this.weatherApiKey,
    this.fastApiBaseUrl =
        "http://10.0.2.2:8000", // 👈 use 10.0.2.2 for Android emulator, keep http://127.0.0.1:8000 for Chrome testing
  });

  /// Fetch rainfall data (mm) from OpenWeather API
  Future<double> fetchRainfall(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric',
    );

    print("🌧️ Fetching rainfall from: $url");
    final response = await http.get(url);
    print("🌧️ Weather API status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['rain'] != null && data['rain']['1h'] != null) {
        final rain = (data['rain']['1h']).toDouble();
        print("🌧️ Rainfall (1h): $rain mm");
        return rain;
      } else {
        print("🌤️ No rainfall data available");
        return 0.0;
      }
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  /// Get flood risk prediction from FastAPI model
  Future<String> predictRisk(String place, double rainfallMm) async {
    final encodedPlace = Uri.encodeComponent(place);
    final url = Uri.parse(
      '$fastApiBaseUrl/predict/?place=$encodedPlace&rainfall_mm=$rainfallMm',
    );

    print("🛰️ Sending request to FastAPI: $url");

    final response = await http.get(url); // ✅ changed from POST → GET
    print("🛰️ FastAPI status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ FastAPI response: $data");

      // ✅ Changed to match your FastAPI key name
      return data['predicted_risk_label'] ?? 'safe';
    } else {
      throw Exception(
          'Failed to get prediction from FastAPI: ${response.statusCode}');
    }
  }
}
