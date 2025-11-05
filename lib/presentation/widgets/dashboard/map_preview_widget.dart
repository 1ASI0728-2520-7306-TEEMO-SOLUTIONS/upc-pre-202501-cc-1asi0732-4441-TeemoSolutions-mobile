import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/port_model.dart';
import '../../../data/services/port_service.dart';

class MapPreviewWidget extends StatefulWidget {
  const MapPreviewWidget({Key? key}) : super(key: key);

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  final MapController _mapController = MapController();
  List<Port> _ports = [];
  bool _isLoading = true;
  final PortService _portService = PortService();

  @override
  void initState() {
    super.initState();
    _loadPorts();
  }

  Future<void> _loadPorts() async {
    try {
      final ports = await _portService.getAllPorts();
      setState(() {
        _ports = ports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading ports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mapa de Rutas Marítimas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () => _mapController.move(
                        _mapController.center,
                        _mapController.zoom + 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () => _mapController.move(
                        _mapController.center,
                        _mapController.zoom - 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _mapController.move(
                        LatLng(20, 0),
                        2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(20, 0),
                      zoom: 2,
                      minZoom: 2,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a','b','c'],
                        userAgentPackageName: 'pe.edu.upc.mushroom',
                        maxZoom: 19,
                        tileProvider: NetworkTileProvider(
                          headers: const {
                            'User-Agent': 'pe.edu.upc.mushroom/1.0 (+https://upc.edu.pe)',
                          },
                        ),
                      ),
                      MarkerLayer(
                        markers: _ports.map((port) => Marker(
                          point: LatLng(port.coordinates.latitude, port.coordinates.longitude),
                          width: 20,
                          height: 20,
                          child: GestureDetector(
                            onTap: () => _showPortInfo(port),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.anchor,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showPortInfo(Port port) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(port.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Continente: ${port.continent}'),
            const SizedBox(height: 8),
            Text('Coordenadas: ${port.coordinates.latitude.toStringAsFixed(4)}, ${port.coordinates.longitude.toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
