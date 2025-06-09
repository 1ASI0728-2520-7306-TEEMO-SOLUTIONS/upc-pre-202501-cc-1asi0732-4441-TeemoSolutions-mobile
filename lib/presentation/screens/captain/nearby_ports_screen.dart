import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_drawer.dart';

/// Nearby ports screen matching Angular's NearbyPortsComponent
class NearbyPortsScreen extends StatefulWidget {
  const NearbyPortsScreen({super.key});

  @override
  State<NearbyPortsScreen> createState() => _NearbyPortsScreenState();
}

class _NearbyPortsScreenState extends State<NearbyPortsScreen> {
  final List<Map<String, dynamic>> _nearbyPorts = [
    {
      'id': 1,
      'name': 'Port of Hamburg',
      'code': 'DEHAM',
      'country': 'Germany',
      'distance': '12.5 nm',
      'bearing': 'NE',
      'facilities': ['Container Terminal', 'Fuel Station', 'Repair Services'],
      'coordinates': {'lat': 53.5511, 'lng': 9.9937},
      'status': 'Open',
    },
    {
      'id': 2,
      'name': 'Port of Rotterdam',
      'code': 'NLRTM',
      'country': 'Netherlands',
      'distance': '45.2 nm',
      'bearing': 'W',
      'facilities': ['Container Terminal', 'Bulk Terminal', 'Fuel Station'],
      'coordinates': {'lat': 51.9244, 'lng': 4.4777},
      'status': 'Open',
    },
    {
      'id': 3,
      'name': 'Port of Antwerp',
      'code': 'BEANR',
      'country': 'Belgium',
      'distance': '67.8 nm',
      'bearing': 'SW',
      'facilities': ['Container Terminal', 'Chemical Terminal'],
      'coordinates': {'lat': 51.2194, 'lng': 4.4025},
      'status': 'Restricted',
    },
  ];

  bool _isLoading = false;
  String _sortBy = 'distance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Ports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location Info Header
                _buildLocationHeader(),
                
                // Ports List
                Expanded(
                  child: _buildPortsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshPorts,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Ports',
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Position',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '53.5511°N, 9.9937°E',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_nearbyPorts.length} ports nearby',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortsList() {
    final sortedPorts = List<Map<String, dynamic>>.from(_nearbyPorts);
    
    if (_sortBy == 'distance') {
      sortedPorts.sort((a, b) {
        final aDistance = double.parse(a['distance'].toString().split(' ')[0]);
        final bDistance = double.parse(b['distance'].toString().split(' ')[0]);
        return aDistance.compareTo(bDistance);
      });
    } else if (_sortBy == 'name') {
      sortedPorts.sort((a, b) => a['name'].compareTo(b['name']));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: sortedPorts.length,
      itemBuilder: (context, index) {
        final port = sortedPorts[index];
        return _buildPortCard(port);
      },
    );
  }

  Widget _buildPortCard(Map<String, dynamic> port) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        port['name'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            port['code'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${port['country']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(port['status']),
              ],
            ),
            const SizedBox(height: 16),
            
            // Distance and Bearing
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Distance',
                    port['distance'],
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Bearing',
                    port['bearing'],
                    Icons.navigation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Facilities
            Text(
              'Facilities:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (port['facilities'] as List<String>).map((facility) {
                return Chip(
                  label: Text(
                    facility,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPortDetails(port),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _navigateToPort(port),
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _contactPort(port),
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact'),
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
      case 'Open':
        color = const Color(0xFF4CAF50);
        break;
      case 'Restricted':
        color = const Color(0xFFFFA726);
        break;
      case 'Closed':
        color = const Color.fromARGB(255, 195, 20, 20);
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _getCurrentLocation() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate getting location
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _showSortOptions() {
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
              'Sort By',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Distance'),
              trailing: _sortBy == 'distance' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'distance';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name'),
              trailing: _sortBy == 'name' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _refreshPorts() {
    setState(() {
      _isLoading = true;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ports refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    });
  }

  void _showPortDetails(Map<String, dynamic> port) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(port['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Code', port['code']),
              _buildDetailRow('Country', port['country']),
              _buildDetailRow('Distance', port['distance']),
              _buildDetailRow('Bearing', port['bearing']),
              _buildDetailRow('Status', port['status']),
              _buildDetailRow(
                'Coordinates',
                '${port['coordinates']['lat']}, ${port['coordinates']['lng']}',
              ),
              const SizedBox(height: 8),
              Text(
                'Facilities:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...((port['facilities'] as List<String>).map((facility) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text('• $facility'),
                ),
              )),
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

  void _navigateToPort(Map<String, dynamic> port) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation to ${port['name']} started'),
        action: SnackBarAction(
          label: 'View Map',
          onPressed: () {
            // Navigate to map view
          },
        ),
      ),
    );
  }

  void _contactPort(Map<String, dynamic> port) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${port['name']}'),
        content: const Text('Contact information will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
