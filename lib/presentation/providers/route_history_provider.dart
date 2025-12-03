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
    _isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ Cargar PUERTOS primero (necesarios para resolver nombres)
      if (_portNameMap.isEmpty) {
        final ports = await _portService.getAllPorts();
        for (final Port p in ports) {
          _portNameMap[p.id] = p.name;
        }
        debugPrint('✅ Puertos cargados: ${_portNameMap.length}');
      }

      // 2️⃣ Ahora cargar historial
      _recent = await _service.getRecentForUser(userId);
      debugPrint('✅ Rutas cargadas: ${_recent.length}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
