import 'package:flutter/material.dart';
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
      setState(() {
        _isLoadingPorts = false;
      });
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
                              'Para funcionalidades avanzadas como selección de puertos intermedios y cálculo de Incoterms, use "Seleccionar Puertos" desde el dashboard.',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un nombre para la ruta';
                                }
                                return null;
                              },
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
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      final vessels = int.tryParse(value);
                                      if (vessels == null || vessels <= 0) {
                                        return 'Número inválido';
                                      }
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
      validator: (value) {
        if (value == null) {
          return 'Requerido';
        }
        return null;
      },
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

    if (date != null) {
      setState(() {
        _departureDate = date;
      });
    }
  }

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_originPort == null || _destinationPort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione puertos de origen y destino')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calcular la ruta óptima
      final routeData = await _routeService.calculateOptimalRoute(
        _originPort!.name,
        _destinationPort!.name,
        [], // Sin puertos intermedios en ruta rápida
      );

      // Navegar a la pantalla de animación
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RouteAnimationScreen(
            routeName: _routeNameController.text,
            originPort: _originPort!,
            destinationPort: _destinationPort!,
            intermediatePorts: const [], // Sin puertos intermedios
            routeData: routeData,
            departureDate: _departureDate,
            vessels: int.parse(_vesselsController.text),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la ruta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _vesselsController.dispose();
    super.dispose();
  }
}
