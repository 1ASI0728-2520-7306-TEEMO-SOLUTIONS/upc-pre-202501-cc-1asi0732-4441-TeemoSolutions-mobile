class WeatherDelayRequest {
  final double distanceKm;
  final double cruiseSpeedKnots;
  final double avgWindKnots;
  final double maxWaveM;
  final String departureTimeIso;
  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;

  WeatherDelayRequest({
    required this.distanceKm,
    required this.cruiseSpeedKnots,
    required this.avgWindKnots,
    required this.maxWaveM,
    required this.departureTimeIso,
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
  });

  Map<String, dynamic> toJson() => {
        'distanceKm': distanceKm,
        'cruiseSpeedKnots': cruiseSpeedKnots,
        'avgWindKnots': avgWindKnots,
        'maxWaveM': maxWaveM,
        'departureTimeIso': departureTimeIso,
        'originLat': originLat,
        'originLon': originLon,
        'destLat': destLat,
        'destLon': destLon,
      };
}

class WeatherDelayResult {
  final double delayHours;
  final double delayProbability;
  final String? plannedEtaIso;
  final String? adjustedEtaIso;
  final String? mainDelayFactor;
  final bool? usedFallback;
  final double? usedAvgWindKnots;
  final double? usedMaxWaveM;
  final String? riskLevel; // e.g. LOW | MEDIUM | HIGH (si backend lo provee)
  final double? riskScore; // valor numérico si existe

  WeatherDelayResult({
    required this.delayHours,
    required this.delayProbability,
    this.plannedEtaIso,
    this.adjustedEtaIso,
    this.mainDelayFactor,
    this.usedFallback,
    this.usedAvgWindKnots,
    this.usedMaxWaveM,
    this.riskLevel,
    this.riskScore,
  });

  factory WeatherDelayResult.fromJson(Map<String, dynamic> json) => WeatherDelayResult(
        delayHours: (json['delayHours'] ?? 0).toDouble(),
        delayProbability: (json['delayProbability'] ?? 0).toDouble(),
        plannedEtaIso: json['plannedEtaIso'],
        adjustedEtaIso: json['adjustedEtaIso'],
        mainDelayFactor: json['mainDelayFactor'],
        usedFallback: json['usedFallback'],
        usedAvgWindKnots: (json['usedAvgWindKnots'] == null) ? null : (json['usedAvgWindKnots']).toDouble(),
        usedMaxWaveM: (json['usedMaxWaveM'] == null) ? null : (json['usedMaxWaveM']).toDouble(),
        riskLevel: json['riskLevel'],
        riskScore: (json['riskScore'] == null) ? null : (json['riskScore']).toDouble(),
      );
}
