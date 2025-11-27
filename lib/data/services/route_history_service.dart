// lib/data/services/route_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/route_history_model.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart'; // para debugPrint

class RouteHistoryService {
  final AuthService _authService;
  RouteHistoryService(this._authService);

  final String _baseUrl = AppConstants.baseUrl;

  Future<List<RouteHistoryItem>> getRecentForUser(String userId) async {
    debugPrint('👉 [RouteHistoryService] getRecentForUser userId=$userId');

    final token = await _authService.getToken();
    debugPrint('👉 [RouteHistoryService] token=$token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl/users/$userId/route-history').replace(
      queryParameters: {
        'page': '0',
        'size': '1000', // obtener todas
        'archived': 'false',
      },
    );


    debugPrint('👉 [RouteHistoryService] GET $uri');
    debugPrint('👉 [RouteHistoryService] headers=$headers');

    final resp = await http.get(uri, headers: headers);

    debugPrint('👈 [RouteHistoryService] status=${resp.statusCode}');
    debugPrint('👈 [RouteHistoryService] body=${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}: ${resp.reasonPhrase}');
    }

    final Map<String, dynamic> json = jsonDecode(resp.body);
    final List<dynamic> itemsJson = json['items'] ?? [];

    final items = itemsJson
        .map((e) => RouteHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // ordenar como en Angular
    items.sort((a, b) => b.computedAt.compareTo(a.computedAt));

    debugPrint('✅ [RouteHistoryService] items cargados=${items.length}');
    return items;
  }
}
