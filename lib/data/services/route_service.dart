import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/route_model.dart';
import '../services/auth_service.dart';

/// Route service for API communication
/// Corresponds to Angular's RouteService
class RouteService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.routesEndpoint;

  // Usamos AuthService para obtener el token y los headers
  final AuthService _authService = AuthService();

  /// Get all routes
  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get route by ID
  Future<RouteModel> getRouteById(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteModel.fromJson(data);
      } else {
        throw Exception('Failed to load route (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Calculate optimal route - Based on Angular RouteService
  Future<RouteCalculationResource> calculateOptimalRoute(
      String originPortId,
      String destinationPortId,
      List<String> intermediatePortIds,
      ) async {
    try {
      // Solo los parámetros requeridos según Swagger (startPortId, endPortId)
      // Si más adelante el backend admite intermedios, se envían aparte.
      final qp = <String, String>{
        'startPortId': originPortId,
        'endPortId': destinationPortId,
      };

      // Usar _baseUrl para consistencia y permitir cambio centralizado
      final url = Uri.parse('$_baseUrl/calculate-optimal-route')
          .replace(queryParameters: qp);
      print('[RouteService] URL calculate route => $url');

      final headers = await _authService.getAuthHeaders();

      // Reducimos token para logging seguro
      final tokenPreview = headers['Authorization'] != null
          ? headers['Authorization']!.substring(0, headers['Authorization']!.length.clamp(0, 20)) + '...'
          : 'NO_TOKEN';
      print('[RouteService] Auth header preview => $tokenPreview');

      // Añadimos Accept para evitar negociaciones inesperadas.
      final effectiveHeaders = {
        ...headers,
        'Accept': 'application/json',
      };

      http.Response response = await http.post(url, headers: effectiveHeaders);
      print('[RouteService] POST status => ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[RouteService] POST body => ${response.body}');
      }

      // Fallback: si 404 o 405, intentar GET (por si la doc o backend difieren)
      if (response.statusCode == 404 || response.statusCode == 405) {
        print('[RouteService] Intentando fallback GET para calculate-optimal-route');
        final getResp = await http.get(url, headers: effectiveHeaders);
        print('[RouteService] GET status => ${getResp.statusCode}');
        if (getResp.statusCode == 200) {
          response = getResp; // usamos esta como buena
        } else {
          print('[RouteService] GET body => ${getResp.body}');
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteCalculationResource.fromJson(data);
      }

      // Intentar parsear warnings del cuerpo aunque sea error
      String extra = '';
      try {
        final bodyJson = jsonDecode(response.body);
        if (bodyJson is Map && bodyJson['warnings'] is List) {
          final warnings = (bodyJson['warnings'] as List).whereType<String>().toList();
          if (warnings.isNotEmpty) {
            extra = ' Warnings: ' + warnings.join(' | ');
          }
        }
      } catch (_) {
        // Ignorar parseo fallido
      }

      switch (response.statusCode) {
        case 401:
          throw Exception('Failed to calculate route: 401 (token inválido o ausente).' + extra);
        case 403:
          throw Exception('Failed to calculate route: 403 (permisos insuficientes).' + extra);
        case 404:
          throw Exception('Failed to calculate route: 404 (endpoint no encontrado). Revisa path /api/routes/calculate-optimal-route y método POST en backend.' + extra);
        case 405:
          throw Exception('Failed to calculate route: 405 (método no permitido). Backend podría requerir GET.' + extra);
        case 500:
          throw Exception('Failed to calculate route: 500 (error interno backend).' + extra + ' Ver logs del servidor para stacktrace.');
        default:
          throw Exception('Failed to calculate route: ${response.statusCode}.' + extra);
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

      final headers = await _authService.getAuthHeaders();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
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
      final headers = await _authService.getAuthHeaders();

      final response = await http.patch(
        Uri.parse('$_baseUrl/$routeId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteModel.fromJson(data);
      } else {
        throw Exception('Failed to update route status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating route: $e');
    }
  }

  /// Delete route
  Future<void> deleteRoute(int routeId) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$routeId'),
        headers: headers,
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
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
        headers: headers,
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
      final headers = await _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/active'),
        headers: headers,
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

  Future<void> createRouteReport(Map<String, Object?> routeData) async {
    // cuando implementes esto, igual usas:
    // final headers = await _authService.getAuthHeaders();
  }

  /// Recalculate an existing route avoiding disabled ports
  /// Swagger: POST /api/routes/{routeId}/recalculate
  Future<RouteCalculationResource> recalculateRoute(String routeId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final effectiveHeaders = {
        ...headers,
        'Accept': 'application/json',
      };

      final url = Uri.parse('$_baseUrl/$routeId/recalculate');
      print('[RouteService] URL recalculate route => $url');

      final response = await http.post(url, headers: effectiveHeaders);
      print('[RouteService] RECALCULATE status => ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[RouteService] RECALCULATE body => ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return RouteCalculationResource.fromJson(data);
      }

      String extra = '';
      try {
        final bodyJson = jsonDecode(response.body);
        if (bodyJson is Map && bodyJson['warnings'] is List) {
          final warnings = (bodyJson['warnings'] as List).whereType<String>().toList();
          if (warnings.isNotEmpty) {
            extra = ' Warnings: ' + warnings.join(' | ');
          }
        }
      } catch (_) {}

      switch (response.statusCode) {
        case 401:
          throw Exception('Failed to recalculate route: 401 (token inválido o ausente).' + extra);
        case 403:
          throw Exception('Failed to recalculate route: 403 (permisos insuficientes).' + extra);
        case 404:
          throw Exception('Failed to recalculate route: 404 (ruta no encontrada / endpoint). Revisa path /api/routes/{routeId}/recalculate.' + extra);
        case 405:
          throw Exception('Failed to recalculate route: 405 (método no permitido). Backend podría requerir GET).' + extra);
        case 500:
          throw Exception('Failed to recalculate route: 500 (error interno backend).' + extra);
        default:
          throw Exception('Failed to recalculate route: ${response.statusCode}.' + extra);
      }
    } catch (e) {
      throw Exception('Network error recalculating route: $e');
    }
  }
}
