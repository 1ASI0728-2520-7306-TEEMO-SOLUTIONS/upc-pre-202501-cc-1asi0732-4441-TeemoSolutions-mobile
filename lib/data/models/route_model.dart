class RouteModel {
  final int id;
  final String name;
  final String from;
  final String to;
  final String status;
  final String statusColor;
  final int vessels;
  final String eta;
  final bool isActive;
  final DateTime? departureDate;
  final DateTime? arrivalDate;
  final double? distance;
  final List<String>? intermediatePorts;

  RouteModel({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.status,
    required this.statusColor,
    required this.vessels,
    required this.eta,
    required this.isActive,
    this.departureDate,
    this.arrivalDate,
    this.distance,
    this.intermediatePorts,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      status: json['status'] ?? 'planned',
      statusColor: json['statusColor'] ?? '#FFA726',
      vessels: json['vessels'] ?? 1,
      eta: json['eta'] ?? '',
      isActive: json['isActive'] ?? false,
      departureDate: json['departureDate'] != null 
          ? DateTime.tryParse(json['departureDate']) 
          : null,
      arrivalDate: json['arrivalDate'] != null 
          ? DateTime.tryParse(json['arrivalDate']) 
          : null,
      distance: json['distance']?.toDouble(),
      intermediatePorts: json['intermediatePorts'] != null 
          ? List<String>.from(json['intermediatePorts']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from': from,
      'to': to,
      'status': status,
      'statusColor': statusColor,
      'vessels': vessels,
      'eta': eta,
      'isActive': isActive,
      'departureDate': departureDate?.toIso8601String(),
      'arrivalDate': arrivalDate?.toIso8601String(),
      'distance': distance,
      'intermediatePorts': intermediatePorts,
    };
  }
}

class RouteCalculationResource {
  final String routeName;
  final double totalDistance;
  final int estimatedDays;
  final List<RouteSegment> segments;
  final List<PortCoordinates> coordinates;
  final String status;
  final List<String> warnings; // ✅ nuevo campo


  RouteCalculationResource({
    required this.routeName,
    required this.totalDistance,
    required this.estimatedDays,
    required this.segments,
    required this.coordinates,
    required this.status,
    this.warnings = const [],
  });

  factory RouteCalculationResource.fromJson(Map<String, dynamic> json) {
    // Path A: backend envía formato que mostraste (optimalRoute + coordinatesMapping)

    final warningsList = (json['warnings'] as List?)?.cast<String>() ?? const [];

    final optimal = (json['optimalRoute'] as List?)?.cast<String>() ?? const <String>[];
    final coordsMapRaw = json['coordinatesMapping'] as Map<String, dynamic>?;

    if (optimal.isNotEmpty && coordsMapRaw != null && coordsMapRaw.isNotEmpty) {
      // Construimos la lista 'coordinates' en el orden de optimalRoute
      final coordsList = <PortCoordinates>[];
      for (final name in optimal) {
        final c = coordsMapRaw[name];
        if (c is Map<String, dynamic>) {
          final lat = (c['latitude'] as num?)?.toDouble();
          final lon = (c['longitude'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            coordsList.add(PortCoordinates(latitude: lat, longitude: lon));
          }
        }
      }

      return RouteCalculationResource(
        routeName: json['routeName'] ?? '',                 // opcional, puede venir vacío
        totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
        estimatedDays: json['estimatedDays'] ?? 0,          // si no viene, 0
        segments: const <RouteSegment>[],                   // no viene en este formato
        coordinates: coordsList,                            // ✅ lo importante para el mapa
        status: json['status'] ?? 'calculated',
        warnings: warningsList,
      );
    }

    // Path B: legacy (tu formato anterior con 'coordinates' y 'segments')
    return RouteCalculationResource(
      routeName: json['routeName'] ?? '',
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      estimatedDays: json['estimatedDays'] ?? 0,
      segments: (json['segments'] as List<dynamic>?)
          ?.map((segment) => RouteSegment.fromJson(segment))
          .toList() ??
          [],
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((coord) => PortCoordinates.fromJson(coord))
          .toList() ??
          [],
      status: json['status'] ?? 'calculated',
      warnings: warningsList,
    );
  }

}

class RouteSegment {
  final String from;
  final String to;
  final double distance;
  final int estimatedHours;

  RouteSegment({
    required this.from,
    required this.to,
    required this.distance,
    required this.estimatedHours,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedHours: json['estimatedHours'] ?? 0,
    );
  }
}

class PortCoordinates {
  final double latitude;
  final double longitude;

  PortCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory PortCoordinates.fromJson(Map<String, dynamic> json) {
    return PortCoordinates(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
