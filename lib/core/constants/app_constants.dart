/// Application constants matching Angular's environment configuration
class AppConstants {
  // App Information
  static const String appName = 'Mushroom';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Maritime Route Management';

  // API Configuration - corresponds to Angular's environment.ts
  static const String baseUrl = 'http://localhost:8080/api';
  static const String authEndpoint = '/authentication';
  static const String routesEndpoint = '/routes';
  static const String portsEndpoint = '/ports';

  // Storage Keys - matches Angular's localStorage keys
  static const String tokenKey = 'maritime_auth_token';
  static const String userKey = 'maritime_user';
  static const String themeKey = 'theme_mode';
  static const String splashShownKey = 'splash_shown';

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 4.0;

  // Map Configuration
  static const double defaultZoom = 10.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 3.0;
}

/// Route names matching Angular's routing structure
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String shipmentReports = '/shipment-reports';
  static const String routeHistory = '/route-history';
  static const String nearbyPorts = '/nearby-ports';
}

/// User roles matching Angular's role system
class UserRoles {
  static const String admin = 'ROLE_ADMIN';
  static const String captain = 'ROLE_CAPTAIN';
  static const String user = 'ROLE_USER';
}
