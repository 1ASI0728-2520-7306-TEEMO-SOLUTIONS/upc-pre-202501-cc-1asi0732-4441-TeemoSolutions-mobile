// lib/data/models/popular_route_model.dart
class PopularRoute {
  final String? routeId;
  final String originPortId;
  final String originPortName;
  final String destinationPortId;
  final String destinationPortName;
  final int searchesCount;

  PopularRoute({
    required this.routeId,
    required this.originPortId,
    required this.originPortName,
    required this.destinationPortId,
    required this.destinationPortName,
    required this.searchesCount,
  });

  factory PopularRoute.fromJson(Map<String, dynamic> json) {
    return PopularRoute(
      routeId: json['routeId'] as String?,
      originPortId: json['originPortId'] as String,
      originPortName: json['originPortName'] as String,
      destinationPortId: json['destinationPortId'] as String,        // 👈 aquí
      destinationPortName: json['destinationPortName'] as String,    // 👈 y aquí
      searchesCount: (json['searchesCount'] as num).toInt(),
    );
  }
}
