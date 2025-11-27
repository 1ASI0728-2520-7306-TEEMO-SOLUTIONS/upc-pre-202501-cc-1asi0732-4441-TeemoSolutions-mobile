import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../../data/services/report_local_store.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
/// Shipment reports screen matching Angular's ShipmentReportsComponent
class ShipmentReportsScreen extends StatefulWidget {
  const ShipmentReportsScreen({super.key});

  @override
  State<ShipmentReportsScreen> createState() => _ShipmentReportsScreenState();
}

class _ShipmentReportsScreenState extends State<ShipmentReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Calculado', 'In Transit', 'Delivered', 'Scheduled'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Reports'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.download),
          //   onPressed: _downloadReports,
          //   tooltip: 'Download Reports',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // Reports List
          Expanded(
            child: _buildReportsList(),
          ),
        ],
      ),
      // Sin FAB por ahora: los informes se generan desde otras pantallas
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Text(
            'Filter by Status:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              items: _filterOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
  final filteredReports = _selectedFilter == 'All'
    ? _reports
    : _reports.where((report) => (report['status'] ?? '').toString() == _selectedFilter).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter or add a new report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report['shipmentId'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(report['status']),
              ],
            ),
            const SizedBox(height: 8),
            
            // Route Information
            Text(
              report['route'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              '${report['origin']} → ${report['destination']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Incoterm (si proviene de la calculadora de Incoterms)
            if (report['recommended'] is Map &&
                ((report['recommended'] as Map)['code'] ?? '') != '') ...[
              Row(
                children: [
                  Chip(
                    label: Text(
                      'Incoterm: ${(report['recommended'] as Map)['code']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF0A6CBC),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (report['recommended'] as Map)['name'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Costo total estimado',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatMoney((((report['recommended'] as Map)['total']) ?? 0).toDouble()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Progress Bar (if in transit)
            if (report['status'] == 'In Transit') ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: report['progress'].toDouble(),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(report['progress'] * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Details Row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Cargo', report['cargo']),
                ),
                Expanded(
                  child: _buildDetailItem('ETA', report['eta']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewReportDetails(report),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _downloadSingleReport(report),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'In Transit':
        color = const Color(0xFF1976D2);
        break;
      case 'Delivered':
        color = const Color(0xFF4CAF50);
        break;
      case 'Scheduled':
        color = const Color(0xFFFFA726);
        break;
      default:
        color = const Color(0xFFFFA726);
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _downloadReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading all reports...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadReports() async {
    final data = await ReportLocalStore.loadIncotermReports();
    setState(() {
      _reports = data;
    });
  }

  Future<void> _refreshReports() async {
    await _loadReports();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reportes actualizados')),
    );
  }

  void _viewReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details - ${report['shipmentId']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${report['route']}'),
            Text('Origin: ${report['origin']}'),
            Text('Destination: ${report['destination']}'),
            Text('Status: ${report['status']}'),
            Text('Cargo: ${report['cargo']}'),
            Text('ETA: ${report['eta']}'),
            const SizedBox(height: 8),
            if ((report['recommended'] ?? const {}) is Map &&
                (report['recommended']['code'] ?? '') != '') ...[
              const Divider(),
              const Text(
                'Incoterm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Código: ${report['recommended']['code']}'),
              Text('Nombre: ${report['recommended']['name']}'),
              Text('Costo Total: ${_formatMoney((report['recommended']['total'] ?? 0).toDouble())}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    if (value.isNaN || value.isInfinite) return '\$0';
    return '\$' + value.toStringAsFixed(0);
  }



  void _downloadSingleReport(Map<String, dynamic> report) async {
    // construimos el pdf
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de Envío',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Text('ID de envío: ${report['shipmentId'] ?? '-'}'),
              pw.Text('Ruta: ${report['route'] ?? '-'}'),
              pw.Text('Origen: ${report['origin'] ?? '-'}'),
              pw.Text('Destino: ${report['destination'] ?? '-'}'),
              pw.Text('Estado: ${report['status'] ?? '-'}'),
              pw.Text('ETA: ${report['eta'] ?? '-'}'),
              pw.Text('Carga: ${report['cargo'] ?? '-'}'),
              pw.SizedBox(height: 12),

              // Si viene de IncotermCalculator
              if ((report['recommended'] ?? const {}) is Map &&
                  (report['recommended']['code'] ?? '') != '') ...[
                pw.Divider(),
                pw.Text(
                  'Incoterm recomendado',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Código: ${report['recommended']['code']}'),
                pw.Text('Nombre: ${report['recommended']['name'] ?? ''}'),
                pw.Text(
                  'Costo total: ${_formatMoney(((report['recommended']['total']) ?? 0).toDouble())}',
                ),
              ],
            ],
          );
        },
      ),
    );

    // abrir el diálogo de impresión/descarga
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'reporte_${report['shipmentId'] ?? 'envio'}.pdf',
    );
  }

}
