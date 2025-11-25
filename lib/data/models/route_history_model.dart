class RouteHistoryItem {
  final String id;
  final String userId;
  final String originPortId;
  final String destinationPortId;
  final List<String> waypointPortIds;
  final List<String> avoidedPortIds;
  final DateTime computedAt;
  final String status; // 'SUCCESS' | 'NO_VIABLE_ROUTE' | 'CANCELLED'
  final String source; // 'AUTO' | 'MANUAL' | 'OPERATOR_OVERRIDE'
  final double? totalDistance;
  final double? durationEstimate;
  final double? costEstimate;
  final bool archived;

  RouteHistoryItem({
    required this.id,
    required this.userId,
    required this.originPortId,
    required this.destinationPortId,
    required this.computedAt,
    required this.status,
    required this.source,
    required this.archived,
    this.waypointPortIds = const [],
    this.avoidedPortIds = const [],
    this.totalDistance,
    this.durationEstimate,
    this.costEstimate,
  });

  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      originPortId: json['originPortId'] as String,
      destinationPortId: json['destinationPortId'] as String,
      computedAt: DateTime.parse(json['computedAt'] as String),
      status: json['status'] as String,
      source: json['source'] as String,
      archived: json['archived'] as bool? ?? false,
      waypointPortIds: (json['waypointPortIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      avoidedPortIds: (json['avoidedPortIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      totalDistance:
      (json['totalDistance'] as num?)?.toDouble(),
      durationEstimate:
      (json['durationEstimate'] as num?)?.toDouble(),
      costEstimate:
      (json['costEstimate'] as num?)?.toDouble(),
    );
  }
}

class RouteHistoryPage {
  final List<RouteHistoryItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final String? nextCursor;

  RouteHistoryPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.nextCursor,
  });

  factory RouteHistoryPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((e) => RouteHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Igual que en Angular: ordenar por computedAt desc
    items.sort((a, b) => b.computedAt.compareTo(a.computedAt));

    return RouteHistoryPage(
      items: items,
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? items.length,
      totalElements: json['totalElements'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
