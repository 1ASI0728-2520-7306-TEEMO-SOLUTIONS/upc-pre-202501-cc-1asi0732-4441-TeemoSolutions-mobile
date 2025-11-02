import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../data/models/port_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/services/port_service.dart';
import '../../../data/services/route_service.dart';
import '../../widgets/common/loading_button.dart';
import 'route_animation_screen.dart';
import 'incoterm_calculator_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;


class PortSelectorScreen extends StatefulWidget {
  const PortSelectorScreen({Key? key}) : super(key: key);


  @override
  State<PortSelectorScreen> createState() => _PortSelectorScreenState();
}

class _PortSelectorScreenState extends State<PortSelectorScreen> {
  final PortService _portService = PortService();
  final RouteService _routeService = RouteService();
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destinationSearchController = TextEditingController();
  final TextEditingController _intermediateSearchController = TextEditingController();


  List<Port> _allPorts = [];
  List<Port> _filteredOriginPorts = [];
  List<Port> _filteredDestinationPorts = [];
  List<Port> _filteredIntermediatePorts = [];
  
  Port? _selectedOriginPort;
  Port? _selectedDestinationPort;
  List<Port> _selectedIntermediatePorts = [];
  
  bool _isLoadingPorts = true;
  bool _showRouteVisualization = false;
  RouteCalculationResource? _routeData;
  bool _isCalculatingRoute = false;



  @override
  void initState() {
    super.initState();
    _loadPorts();
  }

  List<ll.LatLng> _buildLatLngRoute(dynamic data) {
    // A) Formato nuevo (lo que muestras en tu JSON): optimalRoute + coordinatesMapping
    try {
      final optimal = (data.optimalRoute as List<String>?) ?? const <String>[];
      final mapping = (data.coordinatesMapping as Map<String, dynamic>?) ?? const {};
      if (optimal.isNotEmpty && mapping.isNotEmpty) {
        final pts = <ll.LatLng>[];
        for (final name in optimal) {
          final c = mapping[name];
          if (c != null) {
            final lat = (c.latitude as num?)?.toDouble() ?? (c['latitude'] as num?)?.toDouble();
            final lon = (c.longitude as num?)?.toDouble() ?? (c['longitude'] as num?)?.toDouble();
            if (lat != null && lon != null) pts.add(ll.LatLng(lat, lon));
          }
        }
        if (pts.isNotEmpty) return pts;
      }
    } catch (_) {} // si falla, probamos formato legacy

    // B) Formato legacy (tu modelo antiguo): coordinates: List<PortCoordinates>
    try {
      final coords = (data.coordinates as List?) ?? const [];
      if (coords.isNotEmpty) {
        return coords.map((c) {
          final lat = (c.latitude as num?)?.toDouble() ?? (c['latitude'] as num).toDouble();
          final lon = (c.longitude as num?)?.toDouble() ?? (c['longitude'] as num).toDouble();
          return ll.LatLng(lat, lon);
        }).toList();
      }
    } catch (_) {}

    return const <ll.LatLng>[];
  }



  Future<void> _loadPorts() async {
    try {
      final ports = await _portService.getAllPorts();
      setState(() {
        _allPorts = ports;
        _filteredOriginPorts = [...ports];
        _filteredDestinationPorts = [...ports];
        _filteredIntermediatePorts = [...ports];
        _isLoadingPorts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPorts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar puertos: $e')),
      );
    }
  }

  void _searchOriginPorts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOriginPorts = [..._allPorts];
      } else {
        _filteredOriginPorts = _allPorts.where((port) =>
          port.name.toLowerCase().contains(query.toLowerCase()) ||
          port.continent.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _searchDestinationPorts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDestinationPorts = [..._allPorts];
      } else {
        _filteredDestinationPorts = _allPorts.where((port) =>
          port.name.toLowerCase().contains(query.toLowerCase()) ||
          port.continent.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }



  void _searchIntermediatePorts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIntermediatePorts = [..._allPorts];
      } else {
        _filteredIntermediatePorts = _allPorts.where((port) =>
          port.name.toLowerCase().contains(query.toLowerCase()) ||
          port.continent.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _selectOriginPort(Port port) {
    setState(() {
      _selectedOriginPort = port;
      if (_showRouteVisualization) {
        _showRouteVisualization = false;
        _routeData = null;
      }
    });
  }

  void _selectDestinationPort(Port port) {
    setState(() {
      _selectedDestinationPort = port;
      if (_showRouteVisualization) {
        _showRouteVisualization = false;
        _routeData = null;
      }
    });
  }

  void _toggleIntermediatePort(Port port) {
    setState(() {
      if (_selectedIntermediatePorts.contains(port)) {
        _selectedIntermediatePorts.remove(port);
      } else if (port != _selectedOriginPort && port != _selectedDestinationPort) {
        _selectedIntermediatePorts.add(port);
      }
      
      if (_showRouteVisualization) {
        _showRouteVisualization = false;
        _routeData = null;
      }
    });
  }

  bool _isPortDisabled(Port port) {
    return port == _selectedOriginPort || port == _selectedDestinationPort;
  }

  Future<void> _visualizeRoute() async {
    if (_selectedOriginPort == null || _selectedDestinationPort == null) {
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final intermediatePortNames = _selectedIntermediatePorts.map((port) => port.name).toList();
      
      final routeData = await _routeService.calculateOptimalRoute(
        _selectedOriginPort!.name,
        _selectedDestinationPort!.name,
        intermediatePortNames,
      );

      setState(() {
        _routeData = routeData;
        _showRouteVisualization = true;
        _isCalculatingRoute = false;
      });
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al calcular la ruta: $e')),
      );
    }
  }

  Future<void> _createRoute() async {
    if (_selectedOriginPort == null || _selectedDestinationPort == null) {
      return;
    }

    if (_routeData == null) {
      await _visualizeRoute();
      return;
    }

    try {
      final routeData = {
        'name': '${_selectedOriginPort!.name} a ${_selectedDestinationPort!.name}',
        'originPortId': _selectedOriginPort!.id,
        'destinationPortId': _selectedDestinationPort!.id,
        'departureDate': DateTime.now().toIso8601String(),
        'vessels': 1,
        'status': 'Planificada',
        'intermediatePorts': _selectedIntermediatePorts.map((port) => port.id).toList(),
        'routeData': _routeData,
      };

      await _routeService.createRouteReport(routeData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta creada con éxito. Se ha generado un informe que puede consultar en la sección de Informes de Envíos.'),
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la ruta: $e')),
      );
    }
  }

  void _showIncotermCalculator() {
    if (_routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe visualizar la ruta')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncotermCalculatorScreen(
          originPort: _selectedOriginPort?.name ?? '',
          destinationPort: _selectedDestinationPort?.name ?? '',
          distance: _routeData?.totalDistance ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selección de Puertos para Nueva Ruta'),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPorts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPortSelectionSection(),
                  const SizedBox(height: 24),
                  _buildIntermediatePortsSection(),
                  const SizedBox(height: 24),
                  if (_showRouteVisualization) _buildRouteVisualizationSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPortSelectionSection() {
    return Row(
      children: [
        Expanded(
          child: _buildPortSelectionCard(
            title: 'Puerto de Origen',
            searchController: _originSearchController,
            filteredPorts: _filteredOriginPorts,
            selectedPort: _selectedOriginPort,
            onSearch: _searchOriginPorts,
            onPortSelected: _selectOriginPort,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPortSelectionCard(
            title: 'Puerto de Destino',
            searchController: _destinationSearchController,
            filteredPorts: _filteredDestinationPorts,
            selectedPort: _selectedDestinationPort,
            onSearch: _searchDestinationPorts,
            onPortSelected: _selectDestinationPort,
          ),
        ),
      ],
    );
  }

  Widget _buildPortSelectionCard({
    required String title,
    required TextEditingController searchController,
    required List<Port> filteredPorts,
    required Port? selectedPort,
    required Function(String) onSearch,
    required Function(Port) onPortSelected,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar puerto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: onSearch,
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Nombre del Puerto',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Continente',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredPorts.length,
                      itemBuilder: (context, index) {
                        final port = filteredPorts[index];
                        final isSelected = selectedPort?.id == port.id;
                        
                        return InkWell(
                          onTap: () => onPortSelected(port),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : null,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.anchor, size: 16, color: Color(0xFF0A6CBC)),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    port.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    port.continent,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntermediatePortsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puertos Intermedios (Opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seleccione los puertos intermedios por los que desea que pase la ruta.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _intermediateSearchController,
              decoration: InputDecoration(
                hintText: 'Buscar puertos intermedios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _intermediateSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _intermediateSearchController.clear();
                          _searchIntermediatePorts('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: _searchIntermediatePorts,
            ),
            const SizedBox(height: 12),
            if (_selectedIntermediatePorts.isNotEmpty) ...[
              Text(
                'Puertos intermedios seleccionados (${_selectedIntermediatePorts.length}):',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedIntermediatePorts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final port = entry.value;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFF0A6CBC),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    label: Text(port.name),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _toggleIntermediatePort(port),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Nombre del Puerto',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Continente',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredIntermediatePorts.length,
                      itemBuilder: (context, index) {
                        final port = _filteredIntermediatePorts[index];
                        final isSelected = _selectedIntermediatePorts.contains(port);
                        final isDisabled = _isPortDisabled(port);
                        
                        return InkWell(
                          onTap: isDisabled ? null : () => _toggleIntermediatePort(port),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blue.shade50 
                                  : isDisabled 
                                      ? Colors.grey.shade100 
                                      : null,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.anchor, 
                                  size: 16, 
                                  color: isDisabled 
                                      ? Colors.grey 
                                      : const Color(0xFF0A6CBC),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    port.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDisabled ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    port.continent,
                                    style: TextStyle(
                                      color: isDisabled ? Colors.grey : Colors.grey.shade600, 
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteVisualizationSection() {
    if (_routeData == null) return const SizedBox.shrink();

    final points = _buildLatLngRoute(_routeData!);
    // Debug para confirmar
    // print('POINTS LEN = ${points.length}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visualización de Ruta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Resumen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildSummaryItem('Origen:', _selectedOriginPort?.name ?? ''),
                  _buildSummaryItem('Destino:', _selectedDestinationPort?.name ?? ''),
                  _buildSummaryItem('Distancia Total:', '${_routeData!.totalDistance.toStringAsFixed(0)} millas náuticas'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            const Text('Información de la Ruta', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    if ((_routeData!.warnings).isNotEmpty) ...[
                      const SizedBox(height: 8),

                      const SizedBox(height: 6),
                      ..._routeData!.warnings.map((w) => Row(
                         children: [
                           const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                           const SizedBox(width: 6),
                           Expanded(child: Text(w)),
                         ],
                      )).toList(),
                    ],
                  ]
                )
              ),


            const SizedBox(height: 12),

            // Mapa
            SizedBox(
              height: 260,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points.isNotEmpty ? points.first : const ll.LatLng(0, 0),
                  initialZoom: 3.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mushroom_mobile',
                  ),
                  if (points.length > 1)
                    PolylineLayer(polylines: [Polyline(points: points, strokeWidth: 4)]),
                  MarkerLayer(markers: [
                    if (points.isNotEmpty)
                      Marker(
                        point: points.first,
                        width: 30, height: 30,
                        child: const Icon(Icons.place, color: Colors.green),
                      ),
                    if (points.length > 1)
                      Marker(
                        point: points.last,
                        width: 30, height: 30,
                        child: const Icon(Icons.flag, color: Colors.red),
                      ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botón Animar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: points.length >= 2
                    ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteAnimationScreen(points: points),
                    ),
                  );
                }
                    : null,
                icon: const Icon(Icons.directions_boat),
                label: const Text('Animar ruta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6CBC),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),


          ],
        ),
      ),
    );
  }


  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: (_selectedOriginPort != null && _selectedDestinationPort != null)
              ? _visualizeRoute
              : null,
          icon: _isCalculatingRoute
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.map),
          label: Text(_isCalculatingRoute ? 'Calculando...' : 'Visualizar Ruta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: (_selectedOriginPort != null && _selectedDestinationPort != null)
              ? _createRoute
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Crear Ruta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A6CBC),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _routeData != null ? _showIncotermCalculator : null,
          icon: const Icon(Icons.calculate),
          label: const Text('Calcular Incoterm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _originSearchController.dispose();
    _destinationSearchController.dispose();
    _intermediateSearchController.dispose();
    super.dispose();
  }
}

class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key, required this.points});
  final List<ll.LatLng> points;


  @override
  Widget build(BuildContext context) {
    final bounds = _bounds(points);

    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.isNotEmpty ? points.first : const ll.LatLng(0, 0),
            initialZoom: 4,
            bounds: bounds,
            boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(48)),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
          ),
          children: [
            // Tiles (OSM por defecto)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mushroom_mobile',
            ),
            // Polilínea de la ruta
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: points, strokeWidth: 4),
                ],
              ),
            // Marcadores origen/destino
            MarkerLayer(markers: [
              if (points.isNotEmpty)
                Marker(
                  point: points.first,
                  width: 32, height: 32,
                  child: const Icon(Icons.place, size: 28),
                ),
              if (points.length > 1)
                Marker(
                  point: points.last,
                  width: 32, height: 32,
                  child: const Icon(Icons.flag, size: 28),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  LatLngBounds? _bounds(List<ll.LatLng> pts) {
    if (pts.length < 2) return null;
    var sw = ll.LatLng(pts.first.latitude, pts.first.longitude);
    var ne = ll.LatLng(pts.first.latitude, pts.first.longitude);
    for (final p in pts) {
      sw = ll.LatLng(
        (p.latitude  < sw.latitude)  ? p.latitude  : sw.latitude,
        (p.longitude < sw.longitude) ? p.longitude : sw.longitude,
      );
      ne = ll.LatLng(
        (p.latitude  > ne.latitude)  ? p.latitude  : ne.latitude,
        (p.longitude > ne.longitude) ? p.longitude : ne.longitude,
      );
    }
    return LatLngBounds(sw, ne);
  }
}

class RouteAnimationScreen extends StatefulWidget {
  const RouteAnimationScreen({super.key, required this.points});
  final List<ll.LatLng> points;

  @override
  State<RouteAnimationScreen> createState() => _RouteAnimationScreenState();
}

class _RouteAnimationScreenState extends State<RouteAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animación de Ruta'),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: widget.points.isNotEmpty
                    ? widget.points.first
                    : const ll.LatLng(0, 0),
                initialZoom: 3.5,
                interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tuapp.nombre',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: widget.points, strokeWidth: 4),
                  ],
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    if (widget.points.isEmpty) return const SizedBox.shrink();
                    final progress = _animation.value;
                    final index = (progress * (widget.points.length - 1)).toInt();
                    final pos = widget.points[index.clamp(0, widget.points.length - 1)];
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: pos,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.directions_boat,
                            size: 32,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _controller.forward(from: 0),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _controller.stop(),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.stop();
                    _controller.reset();
                    setState(() {});
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
