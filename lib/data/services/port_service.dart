import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/port_model.dart';

/// Port service for API communication
/// Corresponds to Angular's PortService
class PortService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.portsEndpoint;

  
  /// Get all ports
  Future<List<Port>> getAllPorts() async {
    try {
      // Cambia la URL para usar el endpoint correcto
      final response =
          await http.get(Uri.parse('${AppConstants.baseUrl}/ports/all-ports'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Port.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load ports');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get nearby ports
  Future<List<Port>> getNearbyPorts(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nearby?lat=$latitude&lng=$longitude'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Port.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load nearby ports');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get port by name
  Future<Port?> getPortByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?name=$name'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Port.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
