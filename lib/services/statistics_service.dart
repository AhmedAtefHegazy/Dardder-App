import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StatisticsService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await ApiConfig.handleRequest(() async => await http.get(
            Uri.parse('$baseUrl/api/auth/statistics'),
            headers: await ApiConfig.getHeaders(),
          ));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }
}
