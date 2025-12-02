import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../screens/notifications/notifications_screen.dart';


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
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.loadNotifications();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.loading) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = provider.notifications;
            // 👇 Solo mostramos máximo 3 notificaciones
            final visibleItems = items.take(3).toList();

            return Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.done_all),
                        tooltip: 'Marcar todas como leídas',
                        onPressed: () => provider.markAllAsRead(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (visibleItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay notificaciones.'),
                    )
                  else
                    ...visibleItems.map((n) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          (n.read ? Colors.grey : Colors.blue).withOpacity(0.1),
                          child: Icon(
                            Icons.notifications,
                            color: n.read ? Colors.grey : Colors.blue,
                          ),
                        ),
                        title: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          n.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatRelativeTime(n.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          provider.markAsRead(n.id);
                          // aquí podrías navegar a detalle si quisieras
                        },
                      );
                    }).toList(),

                  const SizedBox(height: 8),

                  // Ver todas
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        context.push('/notifications');
                      },
                      child: const Text('Ver todas las notificaciones'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
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
