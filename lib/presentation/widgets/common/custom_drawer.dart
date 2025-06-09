import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/mushroom_logo.dart';

/// Custom drawer matching Angular's SidebarComponent functionality
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header matching Angular's sidebar header
          _buildDrawerHeader(context),
          
          // Navigation items matching Angular's sidebar navigation
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavigationItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.assessment_outlined,
                  title: 'Reportes de Envío',
                  route: AppRoutes.shipmentReports,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.history_outlined,
                  title: 'Historial de Rutas',
                  route: AppRoutes.routeHistory,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.anchor_outlined,
                  title: 'Puertos Cercanos',
                  route: AppRoutes.nearbyPorts,
                ),
                
                const Divider(),
                
                // Settings section
                _buildNavigationItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                  },
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Ayuda',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help
                  },
                ),
              ],
            ),
          ),
          
          // Footer with user info and logout
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  /// Build drawer header matching Angular's sidebar header
  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return DrawerHeader(
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MushroomLogo(
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Usuario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user?.formattedRole ?? 'Usuario',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build navigation item matching Angular's sidebar navigation items
  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = route != null && currentLocation == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryBlue : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryBlue.withOpacity(0.1),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null) {
          context.go(route);
        }
      },
    );
  }

  /// Build drawer footer with logout option
  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, authProvider);
            },
          );
        },
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.signOut();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
