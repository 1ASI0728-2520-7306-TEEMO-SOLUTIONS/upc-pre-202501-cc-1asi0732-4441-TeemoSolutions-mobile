import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_drawer.dart';

/// Shipment reports screen matching Angular's ShipmentReportsComponent
class ShipmentReportsScreen extends StatefulWidget {
  const ShipmentReportsScreen({super.key});

  @override
  State<ShipmentReportsScreen> createState() => _ShipmentReportsScreenState();
}

class _ShipmentReportsScreenState extends State<ShipmentReportsScreen> {
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 1,
      'shipmentId': 'SH001',
      'route': 'Atlantic Express',
      'origin': 'New York',
      'destination': 'London',
      'status': 'In Transit',
      'progress': 0.65,
      'eta': '2024-02-15',
      'cargo': 'Electronics',
    },
    {
      'id': 2,
      'shipmentId': 'SH002',
      'route': 'Pacific Route',
      'origin': 'Los Angeles',
      'destination': 'Tokyo',
      'status': 'Delivered',
      'progress': 1.0,
      'eta': '2024-02-10',
      'cargo': 'Automotive Parts',
    },
    {
      'id': 3,
      'shipmentId': 'SH003',
      'route': 'Mediterranean Line',
      'origin': 'Barcelona',
      'destination': 'Istanbul',
      'status': 'Scheduled',
      'progress': 0.0,
      'eta': '2024-02-20',
      'cargo': 'Textiles',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'In Transit', 'Delivered', 'Scheduled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReports,
            tooltip: 'Download Reports',
          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewReport,
        child: const Icon(Icons.add),
        tooltip: 'Add New Report',
      ),
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
        : _reports.where((report) => report['status'] == _selectedFilter).toList();

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

  void _refreshReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing reports...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addNewReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Report'),
        content: const Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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

  void _downloadSingleReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading report ${report['shipmentId']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
