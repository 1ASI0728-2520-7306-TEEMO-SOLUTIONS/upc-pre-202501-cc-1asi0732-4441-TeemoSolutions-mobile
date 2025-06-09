import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/route_model.dart';

/// Route service for API communication
/// Corresponds to Angular's RouteService
class RouteService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.routesEndpoint;

  /// Get all routes
  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get route by ID
  Future<RouteModel> getRouteById(int id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteModel.fromJson(data);
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Calculate optimal route - Based on Angular RouteService
  Future<RouteCalculationResource> calculateOptimalRoute(
    String originPort,
    String destinationPort,
    List<String> intermediatePorts,
  ) async {
    try {
      // Construye la URL con los parámetros en la query
      final url = Uri.parse(
        '${AppConstants.baseUrl}/routes/calculate-optimal-route'
        '?startPort=$originPort&endPort=$destinationPort',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: '', // El body puede ir vacío si la API así lo espera
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteCalculationResource.fromJson(data);
      } else {
        throw Exception('Failed to calculate route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error calculating route: $e');
    }
  }

  /// Create new route
  Future<RouteModel> createRoute({
    required String name,
    required String originPort,
    required String destinationPort,
    required List<String> intermediatePorts,
    required DateTime departureDate,
    required int vessels,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'originPort': originPort,
        'destinationPort': destinationPort,
        'intermediatePorts': intermediatePorts,
        'departureDate': departureDate.toIso8601String(),
        'vessels': vessels,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteModel.fromJson(data);
      } else {
        throw Exception('Failed to create route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error creating route: $e');
    }
  }

  /// Update route status
  Future<RouteModel> updateRouteStatus(int routeId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$routeId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteModel.fromJson(data);
      } else {
        throw Exception(
            'Failed to update route status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating route: $e');
    }
  }

  /// Delete route
  Future<void> deleteRoute(int routeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$routeId'),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error deleting route: $e');
    }
  }

  /// Get route history
  Future<List<RouteModel>> getRouteHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load route history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get active routes
  Future<List<RouteModel>> getActiveRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/active'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load active routes');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createRouteReport(Map<String, Object?> routeData) async {}
}
