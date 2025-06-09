import 'package:mushroom/data/models/route_model.dart';

class Port {
  final String id;
  final String name;
  final String continent;
  final double latitude;
  final double longitude;
  final String country;
  final String code;

  Port({
    required this.id,
    required this.name,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.code,
  });

  factory Port.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] ?? {};
    return Port(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      continent: json['continent'] ?? '',
      latitude: (coordinates['latitude'] ?? 0.0).toDouble(),
      longitude: (coordinates['longitude'] ?? 0.0).toDouble(),
      country: json['country'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'continent': continent,
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'country': country,
      'code': code,
    };
  }

  PortCoordinates get coordinates => PortCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

  @override
  String toString() {
    return 'Port(id: $id, name: $name, continent: $continent)';
  }
}
