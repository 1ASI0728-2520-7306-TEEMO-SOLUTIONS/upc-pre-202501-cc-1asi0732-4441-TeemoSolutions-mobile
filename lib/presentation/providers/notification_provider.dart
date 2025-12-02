import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  List<NotificationItem> _notifications = [];
  bool _loading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get loading => _loading;

  NotificationProvider(this._service);

  Future<void> loadNotifications() async {
    _loading = true;
    notifyListeners();

    try {
      final collection = await _service.getNotifications();
      _notifications = collection.items;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    final unreadIds =
    _notifications.where((n) => !n.read).map((n) => n.id).toList();

    if (unreadIds.isNotEmpty) {
      await _service.markManyAsRead(unreadIds);
      await loadNotifications();
    }
  }
}
