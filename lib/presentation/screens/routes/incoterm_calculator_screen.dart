import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/incoterm_model.dart';
import '../../../data/services/incoterm_service.dart';
import '../../../data/services/report_local_store.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/loading_button.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xls;

import 'dart:typed_data';


class IncotermCalculatorScreen extends StatefulWidget {
  final String originPort;
  final String destinationPort;
  final double distance;

  const IncotermCalculatorScreen({
    Key? key,
    required this.originPort,
    required this.destinationPort,
    required this.distance,
  }) : super(key: key);

  @override
  State<IncotermCalculatorScreen> createState() => _IncotermCalculatorScreenState();
}



class _IncotermCalculatorScreenState extends State<IncotermCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncotermService _incotermService = IncotermService();
  
  final _cargoValueController = TextEditingController();
  final _cargoWeightController = TextEditingController();
  final _cargoVolumeController = TextEditingController();
  final _sellerController = TextEditingController();
  final _buyerController = TextEditingController();
  final _sellerCountryController = TextEditingController();
  final _buyerCountryController = TextEditingController();
  final _specialRequirementsController = TextEditingController();

  IncotermFormData _formData = IncotermFormData();
  IncotermCalculationResult? _calculationResult;
  bool _isCalculating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Incoterms'),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteInfo(),
            const SizedBox(height: 24),
            if (_calculationResult == null) ...[
              _buildIncotermForm(),
            ] else ...[
              _buildCalculationResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Ruta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Puerto de Origen:', widget.originPort),
            _buildInfoRow('Puerto de Destino:', widget.destinationPort),
            _buildInfoRow('Distancia:', '${widget.distance.toStringAsFixed(0)} millas náuticas'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildIncotermForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCargoInfoSection(),
          const SizedBox(height: 24),
          _buildCommercialInfoSection(),
          const SizedBox(height: 24),
          _buildAdditionalConfigSection(),
          const SizedBox(height: 32),
          _buildFormActions(),
        ],
      ),
    );
  }

  Widget _buildCargoInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Mercancía',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Tipo de Mercancía',
              value: _formData.cargoType.isEmpty ? null : _formData.cargoType,
              items: const [
                {'value': 'general', 'label': 'Carga General'},
                {'value': 'container', 'label': 'Contenedores'},
                {'value': 'bulk', 'label': 'Carga a Granel'},
                {'value': 'liquid', 'label': 'Líquidos'},
                {'value': 'refrigerated', 'label': 'Refrigerada'},
                {'value': 'dangerous', 'label': 'Mercancía Peligrosa'},
              ],
              onChanged: (value) => setState(() => _formData.cargoType = value ?? ''),
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Valor de la Mercancía (USD)',
              controller: _cargoValueController,
              onChanged: (value) => _formData.cargoValue = double.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Peso (kg)',
              controller: _cargoWeightController,
              onChanged: (value) => _formData.cargoWeight = double.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Volumen (m³)',
              controller: _cargoVolumeController,
              onChanged: (value) => _formData.cargoVolume = double.tryParse(value) ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Comercial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Vendedor',
              controller: _sellerController,
              onChanged: (value) => _formData.seller = value,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Comprador',
              controller: _buyerController,
              onChanged: (value) => _formData.buyer = value,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'País del Vendedor',
              controller: _sellerCountryController,
              onChanged: (value) => _formData.sellerCountry = value,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'País del Comprador',
              controller: _buyerCountryController,
              onChanged: (value) => _formData.buyerCountry = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración Adicional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Términos de Pago',
              value: _formData.paymentTerms.isEmpty ? null : _formData.paymentTerms,
              items: const [
                {'value': 'prepago', 'label': 'Prepago'},
                {'value': 'carta_credito', 'label': 'Carta de Crédito'},
                {'value': 'transferencia', 'label': 'Transferencia Bancaria'},
                {'value': 'credito', 'label': 'Crédito'},
              ],
              onChanged: (value) => setState(() => _formData.paymentTerms = value ?? ''),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Nivel de Experiencia',
              value: _formData.experienceLevel.isEmpty ? null : _formData.experienceLevel,
              items: const [
                {'value': 'principiante', 'label': 'Principiante'},
                {'value': 'intermedio', 'label': 'Intermedio'},
                {'value': 'experto', 'label': 'Experto'},
              ],
              onChanged: (value) => setState(() => _formData.experienceLevel = value ?? ''),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Requiere seguro de carga'),
              value: _formData.insurance,
              onChanged: (value) => setState(() => _formData.insurance = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Requisitos Especiales',
              controller: _specialRequirementsController,
              onChanged: (value) => _formData.specialRequirements = value,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        final number = double.tryParse(value);
        if (number == null || number <= 0) {
          return 'Ingrese un número válido mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor seleccione una opción';
        }
        return null;
      },
    );
  }

  Widget _buildFormActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        LoadingButton(
          onPressed: _isFormValid() ? _calculateIncoterms : null,
          isLoading: _isCalculating,
          text: 'Calcular Incoterms',
          icon: Icons.calculate,
          fullWidth: false,
        ),
      ],
    );
  }

  Widget _buildCalculationResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecommendedIncotermSection(),
        const SizedBox(height: 24),
        _buildAlternativesSection(),
        const SizedBox(height: 24),
        _buildRouteDetailsSection(),
        const SizedBox(height: 24),
        if (_calculationResult!.warnings.isNotEmpty) ...[
          _buildWarningsSection(),
          const SizedBox(height: 24),
        ],
        _buildResultActions(),
      ],
    );
  }

  Widget _buildRecommendedIncotermSection() {
    final recommended = _calculationResult!.recommendedIncoterm;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incoterm Recomendado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  recommended.code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A6CBC),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    recommended.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: recommended.recommendationScore / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A6CBC),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recommended.recommendationScore.toInt()}% compatible',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommended.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildResponsibilitiesColumn(
                    'Responsabilidades del Vendedor',
                    recommended.sellerResponsibilities,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResponsibilitiesColumn(
                    'Responsabilidades del Comprador',
                    recommended.buyerResponsibilities,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCostBreakdown(recommended.costBreakdown),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilitiesColumn(String title, List<String> responsibilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...responsibilities.map((resp) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  resp,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCostBreakdown(CostBreakdown costs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose de Costos (USD)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildCostItem('Flete:', costs.freight),
              _buildCostItem('Seguro:', costs.insurance),
              _buildCostItem('Despacho Aduanero:', costs.customsClearance),
              _buildCostItem('Manejo en Puerto:', costs.portHandling),
              _buildCostItem('Documentación:', costs.documentation),
              const Divider(),
              _buildCostItem('Total:', costs.total, isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostItem(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternativas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._calculationResult!.alternatives.map((alt) => 
              _buildAlternativeCard(alt)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(IncotermOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  option.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A6CBC),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: option.recommendationScore / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A6CBC),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${option.recommendationScore.toInt()}%',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              option.description,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Costo Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${option.costBreakdown.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0A6CBC),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetailsSection() {
    final details = _calculationResult!.routeDetails;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Ruta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildDetailItem('Distancia:', '${details.distance.toStringAsFixed(0)} millas náuticas'),
                  _buildDetailItem('Tiempo Estimado:', details.estimatedTime),
                  _buildDetailItem('Nivel de Riesgo:', details.riskLevel, isRisk: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isRisk = false}) {
    Color? valueColor;
    if (isRisk) {
      switch (value.toLowerCase()) {
        case 'bajo':
          valueColor = Colors.green;
          break;
        case 'medio':
          valueColor = Colors.orange;
          break;
        case 'alto':
          valueColor = Colors.red;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isRisk ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advertencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._calculationResult!.warnings.map((warning) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(color: Colors.brown, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _resetCalculation,
              child: const Text('Volver al Formulario'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _createReport,
              icon: const Icon(Icons.description),
              label: const Text('Crear Informe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6CBC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 🔽 Aquí los dos botones que pediste
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _downloadPdfFromResult,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _downloadExcelFromResult,
              icon: const Icon(Icons.table_view),
              label: const Text('Descargar Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }


  bool _isFormValid() {
    return _formData.cargoType.isNotEmpty &&
           _formData.cargoValue > 0 &&
           _formData.cargoWeight > 0 &&
           _formData.cargoVolume > 0 &&
           _formData.seller.isNotEmpty &&
           _formData.buyer.isNotEmpty &&
           _formData.sellerCountry.isNotEmpty &&
           _formData.buyerCountry.isNotEmpty &&
           _formData.paymentTerms.isNotEmpty &&
           _formData.experienceLevel.isNotEmpty;
  }

  Future<void> _calculateIncoterms() async {
    if (!_formKey.currentState!.validate() || !_isFormValid()) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final result = await _incotermService.calculateIncoterms(
        _formData,
        widget.originPort,
        widget.destinationPort,
        widget.distance,
      );

      setState(() {
        _calculationResult = result;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al calcular Incoterms: $e')),
      );
    }
  }

  void _resetCalculation() {
    setState(() {
      _calculationResult = null;
    });
  }

  void _createReport() {
    if (_calculationResult == null) return;

    final now = DateTime.now();
    final report = <String, dynamic>{
      'id': now.millisecondsSinceEpoch,
      'type': 'incoterm',
      'createdAt': now.toIso8601String(),
      // Campos que usa la pantalla de reportes actual
      'shipmentId': 'INC-${now.millisecondsSinceEpoch % 100000}',
      'route': '${widget.originPort} → ${widget.destinationPort}',
      'origin': widget.originPort,
      'destination': widget.destinationPort,
      'status': 'Calculado',
      'progress': 1.0,
      'eta': _calculationResult!.routeDetails.estimatedTime,
      'cargo': _formData.cargoType,
      // Extras útiles
      'distance': widget.distance,
      'recommended': {
        'code': _calculationResult!.recommendedIncoterm.code,
        'name': _calculationResult!.recommendedIncoterm.name,
        'total': _calculationResult!.recommendedIncoterm.costBreakdown.total,
      },
      'warnings': _calculationResult!.warnings,
    };

    ReportLocalStore.addIncotermReport(report).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe guardado. Abriendo Reportes…'),
          duration: Duration(seconds: 1),
        ),
      );
      // Ir a la pantalla de reportes
      context.go(AppRoutes.shipmentReports);
    });
  }




  Future<void> _downloadPdfFromResult() async {
    if (_calculationResult == null) return;

    final pdf = pw.Document();
    final inc = _calculationResult!.recommendedIncoterm;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de Incoterm',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Ruta: ${widget.originPort} → ${widget.destinationPort}'),
              pw.Text('Distancia: ${widget.distance.toStringAsFixed(0)} millas náuticas'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Incoterm recomendado: ${inc.code} - ${inc.name}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Desglose de costos (USD):',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              // ⬇️ aquí van TODOS los campos de tu CostBreakdown
              pw.Bullet(text: 'Flete: \$${inc.costBreakdown.freight.toStringAsFixed(0)}'),
              pw.Bullet(text: 'Seguro: \$${inc.costBreakdown.insurance.toStringAsFixed(0)}'),
              pw.Bullet(
                text:
                'Despacho aduanero: \$${inc.costBreakdown.customsClearance.toStringAsFixed(0)}',
              ),
              pw.Bullet(
                text: 'Manejo en puerto: \$${inc.costBreakdown.portHandling.toStringAsFixed(0)}',
              ),
              // 🔴 ESTE FALTABA
              pw.Bullet(
                text: 'Documentación: \$${inc.costBreakdown.documentation.toStringAsFixed(0)}',
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total: \$${inc.costBreakdown.total.toStringAsFixed(0)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              if (_calculationResult!.warnings.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Advertencias:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ..._calculationResult!.warnings.map((w) => pw.Bullet(text: w)),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }


  Future<void> _downloadExcelFromResult() async {
    if (_calculationResult == null) return;

    final excel = xls.Excel.createExcel();

    // renombrar la hoja por defecto en vez de crear otra
    final defaultSheet = excel.sheets.keys.first;
    excel.rename(defaultSheet, 'Incoterm');

    final sheet = excel['Incoterm'];


    final inc = _calculationResult!.recommendedIncoterm;

    // helper para no repetir
    xls.CellValue txt(String v) => xls.TextCellValue(v);

    // estilos sencillos compatibles
    final headerStyle = xls.CellStyle(
      bold: true,
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
    );

    final bodyStyle = xls.CellStyle(
      verticalAlign: xls.VerticalAlign.Center,
    );

    final moneyStyle = xls.CellStyle(
      verticalAlign: xls.VerticalAlign.Center,
      horizontalAlign: xls.HorizontalAlign.Right,
    );

    // 1) encabezados
    final headers = [
      'Origen',
      'Destino',
      'Distancia (mn)',
      'Incoterm',
      'Nombre',
      'Flete',
      'Seguro',
      'Despacho Aduanero',
      'Manejo en Puerto',
      'Documentación',
      'Costo Total (USD)',
    ];

    sheet.appendRow(headers.map((h) => txt(h)).toList());

    // aplicar estilo header (fila 0)
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    // 2) fila de datos principal
    final dataRow = [
      txt(widget.originPort),
      txt(widget.destinationPort),
      txt(widget.distance.toStringAsFixed(0)),
      txt(inc.code),
      txt(inc.name),
      txt(inc.costBreakdown.freight.toStringAsFixed(0)),
      txt(inc.costBreakdown.insurance.toStringAsFixed(0)),
      txt(inc.costBreakdown.customsClearance.toStringAsFixed(0)),
      txt(inc.costBreakdown.portHandling.toStringAsFixed(0)),
      txt(inc.costBreakdown.documentation.toStringAsFixed(0)),
      txt(inc.costBreakdown.total.toStringAsFixed(0)),
    ];

    sheet.appendRow(dataRow);

    // aplicar estilo a fila 1
    for (int col = 0; col < dataRow.length; col++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
      );
      if (col >= 5) {
        cell.cellStyle = moneyStyle;
      } else {
        cell.cellStyle = bodyStyle;
      }
    }

    // 3) sección de alternativas
    if (_calculationResult!.alternatives.isNotEmpty) {
      // fila vacía
      sheet.appendRow([txt('')]);

      // título de la sección
      final titleRowIndex = sheet.maxRows;
      sheet.appendRow([txt('Alternativas recomendadas')]);
      final titleCell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: titleRowIndex),
      );
      titleCell.cellStyle = xls.CellStyle(bold: true);

      // encabezados de alternativas
      final altHeaderIndex = sheet.maxRows;
      final altHeaders = [
        'Código',
        'Nombre',
        'Score (%)',
        'Total (USD)',
      ];
      sheet.appendRow(altHeaders.map((h) => txt(h)).toList());
      for (int col = 0; col < altHeaders.length; col++) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: altHeaderIndex),
        );
        cell.cellStyle = headerStyle;
      }

      // filas de alternativas
      for (final alt in _calculationResult!.alternatives) {
        final r = [
          txt(alt.code),
          txt(alt.name),
          txt(alt.recommendationScore.toStringAsFixed(0)),
          txt(alt.costBreakdown.total.toStringAsFixed(0)),
        ];
        sheet.appendRow(r);

        final currentRow = sheet.maxRows - 1;
        for (int col = 0; col < r.length; col++) {
          final cell = sheet.cell(
            xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow),
          );
          if (col >= 2) {
            cell.cellStyle = moneyStyle;
          } else {
            cell.cellStyle = bodyStyle;
          }
        }
      }
    }

    // exportar
    final bytes = excel.encode()!;
    final uint8 = Uint8List.fromList(bytes);

    await Printing.sharePdf(
      bytes: uint8,
      filename: 'reporte_incoterm.xlsx',
    );
  }




  @override
  void dispose() {
    _cargoValueController.dispose();
    _cargoWeightController.dispose();
    _cargoVolumeController.dispose();
    _sellerController.dispose();
    _buyerController.dispose();
    _sellerCountryController.dispose();
    _buyerCountryController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }
}
