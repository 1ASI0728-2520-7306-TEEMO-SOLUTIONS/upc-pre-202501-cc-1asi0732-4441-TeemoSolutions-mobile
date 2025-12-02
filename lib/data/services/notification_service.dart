import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import 'auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final AuthService _authService;
  final String _baseUrl = "${AppConstants.baseUrl}/notifications";

  NotificationService(this._authService);

  Future<NotificationCollection> getNotifications() async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse(_baseUrl);

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception("Error al obtener notificaciones");
    }

    return NotificationCollection.fromJson(jsonDecode(resp.body));
  }

  Future<void> markAsRead(String id) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse("$_baseUrl/$id/read");

    final resp = await http.patch(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception("Error al marcar como leída");
    }
  }

  Future<void> markManyAsRead(List<String> ids) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse("$_baseUrl/read");

    final resp = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({"ids": ids}),
    );

    if (resp.statusCode != 200) {
      throw Exception("Error al marcar varias como leídas");
    }
  }
}
