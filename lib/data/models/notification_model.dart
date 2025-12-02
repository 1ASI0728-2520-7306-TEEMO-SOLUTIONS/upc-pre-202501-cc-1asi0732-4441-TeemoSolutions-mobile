class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? portId;
  final String? portName;
  final String? action;
  final String? reason;
  final String? performedBy;
  final String? audience;
  final DateTime createdAt;
  final bool read;
  final DateTime? readAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.portId,
    this.portName,
    this.action,
    this.reason,
    this.performedBy,
    this.audience,
    this.readAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json["id"],
      type: json["type"],
      title: json["title"],
      message: json["message"],
      portId: json["portId"],
      portName: json["portName"],
      action: json["action"],
      reason: json["reason"],
      performedBy: json["performedBy"],
      audience: json["audience"],
      read: json["read"],
      createdAt: DateTime.parse(json["createdAt"]),
      readAt: json["readAt"] != null ? DateTime.parse(json["readAt"]) : null,
    );
  }
}

class NotificationCollection {
  final List<NotificationItem> items;
  final int totalItems;

  NotificationCollection({
    required this.items,
    required this.totalItems,
  });

  factory NotificationCollection.fromJson(Map<String, dynamic> json) {
    return NotificationCollection(
      items: (json["items"] as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList(),
      totalItems: json["totalItems"],
    );
  }
}
