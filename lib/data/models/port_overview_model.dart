// lib/data/models/port_overview_model.dart
enum PortOperationalStatus { OPEN, RESTRICTED, CLOSED }

PortOperationalStatus portStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'OPEN':
      return PortOperationalStatus.OPEN;
    case 'RESTRICTED':
      return PortOperationalStatus.RESTRICTED;
    case 'CLOSED':
      return PortOperationalStatus.CLOSED;
    default:
      return PortOperationalStatus.OPEN;
  }
}

String portStatusToString(PortOperationalStatus status) {
  switch (status) {
    case PortOperationalStatus.OPEN:
      return 'OPEN';
    case PortOperationalStatus.RESTRICTED:
      return 'RESTRICTED';
    case PortOperationalStatus.CLOSED:
      return 'CLOSED';
  }
}

class PortOverviewItem {
  final String portId;
  final String name;
  final String country;
  final double lat;
  final double lon;
  final PortOperationalStatus status;
  final String? reason;
  final int? traffic;
  final DateTime? updatedAt;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;

  PortOverviewItem({
    required this.portId,
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    required this.status,
    this.reason,
    this.traffic,
    this.updatedAt,
    this.contactPhone,
    this.contactEmail,
    this.website,
  });

  factory PortOverviewItem.fromJson(Map<String, dynamic> json) {
    return PortOverviewItem(
      portId: json['portId'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      status: portStatusFromString(json['status'] as String),
      reason: json['reason'] as String?,
      traffic: json['traffic'] != null ? (json['traffic'] as num).toInt() : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      website: json['website'] as String?,
    );
  }
}

class PortOverviewResponse {
  final List<PortOverviewItem> content;
  final int totalElements;
  final DateTime? lastSyncedAt;

  PortOverviewResponse({
    required this.content,
    required this.totalElements,
    this.lastSyncedAt,
  });

  factory PortOverviewResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['content'] as List<dynamic>? ?? [])
        .map((e) => PortOverviewItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return PortOverviewResponse(
      content: items,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }
}
