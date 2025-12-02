// lib/presentation/providers/popular_routes_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/popular_route_model.dart';
import '../../data/services/popular_route_service.dart';

class PopularRoutesProvider extends ChangeNotifier {
  final PopularRouteService _service;

  PopularRoutesProvider(this._service);

  List<PopularRoute> routes = [];
  bool isLoading = false;
  String? error;

  Future<void> loadPopularRoutes({int limit = 8}) async {
    try {
      isLoading = true;
      notifyListeners();

      routes = await _service.getPopularRoutes(limit: limit);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
