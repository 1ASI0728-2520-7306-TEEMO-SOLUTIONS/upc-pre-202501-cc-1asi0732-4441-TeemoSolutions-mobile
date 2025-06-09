import 'package:flutter/material.dart';
import '../../data/models/route_model.dart';
import '../../data/models/port_model.dart';
import '../../data/services/route_service.dart';
import '../../data/services/port_service.dart';

/// Route provider for managing route state
/// Corresponds to Angular's RouteService with reactive state management
class RouteProvider extends ChangeNotifier {
  final RouteService _routeService;
  final PortService _portService;

  List<RouteModel> _routes = [];
  List<Port> _ports = [];
  RouteModel? _selectedRoute;
  bool _isLoading = false;
  String? _errorMessage;

  RouteProvider(this._routeService, this._portService);

  // Getters
  List<RouteModel> get routes => _routes;
  List<Port> get ports => _ports;
  RouteModel? get selectedRoute => _selectedRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all routes
  Future<void> loadRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _routes = await _routeService.getAllRoutes();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all ports
  Future<void> loadPorts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ports = await _portService.getAllPorts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a route
  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    notifyListeners();
  }

  /// Clear selected route
  void clearSelectedRoute() {
    _selectedRoute = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Create new route
  Future<RouteModel?> createRoute({
    required String name,
    required String originPort,
    required String destinationPort,
    required List<String> intermediatePorts,
    required DateTime departureDate,
    required int vessels,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRoute = await _routeService.createRoute(
        name: name,
        originPort: originPort,
        destinationPort: destinationPort,
        intermediatePorts: intermediatePorts,
        departureDate: departureDate,
        vessels: vessels,
      );
      
      _routes.add(newRoute);
      notifyListeners();
      return newRoute;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate optimal route
  Future<RouteCalculationResource?> calculateOptimalRoute(
    String originPort,
    String destinationPort,
    List<String> intermediatePorts,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final calculation = await _routeService.calculateOptimalRoute(
        originPort,
        destinationPort,
        intermediatePorts,
      );
      return calculation;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
