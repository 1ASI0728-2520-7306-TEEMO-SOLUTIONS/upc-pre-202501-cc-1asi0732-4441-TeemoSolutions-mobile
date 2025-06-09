import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/mushroom_logo.dart';

/// Splash screen with animated logo
/// Corresponds to Angular's splash screen in dashboard component
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _handleSplashFlow();
  }

  /// Initialize animations matching Angular's splash animations
  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  /// Handle splash screen flow matching Angular's splash logic
  Future<void> _handleSplashFlow() async {
    // Check if splash was already shown in this session
    final prefs = await SharedPreferences.getInstance();
    final splashShown = prefs.getBool(AppConstants.splashShownKey) ?? false;

    if (splashShown) {
      // Skip splash and go directly to appropriate screen
      _navigateToNextScreen();
      return;
    }

    // Mark splash as shown for this session
    await prefs.setBool(AppConstants.splashShownKey, true);

    // Wait for splash duration then navigate
    await Future.delayed(AppConstants.splashDuration);
    _navigateToNextScreen();
  }

  /// Navigate to next screen based on authentication status
  void _navigateToNextScreen() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.isAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Mushroom Logo
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: const MushroomLogo(
                    size: 160,
                    showAnimation: true,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Animated App Name
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _textAnimation.value)),
                    child: Text(
                      'MUSHROOM',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value * 0.8,
                  child: Text(
                    'Maritime Route Management',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.05,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
