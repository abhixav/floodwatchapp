import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles both OpenWeather API and local FastAPI model communication
class ApiService {
  final String weatherApiKey;
  final String fastApiBaseUrl;

  ApiService({
    required this.weatherApiKey,
    this.fastApiBaseUrl =
        "http://10.0.2.2:8000", // 👈 use 10.0.2.2 for Android emulator, 127.0.0.1 for Chrome
  });

  // ----------------------------------------------------------------------
  // 🌧️ Fetch single rainfall (1h)
  // ----------------------------------------------------------------------
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

  // ----------------------------------------------------------------------
  // ☀️ Fetch 7-day rainfall forecast using One Call 3.0 API
  // ----------------------------------------------------------------------
  Future<List<double>> fetch7DayRainfall(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon'
      '&exclude=current,minutely,hourly,alerts&appid=$weatherApiKey&units=metric',
    );

    print("📅 Fetching 7-day rainfall forecast: $url");
    final response = await http.get(url);
    print("📅 Forecast API status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<double> rainAmounts = [];

      for (var day in data['daily']) {
        double rain = 0.0;
        if (day.containsKey('rain')) rain = (day['rain'] as num).toDouble();
        rainAmounts.add(rain);
      }

      print("✅ 7-day rainfall values: $rainAmounts");
      return rainAmounts;
    } else {
      throw Exception('Failed to fetch 7-day forecast: ${response.statusCode}');
    }
  }

  // ----------------------------------------------------------------------
  // 🛰️ Get flood risk prediction from FastAPI model
  // ----------------------------------------------------------------------
  Future<String> predictRisk(String place, double rainfallMm) async {
    final encodedPlace = Uri.encodeComponent(place);
    final url = Uri.parse(
      '$fastApiBaseUrl/predict/?place=$encodedPlace&rainfall_mm=$rainfallMm',
    );

    print("🛰️ Sending request to FastAPI: $url");

    final response = await http.get(url); // ✅ GET request
    print("🛰️ FastAPI status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ FastAPI response: $data");

      // ✅ Adjusted key to match your FastAPI output
      return data['predicted_risk_label'] ?? 'safe';
    } else {
      throw Exception(
          'Failed to get prediction from FastAPI: ${response.statusCode}');
    }
  }
}
