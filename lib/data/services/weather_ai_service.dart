import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/weather_delay_model.dart';

class WeatherAiService {
  final http.Client _client;
  WeatherAiService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherDelayResult> predictWeatherDelay(WeatherDelayRequest request) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/predict-weather-delay');
    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (resp.statusCode != 200) {
      throw Exception('AI delay prediction failed: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return WeatherDelayResult.fromJson(data);
  }
}
