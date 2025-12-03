// lib/data/models/route_history_item.dart
class RouteHistoryItem {
  final String id;
  final String? originPortName;
  final String? destinationPortName;
  final String originPortId;
  final String destinationPortId;
  final double? totalDistance;
  final String status;
  final DateTime computedAt;
  final String source;

  RouteHistoryItem( {
    required this.id,
    required this.originPortName,
    required this.destinationPortName,
    required this.originPortId,
    required this.destinationPortId,
    required this.status,
    required this.computedAt,
    required this.source,
    this.totalDistance,
  });

  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      id: json['id'] as String,
      originPortName: json['originPortName'] as String?,
      destinationPortName: json['destinationPortName'] as String?,
      originPortId: json['originPortId'] as String,
      destinationPortId: json['destinationPortId'] as String,
      status: json['status'] as String,
      source: json['source'] as String,
      computedAt: DateTime.parse(json['computedAt'] as String),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
    );
  }
}
