import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/popular_route_model.dart';
import 'auth_service.dart';

class PopularRouteService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.routesEndpoint;
  final AuthService _authService;

  PopularRouteService(this._authService);

  Future<List<PopularRoute>> getPopularRoutes({int limit = 8}) async {
    final token = await _authService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl/popular?limit=$limit');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception("Error al obtener rutas populares (status: ${response.statusCode})");
    }

    final List data = json.decode(response.body) as List;
    return data.map((e) => PopularRoute.fromJson(e as Map<String, dynamic>)).toList();
  }
}
