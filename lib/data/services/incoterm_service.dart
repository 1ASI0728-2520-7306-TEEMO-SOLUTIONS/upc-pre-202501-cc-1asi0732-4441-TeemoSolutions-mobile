import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/incoterm_model.dart';

class IncotermService {
  Future<IncotermCalculationResult> calculateIncoterms(
    IncotermFormData formData,
    String originPort,
    String destinationPort,
    double distance,
  ) async {
    // Intenta llamar al backend real; si falla, cae al generador local como fallback
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/incoterms/calculate');
      final payload = {
        ...formData.toJson(),
        'originPort': originPort,
        'destinationPort': destinationPort,
        'distance': distance,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final Map<String, dynamic> raw = jsonDecode(response.body);

      // Adaptar el shape del backend a nuestros modelos actuales
      Map<String, dynamic> _mapCostBreakdown(Map<String, dynamic> src) {
        double _d(dynamic v) {
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0.0;
          return 0.0;
        }
        final freight = _d(src['oceanFreight']) + _d(src['fuelSurcharge']) + _d(src['bunkerAdjustmentFactor']);
        final insurance = _d(src['marineInsurance']) + _d(src['cargoInsurance']) + _d(src['warRiskInsurance']);
        final customs = _d(src['exportCustomsClearance']) + _d(src['importCustomsClearance']) + _d(src['importDuties']) + _d(src['taxes']);
        final handling = _d(src['originPortHandling']) + _d(src['destinationPortHandling']) + _d(src['containerHandling']) + _d(src['stevedoring']) + _d(src['warehousing']) + _d(src['demurrage']) + _d(src['detention']);
        final docs = _d(src['billOfLading']) + _d(src['certificateOfOrigin']) + _d(src['inspectionCertificate']) + _d(src['customsDocumentation']);
        final total = _d(src['total']);
        return {
          'freight': freight,
          'insurance': insurance,
          'customsClearance': customs,
          'portHandling': handling,
          'documentation': docs,
          'total': total > 0 ? total : (freight + insurance + customs + handling + docs),
        };
      }

      Map<String, dynamic> _adaptIncoterm(Map<String, dynamic> it) {
        final Map<String, dynamic> out = Map<String, dynamic>.from(it);
        out['recommendationScore'] = (it['recommendationScore'] is num)
            ? (it['recommendationScore'] as num).toDouble()
            : 0.0;
        final cost = (it['costBreakdown'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        out['costBreakdown'] = _mapCostBreakdown(cost);
        // Campos extra como riskTransferPoint/suitableFor se ignoran por ahora
        return out;
      }

      final recommended = (raw['recommendedIncoterm'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final alternatives = (raw['alternatives'] as List? ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      final transformed = <String, dynamic>{
        'recommendedIncoterm': _adaptIncoterm(recommended),
        'alternatives': alternatives.map(_adaptIncoterm).toList(),
        'routeDetails': {
          'distance': (raw['routeDetails']?['distance'] ?? distance) is num
              ? (raw['routeDetails']?['distance'] as num).toDouble()
              : distance,
          'estimatedTime': raw['routeDetails']?['estimatedTime'] ?? '',
          'riskLevel': raw['routeDetails']?['riskLevel'] ?? '',
        },
        'warnings': List<String>.from(raw['warnings'] ?? const []),
      };

      return IncotermCalculationResult.fromJson(transformed);
    } catch (e) {
      // Fallback local para no romper la UX si el backend no responde o hay CORS
      return _generateIncotermRecommendation(formData, originPort, destinationPort, distance);
    }
  }

  IncotermCalculationResult _generateIncotermRecommendation(
    IncotermFormData formData,
    String originPort,
    String destinationPort,
    double distance,
  ) {
    // Calculate base costs based on distance and cargo value
    final baseFreight = (distance * 0.05).round().toDouble();
  final baseInsurance = (formData.cargoValue * 0.02).round().toDouble();
    final baseHandling = (formData.cargoWeight * 2 + formData.cargoVolume * 10).round().toDouble();
    const baseDocumentation = 250.0;

    // Calculate scores for different Incoterms
    final cifScore = _calculateCIFScore(formData);
    final fobScore = _calculateFOBScore(formData);
    final cfrScore = _calculateCFRScore(formData);

    // Create Incoterm options
    final cifOption = IncotermOption(
      code: 'CIF',
      name: 'Cost, Insurance and Freight',
      description: 'El vendedor paga el costo, seguro y flete hasta el puerto de destino designado.',
      sellerResponsibilities: [
        'Entrega de mercancía',
        'Embalaje y verificación',
        'Transporte interior en origen',
        'Formalidades aduaneras de exportación',
        'Carga en puerto de origen',
        'Transporte principal (flete marítimo)',
        'Seguro de la mercancía',
      ],
      buyerResponsibilities: [
        'Descarga en puerto de destino',
        'Formalidades aduaneras de importación',
        'Transporte interior en destino',
        'Recepción de la mercancía',
      ],
      recommendationScore: cifScore,
      costBreakdown: CostBreakdown(
        freight: baseFreight,
        insurance: baseInsurance,
        customsClearance: 0,
        portHandling: (baseHandling * 0.5).round().toDouble(),
        documentation: baseDocumentation,
        total: baseFreight + baseInsurance + (baseHandling * 0.5).round() + baseDocumentation,
      ),
    );

    final fobOption = IncotermOption(
      code: 'FOB',
      name: 'Free On Board',
      description: 'El vendedor entrega la mercancía a bordo del buque designado por el comprador.',
      sellerResponsibilities: [
        'Entrega de mercancía',
        'Embalaje y verificación',
        'Transporte interior en origen',
        'Formalidades aduaneras de exportación',
        'Carga en puerto de origen',
      ],
      buyerResponsibilities: [
        'Transporte principal (flete marítimo)',
        'Seguro de la mercancía',
        'Descarga en puerto de destino',
        'Formalidades aduaneras de importación',
        'Transporte interior en destino',
        'Recepción de la mercancía',
      ],
      recommendationScore: fobScore,
      costBreakdown: CostBreakdown(
        freight: 0,
        insurance: 0,
        customsClearance: 0,
        portHandling: (baseHandling * 0.3).round().toDouble(),
        documentation: baseDocumentation,
        total: (baseHandling * 0.3).round() + baseDocumentation,
      ),
    );

    final cfrOption = IncotermOption(
      code: 'CFR',
      name: 'Cost and Freight',
      description: 'El vendedor paga el costo y flete hasta el puerto de destino designado.',
      sellerResponsibilities: [
        'Entrega de mercancía',
        'Embalaje y verificación',
        'Transporte interior en origen',
        'Formalidades aduaneras de exportación',
        'Carga en puerto de origen',
        'Transporte principal (flete marítimo)',
      ],
      buyerResponsibilities: [
        'Seguro de la mercancía',
        'Descarga en puerto de destino',
        'Formalidades aduaneras de importación',
        'Transporte interior en destino',
        'Recepción de la mercancía',
      ],
      recommendationScore: cfrScore,
      costBreakdown: CostBreakdown(
        freight: baseFreight,
        insurance: 0,
        customsClearance: 0,
        portHandling: (baseHandling * 0.4).round().toDouble(),
        documentation: baseDocumentation,
        total: baseFreight + (baseHandling * 0.4).round() + baseDocumentation,
      ),
    );

    // Determine recommended Incoterm
    final scores = [
      {'incoterm': cifOption, 'score': cifScore},
      {'incoterm': fobOption, 'score': fobScore},
      {'incoterm': cfrOption, 'score': cfrScore},
    ];

    scores.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    final recommendedIncoterm = scores[0]['incoterm'] as IncotermOption;
    final alternatives = [
      scores[1]['incoterm'] as IncotermOption,
      scores[2]['incoterm'] as IncotermOption,
    ];

    // Generate warnings based on data
    final warnings = <String>[];
    if (formData.cargoValue > 100000) {
      warnings.add('Carga de alto valor: Se recomienda seguro adicional.');
    }
    if (formData.specialRequirements.toLowerCase().contains('peligros')) {
      warnings.add('Carga peligrosa: Verifique regulaciones especiales de transporte.');
    }
    if (distance > 8000) {
      warnings.add('Ruta de larga distancia: Considere tiempos de tránsito extendidos.');
    }

    // Calculate estimated time based on distance
    final days = (distance / 350).round();
    final estimatedTime = '$days días';

    // Determine risk level
    String riskLevel = 'Bajo';
    if (distance > 5000 || formData.cargoValue > 50000) {
      riskLevel = 'Medio';
    }
    if (distance > 8000 || 
        formData.cargoValue > 100000 || 
        formData.specialRequirements.toLowerCase().contains('peligros')) {
      riskLevel = 'Alto';
    }

    return IncotermCalculationResult(
      recommendedIncoterm: recommendedIncoterm,
      alternatives: alternatives,
      routeDetails: RouteDetails(
        distance: distance,
        estimatedTime: estimatedTime,
        riskLevel: riskLevel,
      ),
      warnings: warnings,
    );
  }

  double _calculateCIFScore(IncotermFormData formData) {
    double score = 70; // Base score

    // CIF is better for buyers with little experience
    if (formData.experienceLevel == 'principiante') score += 20;
    if (formData.experienceLevel == 'intermedio') score += 10;

    // CIF is better when insurance is important
    if (formData.insurance) score += 15;

    // CIF is better for high-value cargo
    if (formData.cargoValue > 50000) score += 10;

    return score;
  }

  double _calculateFOBScore(IncotermFormData formData) {
    double score = 60; // Base score

    // FOB is better for experienced buyers
    if (formData.experienceLevel == 'experto') score += 25;
    if (formData.experienceLevel == 'intermedio') score += 15;

    // FOB is better when buyer wants to control transport
    if (formData.paymentTerms == 'carta_credito') score += 10;

    // FOB is better for lower value cargo
    if (formData.cargoValue < 50000) score += 10;

    return score;
  }

  double _calculateCFRScore(IncotermFormData formData) {
    double score = 65; // Base score

    // CFR is a middle point
    if (formData.experienceLevel == 'intermedio') score += 20;
    if (formData.experienceLevel == 'experto') score += 10;

    // CFR is good when insurance is not so important
    if (!formData.insurance) score += 15;

    // CFR is good for medium value cargo
    if (formData.cargoValue >= 10000 && formData.cargoValue <= 50000) score += 15;

    return score;
  }
}
