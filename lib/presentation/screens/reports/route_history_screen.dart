import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_drawer.dart';

/// Route history screen matching Angular's RouteHistoryComponent
class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  final List<Map<String, dynamic>> _routeHistory = [
    {
      'id': 1,
      'routeName': 'Atlantic Express',
      'startDate': '2024-01-15',
      'endDate': '2024-01-28',
      'origin': 'New York',
      'destination': 'London',
      'distance': '3,459 nm',
      'duration': '13 days',
      'vessels': 2,
      'status': 'Completed',
    },
    {
      'id': 2,
      'routeName': 'Pacific Route',
      'startDate': '2024-01-20',
      'endDate': '2024-02-05',
      'origin': 'Los Angeles',
      'destination': 'Tokyo',
      'distance': '5,156 nm',
      'duration': '16 days',
      'vessels': 1,
      'status': 'Completed',
    },
    {
      'id': 3,
      'routeName': 'Mediterranean Line',
      'startDate': '2024-02-01',
      'endDate': null,
      'origin': 'Barcelona',
      'destination': 'Istanbul',
      'distance': '1,245 nm',
      'duration': '7 days',
      'vessels': 3,
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _routeHistory.length,
        itemBuilder: (context, index) {
          final route = _routeHistory[index];
          return _buildRouteHistoryCard(route);
        },
      ),
    );
  }

  Widget _buildRouteHistoryCard(Map<String, dynamic> route) {
    final isActive = route['status'] == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route['routeName'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(route['status']),
              ],
            ),
            const SizedBox(height: 12),
            
            // Route Details
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${route['origin']} → ${route['destination']}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Distance', route['distance'], Icons.straighten),
                ),
                Expanded(
                  child: _buildStatItem('Duration', route['duration'], Icons.schedule),
                ),
                Expanded(
                  child: _buildStatItem('Vessels', route['vessels'].toString(), Icons.directions_boat),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Date:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        route['startDate'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!isActive) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End Date:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          route['endDate'] ?? 'In Progress',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive) ...[
                  TextButton.icon(
                    onPressed: () => _trackRoute(route),
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () => _viewRouteDetails(route),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _exportRoute(route),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
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
      case 'Cancelled':
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Routes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Active Routes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Completed Routes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelled Routes'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Routes'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter route name or destination...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _trackRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking route: ${route['routeName']}'),
        action: SnackBarAction(
          label: 'View Map',
          onPressed: () {
            // Navigate to map view
          },
        ),
      ),
    );
  }

  void _viewRouteDetails(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route['routeName']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Origin', route['origin']),
              _buildDetailRow('Destination', route['destination']),
              _buildDetailRow('Distance', route['distance']),
              _buildDetailRow('Duration', route['duration']),
              _buildDetailRow('Vessels', route['vessels'].toString()),
              _buildDetailRow('Status', route['status']),
              _buildDetailRow('Start Date', route['startDate']),
              if (route['endDate'] != null)
                _buildDetailRow('End Date', route['endDate']),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _exportRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting route: ${route['routeName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
