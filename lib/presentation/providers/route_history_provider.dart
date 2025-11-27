// lib/presentation/providers/route_history_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/route_history_model.dart';
import '../../data/services/route_history_service.dart';
import '../../data/services/port_service.dart';      // 👈 nuevo
import '../../data/models/port_model.dart';        // 👈 nuevo

class RouteHistoryProvider extends ChangeNotifier {
  final RouteHistoryService _service;
  final PortService _portService;                  // 👈 nuevo

  RouteHistoryProvider(
      this._service,
      this._portService,                             // 👈 nuevo
      );

  List<RouteHistoryItem> _recent = [];
  bool _isLoading = false;
  String? _error;

  // 👇 nuevo: mapa id → nombre
  final Map<String, String> _portNameMap = {};

  List<RouteHistoryItem> get recent => _recent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  /// Igual que en Angular: convertir ID de puerto en nombre
  String resolvePortName(String? portId) {
    if (portId == null) return 'N/D';
    return _portNameMap[portId] ?? portId; // si no lo encontramos, mostramos el id
  }

  Future<void> loadRecentForUser(String userId) async {
    debugPrint('👉 [RouteHistoryProvider] loadRecentForUser userId=$userId');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. cargar historial
      _recent = await _service.getRecentForUser(userId);
      debugPrint('✅ [RouteHistoryProvider] _recent.length=${_recent.length}');

      // 2. si aún no tengo el catálogo de puertos, lo cargo
      if (_portNameMap.isEmpty) {
        debugPrint('👉 [RouteHistoryProvider] cargando puertos...');
        final ports = await _portService.getAllPorts();
        for (final Port p in ports) {
          _portNameMap[p.id] = p.name;
        }
        debugPrint('✅ [RouteHistoryProvider] portNameMap size=${_portNameMap.length}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ [RouteHistoryProvider] error=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
