import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/port_model.dart';
import '../../../data/services/port_service.dart';
import '../../../data/services/route_service.dart';
import '../../widgets/common/loading_button.dart';
import 'route_animation_screen.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({Key? key}) : super(key: key);

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _vesselsController = TextEditingController(text: '1');
  final PortService _portService = PortService();
  final RouteService _routeService = RouteService();

  List<Port> _allPorts = [];
  Port? _originPort;
  Port? _destinationPort;
  List<Port> _intermediatePorts = [];
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
        title: const Text('Crear Nueva Ruta'),
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
                    _buildRouteInfoSection(),
                    const SizedBox(height: 24),
                    _buildPortSelectionSection(),
                    const SizedBox(height: 24),
                    _buildIntermediatePortsSection(),
                    const SizedBox(height: 24),
                    _buildDepartureDateSection(),
                    const SizedBox(height: 32),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRouteInfoSection() {
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
            TextFormField(
              controller: _vesselsController,
              decoration: const InputDecoration(
                labelText: 'Número de Embarcaciones',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_boat),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de embarcaciones';
                }
                final vessels = int.tryParse(value);
                if (vessels == null || vessels <= 0) {
                  return 'Ingrese un número válido de embarcaciones';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selección de Puertos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPortDropdown(
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
            const SizedBox(height: 16),
            _buildPortDropdown(
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
          ],
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
          child: Text('${port.name} (${port.continent})'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Por favor seleccione un puerto';
        }
        return null;
      },
    );
  }

  Widget _buildIntermediatePortsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Puertos Intermedios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addIntermediatePort,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_intermediatePorts.isEmpty)
              const Text(
                'No hay puertos intermedios seleccionados',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._intermediatePorts.asMap().entries.map((entry) {
                final index = entry.key;
                final port = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.anchor),
                    title: Text(port.name),
                    subtitle: Text(port.continent),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeIntermediatePort(index),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartureDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fecha de Salida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
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
                    const SizedBox(width: 12),
                    Text(
                      '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCreateButton() {
  return SizedBox(
    width: double.infinity,
    child: LoadingButton(
      onPressed: _createRoute,
      isLoading: _isLoading,
      text: 'Crear Ruta y Ver Animación',
      icon: Icons.map, // opcional
    ),
  );
}


  void _updateRouteName() {
    if (_originPort != null && _destinationPort != null) {
      _routeNameController.text = '${_originPort!.name} a ${_destinationPort!.name}';
    }
  }

  void _addIntermediatePort() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Puerto Intermedio'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allPorts.length,
              itemBuilder: (context, index) {
                final port = _allPorts[index];
                final isAlreadySelected = _intermediatePorts.contains(port) ||
                    port == _originPort ||
                    port == _destinationPort;

                return ListTile(
                  title: Text(port.name),
                  subtitle: Text(port.continent),
                  enabled: !isAlreadySelected,
                  onTap: isAlreadySelected
                      ? null
                      : () {
                          setState(() {
                            _intermediatePorts.add(port);
                          });
                          Navigator.of(context).pop();
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _removeIntermediatePort(int index) {
    setState(() {
      _intermediatePorts.removeAt(index);
    });
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
        _intermediatePorts.map((p) => p.name).toList(),
      );

    // Construir la polyline para la animación a partir de las coordenadas devueltas
      final List<LatLng> polyline = routeData.coordinates
          .map((c) => LatLng(c.latitude, c.longitude))
          .toList();

      // Validar que existan al menos dos puntos para animar
      if (polyline.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La ruta calculada no tiene suficientes puntos para animar.')),
        );
        return;
      }

      // Navegar a la pantalla de animación con los puntos calculados
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RouteAnimationScreen(
            polyline: polyline,
            // intenta completar la ruta en ~20s ajustando velocidad inicial
            desiredDurationSeconds: 20,
            routeInfo: routeData,
            portNames: routeData.portNames,
            totalNauticalMiles: routeData.totalDistance,
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
