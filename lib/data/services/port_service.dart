import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/port_model.dart';
import '../services/auth_service.dart';

/// Port service for API communication
/// Corresponds to Angular's PortService
class PortService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.portsEndpoint;

  // Usamos AuthService internamente  para leer el token
  final AuthService _authService = AuthService();

  /// Get all ports
  Future<List<Port>> getAllPorts() async {
    try {
      final headers = await _authService.getAuthHeaders();

      final url = '$_baseUrl/all-ports';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Port.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401): token inválido o ausente');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403): rol insuficiente o token sin permisos');
      } else {
        throw Exception('Failed to load ports (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Disable a port
  Future<void> disablePort(String portId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/$portId/disable'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to disable port (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Enable a port
  Future<void> enablePort(String portId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/$portId/enable'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to enable port (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get nearby ports
  Future<List<Port>> getNearbyPorts(double latitude, double longitude) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/nearby?lat=$latitude&lng=$longitude'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Port.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401): token inválido o ausente');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403): rol insuficiente o token sin permisos');
      } else {
        throw Exception('Failed to load nearby ports (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get port by name
  Future<Port?> getPortByName(String name) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/search?name=$name'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Port.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401): token inválido o ausente');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403): rol insuficiente o token sin permisos');
      } else {
        throw Exception('Failed to load port (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
