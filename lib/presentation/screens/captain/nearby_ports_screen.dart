import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_drawer.dart';

// AJUSTA estos imports a tus rutas reales:
import '../../../data/services/nearby_port_service.dart';
import '../../../data/models/port_overview_model.dart';
import '../../../data/services/auth_service.dart';

class NearbyPortsScreen extends StatefulWidget {
  const NearbyPortsScreen({super.key});

  @override
  State<NearbyPortsScreen> createState() => _NearbyPortsScreenState();
}

class _NearbyPortsScreenState extends State<NearbyPortsScreen> {
  late final NearbyPortService _nearbyPortService;

  bool _isLoading = false;
  String _sortBy = 'name'; // 'name' | 'traffic'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // datos traídos de la API
  List<PortOverviewItem> _ports = [];
  int _currentPage = 0; // 0-based
  int _pageSize = 10;
  int _totalElements = 0;
  DateTime? _lastSyncedAt; // <-- ahora DateTime?

  @override
  void initState() {
    super.initState();
    // el servicio necesita AuthService => NearbyPortService(this._authService)
    _nearbyPortService = NearbyPortService(AuthService());
    _loadPorts(page: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalPages {
    if (_pageSize <= 0) return 1;
    if (_totalElements == 0) return 1;
    return ((_totalElements + _pageSize - 1) ~/ _pageSize);
  }

  Future<void> _loadPorts({required int page}) async {
    setState(() => _isLoading = true);

    try {
      final resp = await _nearbyPortService.getPortOverview(
        // si tu servicio admite state, puedes pasar uno luego
        page: page,
        size: _pageSize,
      );

      setState(() {
        _ports = resp.content;
        _totalElements = resp.totalElements;
        _lastSyncedAt = resp.lastSyncedAt; // DateTime?
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo obtener la información de puertos: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado global de puertos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Ordenar',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildLocationHeader(),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar puerto o país...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // LISTA
          Expanded(child: _buildPortsList()),

          // PAGINACIÓN
          _buildPaginationControls(),
        ],
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
            Icons.public,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado global de puertos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Total: $_totalElements puertos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_lastSyncedAt != null)
                  Text(
                    'Última sincronización: ${_lastSyncedAt!.toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortsList() {
    // filtro en memoria
    final filtered = _ports.where((p) {
      if (_searchQuery.isEmpty) return true;
      final name = p.name.toLowerCase();
      final country = (p.country ?? '').toLowerCase();
      return name.contains(_searchQuery) || country.contains(_searchQuery);
    }).toList();

    // orden
    if (_sortBy == 'traffic') {
      filtered.sort((a, b) => (b.traffic ?? 0).compareTo(a.traffic ?? 0));
    } else {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No se encontraron puertos para los filtros actuales.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final port = filtered[index];
        return _buildPortCard(port);
      },
    );
  }

  Widget _buildPortCard(PortOverviewItem port) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        port.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              port.portId,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '· ${port.country ?? ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(port.status),
              ],
            ),
            const SizedBox(height: 16),

            // TRÁFICO + COORDENADAS
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Tráfico',
                    port.traffic != null
                        ? '${port.traffic} buques/día (aprox.)'
                        : 'Sin datos',
                    Icons.directions_boat,
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: _buildInfoItem(
                    'Coordenadas',
                    '${port.lat.toStringAsFixed(2)}, ${port.lon.toStringAsFixed(2)}',
                    Icons.location_on,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (port.reason != null && port.reason!.isNotEmpty) ...[
              Text(
                'Motivo:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                port.reason!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showPortDetails(port),
                icon: const Icon(Icons.info_outline),
                label: const Text('Detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // status como String (OPEN / RESTRICTED / CLOSED)
  Widget _buildStatusChip(PortOperationalStatus status) {
    final code = status.name; // Usamos el valor "OPEN/RESTRICTED/CLOSED"

    late Color color;
    late String label;

    switch (code) {
      case 'OPEN':
        color = const Color(0xFF4CAF50); // Verde
        label = 'Open';
        break;

      case 'RESTRICTED':
        color = const Color(0xFFFFA726); // Naranja
        label = 'Restricted';
        break;

      case 'CLOSED':
        color = const Color(0xFFD32F2F); // Rojo
        label = 'Closed';
        break;

      default:
        color = Colors.grey;
        label = code;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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

  Widget _buildPaginationControls() {
    if (_totalElements <= _pageSize) return const SizedBox.shrink();

    final totalPages = _totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Página ${_currentPage + 1} de $totalPages'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                _currentPage > 0 ? () => _loadPorts(page: _currentPage - 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (_currentPage + 1) < totalPages
                    ? () => _loadPorts(page: _currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
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
              'Ordenar por',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nombre'),
              trailing: _sortBy == 'name' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _sortBy = 'name');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_boat),
              title: const Text('Tráfico'),
              trailing: _sortBy == 'traffic' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _sortBy = 'traffic');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(PortOperationalStatus status) {
    final code = status.name; // o status.toString().split('.').last;

    switch (code) {
      case 'OPEN':
        return 'Abierto';
      case 'RESTRICTED':
        return 'Restringido';
      case 'CLOSED':
        return 'Cerrado';
      default:
        return code;
    }
  }


  void _showPortDetails(PortOverviewItem port) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(port.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', port.portId),
              _buildDetailRow('País', port.country ?? '-'),
              _buildDetailRow('Coordenadas', '${port.lat}, ${port.lon}'),
              if (port.traffic != null)
                _buildDetailRow(
                    'Tráfico', '${port.traffic} buques/día (aprox.)'),
              _buildDetailRow('Estado', _statusLabel(port.status)),
              if (port.reason != null && port.reason!.isNotEmpty)
                _buildDetailRow('Motivo', port.reason!),
              if (port.contactPhone != null && port.contactPhone!.isNotEmpty)
                _buildDetailRow('Teléfono', port.contactPhone!),
              if (port.contactEmail != null && port.contactEmail!.isNotEmpty)
                _buildDetailRow('Email', port.contactEmail!),
              if (port.website != null && port.website!.isNotEmpty)
                _buildDetailRow('Web', port.website!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
            width: 90,
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
}
