import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../widgets/common/custom_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = provider.notifications;

            if (items.isEmpty) {
              return const Center(
                child: Text('No tienes notificaciones por ahora.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = items[index];
                  return _buildNotificationTile(context, n, provider);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context,
      NotificationItem n,
      NotificationProvider provider,
      ) {
    final isUnread = !n.read;

    return Material(
      color: isUnread ? Colors.blue.withOpacity(0.03) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: CircleAvatar(
          backgroundColor:
          (isUnread ? Colors.blue : Colors.grey).withOpacity(0.1),
          child: Icon(
            Icons.notifications,
            color: isUnread ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(
          n.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatRelativeTime(n.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (n.portName != null) ...[
                  const Text(' · ', style: TextStyle(color: Colors.grey)),
                  Text(
                    n.portName!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          if (isUnread) provider.markAsRead(n.id);
          // Aquí podrías abrir una pantalla de detalle según type/action
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }
}
