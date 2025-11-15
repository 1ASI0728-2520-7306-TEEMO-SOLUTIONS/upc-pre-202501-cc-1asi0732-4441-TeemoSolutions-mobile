import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/reports/shipment_reports_screen.dart';
import '../../presentation/screens/reports/route_history_screen.dart';
import '../../presentation/screens/captain/nearby_ports_screen.dart';

/// Router configuration matching Angular's app.routes.ts structure
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen - corresponds to Angular's splash screen in dashboard
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes - matches Angular's auth components
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main Application Routes - protected by auth guard like Angular
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        redirect: _authGuard,
      ),
      
      GoRoute(
        path: AppRoutes.shipmentReports,
        name: 'shipment-reports',
        builder: (context, state) => const ShipmentReportsScreen(),
        redirect: _authGuard,
      ),
      
      GoRoute(
        path: AppRoutes.routeHistory,
        name: 'route-history',
        builder: (context, state) => const RouteHistoryScreen(),
        redirect: _authGuard,
      ),
      
      GoRoute(
        path: AppRoutes.nearbyPorts,
        name: 'nearby-ports',
        builder: (context, state) => const NearbyPortsScreen(),
        redirect: _authGuard,
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
  
  /// Auth guard function matching Angular's AuthGuard
  static String? _authGuard(BuildContext context, GoRouterState state) {
    // This would typically check authentication status
    // For now, we'll implement a basic check
    return null; // Allow navigation - implement proper auth check
  }
}
