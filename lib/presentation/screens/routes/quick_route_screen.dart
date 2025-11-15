import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/port_model.dart';
import '../../../data/services/port_service.dart';
import '../../../data/services/route_service.dart';
import '../../widgets/common/loading_button.dart';
import 'route_animation_screen.dart';

class QuickRouteScreen extends StatefulWidget {
  const QuickRouteScreen({Key? key}) : super(key: key);

  @override
  State<QuickRouteScreen> createState() => _QuickRouteScreenState();
}

class _QuickRouteScreenState extends State<QuickRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _vesselsController = TextEditingController(text: '1');
  final PortService _portService = PortService();
  final RouteService _routeService = RouteService();

  List<Port> _allPorts = [];
  Port? _originPort;
  Port? _destinationPort;
  DateTime _departureDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingPorts = true;

  @override
  void initState() {
    super.initState();
    _loadPorts();
  }

  Future<void> _loadPorts() async {
    try {
      final ports = await _portService.getAllPorts();
      setState(() {
        _allPorts = ports;
        _isLoadingPorts = false;
      });
    } catch (e) {
      setState(() => _isLoadingPorts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar puertos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta Rápida'),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPorts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crear Ruta Rápida',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Para funciones avanzadas (puertos intermedios, Incoterms) usa "Seleccionar Puertos" desde el dashboard.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _routeNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la Ruta',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.route),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPortDropdown(
                                    label: 'Puerto de Origen',
                                    value: _originPort,
                                    onChanged: (port) {
                                      setState(() {
                                        _originPort = port;
                                        _updateRouteName();
                                      });
                                    },
                                    icon: Icons.flight_takeoff,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPortDropdown(
                                    label: 'Puerto de Destino',
                                    value: _destinationPort,
                                    onChanged: (port) {
                                      setState(() {
                                        _destinationPort = port;
                                        _updateRouteName();
                                      });
                                    },
                                    icon: Icons.flight_land,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _vesselsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Embarcaciones',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.directions_boat),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Requerido';
                                      final vessels = int.tryParse(value);
                                      if (vessels == null || vessels <= 0) return 'Número inválido';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDepartureDate,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        LoadingButton(
                          onPressed: _createRoute,
                          isLoading: _isLoading,
                          text: 'Crear y Ver Animación',
                          icon: Icons.play_circle,
                          fullWidth: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPortDropdown({
    required String label,
    required Port? value,
    required Function(Port?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<Port>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      items: _allPorts.map((port) {
        return DropdownMenuItem<Port>(
          value: port,
          child: Text(
            '${port.name} (${port.continent})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Requerido' : null,
    );
  }

  void _updateRouteName() {
    if (_originPort != null && _destinationPort != null) {
      _routeNameController.text = '${_originPort!.name} a ${_destinationPort!.name}';
    }
  }

  Future<void> _selectDepartureDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _departureDate = date);
  }

  // --- EXTRACTOR ROBUSTO DE POLILÍNEA DESDE routeData ----
  List<LatLng> _extractPolyline(dynamic data) {
    dynamic candidate = data;

    // Si viene envuelto
    if (candidate is Map) {
      for (final k in const [
        'polyline', 'points', 'route', 'coordinates', 'path', 'data'
      ]) {
        if (candidate[k] != null) {
          candidate = candidate[k];
          break;
        }
      }
    }

    // Ya debería ser una lista
    if (candidate is List) {
      final out = <LatLng>[];
      for (final p in candidate) {
        if (p is LatLng) {
          out.add(p);
        } else if (p is List && p.length >= 2) {
          final lat = _toDouble(p[0]);
          final lng = _toDouble(p[1]);
          if (lat != null && lng != null) out.add(LatLng(lat, lng));
        } else if (p is Map) {
          final lat = _toDouble(p['lat'] ?? p['latitude']);
          final lng = _toDouble(p['lng'] ?? p['lon'] ?? p['longitude']);
          if (lat != null && lng != null) out.add(LatLng(lat, lng));
        }
      }
      return out;
    }

    // Si todo falla, lista vacía
    return const <LatLng>[];
  }

  double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
    }

  // -------------------------------------------------------

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) return;

    if (_originPort == null || _destinationPort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione puertos de origen y destino')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final routeData = await _routeService.calculateOptimalRoute(
        _originPort!.name,
        _destinationPort!.name,
        const [], // rápida: sin intermedios
      );

      final polyline = _extractPolyline(routeData);
      if (polyline.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La ruta no tiene suficientes puntos para animar.')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RouteAnimationScreen(
            polyline: polyline,
            initialKnots: 20,
            followBoat: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la ruta: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _vesselsController.dispose();
    super.dispose();
  }
}
