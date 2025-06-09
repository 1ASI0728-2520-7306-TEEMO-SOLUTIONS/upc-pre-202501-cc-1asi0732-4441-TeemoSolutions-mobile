class IncotermFormData {
  String cargoType;
  double cargoValue;
  double cargoWeight;
  double cargoVolume;
  String seller;
  String buyer;
  String sellerCountry;
  String buyerCountry;
  String paymentTerms;
  String experienceLevel;
  bool insurance;
  String specialRequirements;

  IncotermFormData({
    this.cargoType = '',
    this.cargoValue = 0.0,
    this.cargoWeight = 0.0,
    this.cargoVolume = 0.0,
    this.seller = '',
    this.buyer = '',
    this.sellerCountry = '',
    this.buyerCountry = '',
    this.paymentTerms = '',
    this.experienceLevel = '',
    this.insurance = false,
    this.specialRequirements = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'cargoType': cargoType,
      'cargoValue': cargoValue,
      'cargoWeight': cargoWeight,
      'cargoVolume': cargoVolume,
      'seller': seller,
      'buyer': buyer,
      'sellerCountry': sellerCountry,
      'buyerCountry': buyerCountry,
      'paymentTerms': paymentTerms,
      'experienceLevel': experienceLevel,
      'insurance': insurance,
      'specialRequirements': specialRequirements,
    };
  }

  factory IncotermFormData.fromJson(Map<String, dynamic> json) {
    return IncotermFormData(
      cargoType: json['cargoType'] ?? '',
      cargoValue: (json['cargoValue'] ?? 0.0).toDouble(),
      cargoWeight: (json['cargoWeight'] ?? 0.0).toDouble(),
      cargoVolume: (json['cargoVolume'] ?? 0.0).toDouble(),
      seller: json['seller'] ?? '',
      buyer: json['buyer'] ?? '',
      sellerCountry: json['sellerCountry'] ?? '',
      buyerCountry: json['buyerCountry'] ?? '',
      paymentTerms: json['paymentTerms'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
      insurance: json['insurance'] ?? false,
      specialRequirements: json['specialRequirements'] ?? '',
    );
  }
}

class CostBreakdown {
  final double freight;
  final double insurance;
  final double customsClearance;
  final double portHandling;
  final double documentation;
  final double total;

  CostBreakdown({
    required this.freight,
    required this.insurance,
    required this.customsClearance,
    required this.portHandling,
    required this.documentation,
    required this.total,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      freight: (json['freight'] ?? 0.0).toDouble(),
      insurance: (json['insurance'] ?? 0.0).toDouble(),
      customsClearance: (json['customsClearance'] ?? 0.0).toDouble(),
      portHandling: (json['portHandling'] ?? 0.0).toDouble(),
      documentation: (json['documentation'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }
}

class IncotermOption {
  final String code;
  final String name;
  final String description;
  final List<String> sellerResponsibilities;
  final List<String> buyerResponsibilities;
  final double recommendationScore;
  final CostBreakdown costBreakdown;

  IncotermOption({
    required this.code,
    required this.name,
    required this.description,
    required this.sellerResponsibilities,
    required this.buyerResponsibilities,
    required this.recommendationScore,
    required this.costBreakdown,
  });

  factory IncotermOption.fromJson(Map<String, dynamic> json) {
    return IncotermOption(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sellerResponsibilities: List<String>.from(json['sellerResponsibilities'] ?? []),
      buyerResponsibilities: List<String>.from(json['buyerResponsibilities'] ?? []),
      recommendationScore: (json['recommendationScore'] ?? 0.0).toDouble(),
      costBreakdown: CostBreakdown.fromJson(json['costBreakdown'] ?? {}),
    );
  }
}

class RouteDetails {
  final double distance;
  final String estimatedTime;
  final String riskLevel;

  RouteDetails({
    required this.distance,
    required this.estimatedTime,
    required this.riskLevel,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    return RouteDetails(
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedTime: json['estimatedTime'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
    );
  }
}

class IncotermCalculationResult {
  final IncotermOption recommendedIncoterm;
  final List<IncotermOption> alternatives;
  final RouteDetails routeDetails;
  final List<String> warnings;

  IncotermCalculationResult({
    required this.recommendedIncoterm,
    required this.alternatives,
    required this.routeDetails,
    required this.warnings,
  });

  factory IncotermCalculationResult.fromJson(Map<String, dynamic> json) {
    return IncotermCalculationResult(
      recommendedIncoterm: IncotermOption.fromJson(json['recommendedIncoterm'] ?? {}),
      alternatives: (json['alternatives'] as List? ?? [])
          .map((alt) => IncotermOption.fromJson(alt))
          .toList(),
      routeDetails: RouteDetails.fromJson(json['routeDetails'] ?? {}),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}
