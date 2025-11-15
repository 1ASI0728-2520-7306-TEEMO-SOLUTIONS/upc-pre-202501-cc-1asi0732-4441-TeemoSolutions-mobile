import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento local simple para informes (fallback mientras no hay GET en backend)
class ReportLocalStore {
  static const String _keyIncotermReports = 'incoterm_reports_v1';

  static Future<List<Map<String, dynamic>>> loadIncotermReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyIncotermReports);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> addIncotermReport(Map<String, dynamic> report) async {
    final current = await loadIncotermReports();
    current.insert(0, report); // más reciente primero
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIncotermReports, jsonEncode(current));
  }

  static Future<void> clearIncotermReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIncotermReports);
  }
}
