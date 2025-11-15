import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/route_provider.dart';
import 'data/services/auth_service.dart';
import 'data/services/route_service.dart';
import 'data/services/port_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MushroomApp());
}

/// Main application widget for Mushroom Maritime Route Management
/// Corresponds to Angular's AppComponent with routing and theming setup
class MushroomApp extends StatelessWidget {
  const MushroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider - handles dark/light mode like Angular's theme service
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Auth Provider - corresponds to Angular's AuthService
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        
        // Route Provider - corresponds to Angular's RouteService
        ChangeNotifierProvider(
          create: (_) => RouteProvider(RouteService(), PortService()),
        ),

      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // Theme configuration matching Angular's color scheme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Localization setup for internationalization
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            
            // Router configuration matching Angular's app.routes.ts
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

