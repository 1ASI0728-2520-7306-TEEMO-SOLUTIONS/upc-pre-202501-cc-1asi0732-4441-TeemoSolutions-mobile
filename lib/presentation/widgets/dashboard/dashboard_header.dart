import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

/// Dashboard header widget matching Angular's HeaderComponent
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String userRole;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Para que el nombre esté a la izquierda
      children: [
        // Usuario y Rol
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $userName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              userRole,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme Toggle Button
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                );
              },
            ),

            // Notifications Button
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _showNotificationsBottomSheet(context);
              },
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              context,
              'Route Update',
              'Route "Atlantic Express" has been updated',
              Icons.route,
              const Color(0xFF1976D2),
            ),
            _buildNotificationItem(
              context,
              'New Port Added',
              'Port of Hamburg has been added to the system',
              Icons.anchor,
              const Color(0xFF4CAF50),
            ),
            _buildNotificationItem(
              context,
              'Weather Alert',
              'Storm warning for North Atlantic routes',
              Icons.warning,
              const Color(0xFFFFA726),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to notifications screen
                },
                child: const Text('View All Notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '2h ago',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        // Handle notification tap
      },
    );
  }
}
