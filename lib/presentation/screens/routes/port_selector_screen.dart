import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/models/port_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/services/port_service.dart';
import '../../../data/services/route_service.dart';
import 'incoterm_calculator_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../data/services/land_mask_service.dart';
import '../../../data/services/weather_ai_service.dart';
import '../../../data/models/weather_delay_model.dart';

// --- Great-circle helpers to render curved routes ---
double _degToRad(double d) => d * math.pi / 180.0;
double _radToDeg(double r) => r * 180.0 / math.pi;

/// Returns a polyline approximating the great-circle segment between two points.
List<ll.LatLng> _greatCircleSegment(ll.LatLng a, ll.LatLng b, int steps) {
  final phi1 = _degToRad(a.latitude);
  final lambda1 = _degToRad(a.longitude);
  final phi2 = _degToRad(b.latitude);
  final lambda2 = _degToRad(b.longitude);

  final delta = math.acos(
    (math.sin(phi1) * math.sin(phi2)) +
        (math.cos(phi1) * math.cos(phi2) * math.cos(lambda2 - lambda1)),
  );

  if (delta.isNaN || delta == 0) {
    return [a, b];
  }

  final sinDelta = math.sin(delta);
  final result = <ll.LatLng>[];

  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final A = math.sin((1 - t) * delta) / sinDelta;
    final B = math.sin(t * delta) / sinDelta;

    final x = A * math.cos(phi1) * math.cos(lambda1) + B * math.cos(phi2) * math.cos(lambda2);
    final y = A * math.cos(phi1) * math.sin(lambda1) + B * math.cos(phi2) * math.sin(lambda2);
    final z = A * math.sin(phi1) + B * math.sin(phi2);

    final phi = math.atan2(z, math.sqrt(x * x + y * y));
    final lambda = math.atan2(y, x);
    result.add(ll.LatLng(_radToDeg(phi), _radToDeg(lambda)));
  }

  return result;
}

/// Densifies the route by replacing each straight segment with a great-circle arc.
List<ll.LatLng> _buildGreatCirclePath(List<ll.LatLng> waypoints) {
  if (waypoints.length < 2) return waypoints;
  final res = <ll.LatLng>[];
  final d = ll.Distance();

  for (int i = 0; i < waypoints.length - 1; i++) {
    final a = waypoints[i];
    final b = waypoints[i + 1];
    final km = d.as(ll.LengthUnit.Kilometer, a, b);
    int steps = (km / 200).ceil(); // ~1 vertex cada 200 km
    if (steps < 8) steps = 8;
    if (steps > 128) steps = 128;

    final seg = _greatCircleSegment(a, b, steps);
    if (i > 0 && seg.isNotEmpty) seg.removeAt(0); // evitar duplicar vértices
    res.addAll(seg);
  }

  return res;
}

// --- Bezier-based aesthetic curve (more pronounced visually) ---
/// Builds a visually curved path between waypoints using quadratic Bezier segments.
/// Useful for short east-asian routes where great-circle looks almost straight.
List<ll.LatLng> _buildCurvedPath(List<ll.LatLng> waypoints, {double curvatureFactor = 0.25}) {
  if (waypoints.length < 2) return waypoints;
  final curved = <ll.LatLng>[];
  for (int i = 0; i < waypoints.length - 1; i++) {
    final a = waypoints[i];
    final b = waypoints[i + 1];

    // Midpoint
    final midLat = (a.latitude + b.latitude) / 2.0;
    final midLng = (a.longitude + b.longitude) / 2.0;

    // Direction vector (planar approximation)
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) continue;

    // Normal vector for perpendicular offset
    double nx = -dy / dist;
    double ny = dx / dist;

    // Always bend "northward" for predominantly east-west segments (dy small) else bend eastward.
    // Adjust sign so curve is consistent visually.
    if (dx.abs() > dy.abs()) {
      // East-West: push latitude positive
      if (ny < 0) { nx = -nx; ny = -ny; }
    } else {
      // North-South: push longitude positive
      if (nx < 0) { nx = -nx; ny = -ny; }
    }

    final offsetScale = dist * curvatureFactor; // scale by segment length
    final ctrlLat = midLat + ny * offsetScale; // note ny corresponds to latitude change
    final ctrlLng = midLng + nx * offsetScale; // nx corresponds to longitude change
    final control = ll.LatLng(ctrlLat, ctrlLng);

    // Sample quadratic Bezier
    const samples = 30;
    for (int s = 0; s <= samples; s++) {
      final t = s / samples;
      final lat = (1 - t) * (1 - t) * a.latitude + 2 * (1 - t) * t * control.latitude + t * t * b.latitude;
      final lng = (1 - t) * (1 - t) * a.longitude + 2 * (1 - t) * t * control.longitude + t * t * b.longitude;
      if (i > 0 && s == 0) continue; // avoid duplicating the start point of subsequent segments
      curved.add(ll.LatLng(lat, lng));
    }
  }
  return curved;
}

/// Genera curvas por tramo usando una normal global para que el arco sea consistente
/// entre segmentos, similar al comportamiento de la versión web. Usa la máscara de
/// tierra si está disponible para evitar cruces sobre tierra.
List<ll.LatLng> _maybeCurve(List<ll.LatLng> pts) {
  if (pts.length < 2) return pts;
  final factor = _curvatureForDistance(pts.first, pts.last);
  return _buildCurvedPathAvoidingLand(pts, curvatureFactor: factor);
}

// Calcula un factor de curvatura adaptativo en función de la distancia media
// de los segmentos, para que las rutas cortas no se vean demasiado rectas.
double _curvatureForPath(List<ll.LatLng> pts) {
  if (pts.length < 2) return 0.33;
  final d = ll.Distance();
  double totalKm = 0;
  for (int i = 0; i < pts.length - 1; i++) {
    totalKm += d.as(ll.LengthUnit.Kilometer, pts[i], pts[i + 1]);
  }
  final avgKm = totalKm / (pts.length - 1);
  if (avgKm < 800) return 0.38;      // tramos cortos: más arco
  if (avgKm < 2000) return 0.34;     // tramos medios
  return 0.30;                       // tramos largos: algo más sutil
}

// Factor de curvatura basado en la distancia directa origen→destino.
double _curvatureForDistance(ll.LatLng a, ll.LatLng b) {
  final d = ll.Distance();
  final km = d.as(ll.LengthUnit.Kilometer, a, b);
  if (km < 800) return 0.40;     // rutas cortas, arco visible
  if (km < 2000) return 0.36;    // media distancia
  if (km < 6000) return 0.32;    // larga distancia
  return 0.30;                    // muy larga distancia, más sutil
}


class PortSelectorScreen extends StatefulWidget {
  const PortSelectorScreen({Key? key}) : super(key: key);


  @override
  State<PortSelectorScreen> createState() => _PortSelectorScreenState();
}

class _PortSelectorScreenState extends State<PortSelectorScreen> {
  final PortService _portService = PortService();
  final RouteService _routeService = RouteService();
  final WeatherAiService _aiService = WeatherAiService();
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

  // Estado del panel IA · Ruta
  bool _aiLoading = false;
  WeatherDelayResult? _aiResult;
  DateTime? _aiUpdatedAt;
  bool _aiCollapsed = false; // permite colapsar/expandir la card IA
  // Inputs de parámetros (restaurados)
  final TextEditingController _speedController = TextEditingController(text: '16');
  final TextEditingController _windController = TextEditingController(text: '12');
  final TextEditingController _waveController = TextEditingController(text: '2');



  @override
  void initState() {
    super.initState();
    _loadPorts();
    LandMaskService.instance.ensureLoaded();
  }

  List<ll.LatLng> _buildLatLngRoute(dynamic data) {
    // Preferir un path detallado si el backend lo provee (evita tierra)
    try {
      final sea = (data.seaPath as List<PortCoordinates>?) ?? const <PortCoordinates>[];
      if (sea.isNotEmpty) {
        return sea.map((c) => ll.LatLng(c.latitude, c.longitude)).toList();
      }
    } catch (_) {}

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

      // Dispara cálculo IA al visualizar ruta
      _fetchAiDelay();
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

  Future<void> _fetchAiDelay() async {
    if (_routeData == null || _selectedOriginPort == null || _selectedDestinationPort == null) {
      return;
    }
    try {
      setState(() {
        _aiLoading = true;
      });

      final nm = (_routeData!.totalDistance) as num? ?? 0;
      final distanceKm = nm.toDouble() * 1.852; // nm -> km
      // Tomar valores ingresados para mejorar precisión de ETA y riesgo
      final cruise = double.tryParse(_speedController.text.trim()) ?? 0;
      final wind = double.tryParse(_windController.text.trim()) ?? 0;
      final wave = double.tryParse(_waveController.text.trim()) ?? 0;
      final req = WeatherDelayRequest(
        distanceKm: distanceKm,
        cruiseSpeedKnots: cruise,
        avgWindKnots: wind,
        maxWaveM: wave,
        departureTimeIso: DateTime.now().toUtc().toIso8601String(),
        originLat: _selectedOriginPort!.latitude,
        originLon: _selectedOriginPort!.longitude,
        destLat: _selectedDestinationPort!.latitude,
        destLon: _selectedDestinationPort!.longitude,
      );

      final res = await _aiService.predictWeatherDelay(req);
      setState(() {
        _aiResult = res;
        _aiUpdatedAt = DateTime.now();
        _aiLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IA · Ruta: error al obtener predicción: $e')),
      );
    }
  }

  Widget _buildAiPanel() {
    final res = _aiResult;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0A6CBC), size: 18),
                const SizedBox(width: 8),
                const Text('IA · Ruta', style: TextStyle(fontWeight: FontWeight.bold)),
                if (res != null) ...[
                  const SizedBox(width: 8),
                  _buildRiskBadge(res),
                ],
                const Spacer(),
                IconButton(
                  onPressed: _aiLoading ? null : _fetchAiDelay,
                  tooltip: 'Actualizar',
                  icon: _aiLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 18),
                ),
                IconButton(
                  onPressed: () => setState(() => _aiCollapsed = !_aiCollapsed),
                  tooltip: _aiCollapsed ? 'Expandir' : 'Colapsar',
                  icon: Icon(_aiCollapsed ? Icons.expand_more : Icons.expand_less, size: 20),
                ),
              ],
            ),
            if (!_aiCollapsed) ...[
              if (_routeData != null) ...[
                const SizedBox(height: 4),
                _aiSummaryRow('Origen:', _selectedOriginPort?.name ?? '—'),
                _aiSummaryRow('Destino:', _selectedDestinationPort?.name ?? '—'),
                _aiSummaryRow('Distancia:', '${_routeData!.totalDistance.toStringAsFixed(0)} nm'),
                const Divider(height: 12),
              ],
              // Inputs ocultos para versión móvil: se usan internamente pero no se muestran.
              if (res == null && !_aiLoading) ...[
                const Text('Obtenga predicción de retraso por clima.'),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _fetchAiDelay,
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Calcular ahora'),
                  ),
                ),
              ] else if (_aiLoading) ...[
                const Text('Calculando predicción...'),
              ] else ...[
                _aiSummaryRow('Retraso estimado:', '${_aiResult!.delayHours.toStringAsFixed(1)} h'),
                _aiSummaryRow('Probabilidad:', _formatProbability(_aiResult!.delayProbability)),
                if (_aiResult!.riskLevel != null || _aiResult!.riskScore != null)
                  _aiSummaryRow('Riesgo:', _riskText(_aiResult!)),
                if (_aiResult!.mainDelayFactor?.isNotEmpty == true)
                  _aiSummaryRow('Causa principal:', _aiResult!.mainDelayFactor!),
                if (_aiResult!.plannedEtaIso != null)
                  _aiSummaryRow('ETA planificada:', _shortIso(_aiResult!.plannedEtaIso!)),
                if (_aiResult!.adjustedEtaIso != null)
                  _aiSummaryRow('ETA ajustada:', _shortIso(_aiResult!.adjustedEtaIso!)),
                if (_aiResult!.usedFallback == true)
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Expanded(child: Text('Se usaron valores por defecto')),
                    ],
                  ),
                if (_aiUpdatedAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Actualizado: ${_hhmm(_aiUpdatedAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniNumberField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildRiskBadge(WeatherDelayResult r) {
    final label = _riskLabel(r);
    Color bg;
    Color fg;
    switch (label) {
      case 'Alto': bg = Colors.red.shade50; fg = Colors.red.shade700; break;
      case 'Medio': bg = Colors.orange.shade50; fg = Colors.orange.shade700; break;
      default: bg = Colors.green.shade50; fg = Colors.green.shade700; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _riskLabel(WeatherDelayResult r) {
    if (r.riskLevel != null && r.riskLevel!.isNotEmpty) {
      final rl = r.riskLevel!.toLowerCase();
      if (rl.contains('high') || rl.contains('alto')) return 'Alto';
      if (rl.contains('med') || rl.contains('medio')) return 'Medio';
      return 'Bajo';
    }
    // Derivar por probabilidad si no viene
    final p = r.delayProbability <= 1 ? r.delayProbability : r.delayProbability / 100.0;
    if (p >= 0.6) return 'Alto';
    if (p >= 0.3) return 'Medio';
    return 'Bajo';
  }

  String _riskText(WeatherDelayResult r) {
    final label = _riskLabel(r);
    if (r.riskScore != null) {
      return '$label (${r.riskScore!.toStringAsFixed(2)})';
    }
    return label;
  }

  Widget _aiSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatProbability(double p) {
    double pct = p;
    if (pct <= 1.0) pct = pct * 100.0;
    return '${pct.toStringAsFixed(0)}%';
  }

  String _shortIso(String iso) {
    // Mostrar fecha corta y hora
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    } catch (_) {
      return iso;
    }
  }

  String _hhmm(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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

  final rawPoints = _buildLatLngRoute(_routeData!);
  final points = _maybeCurve(rawPoints);
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
                    // Resumen basado en datos reales del API
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildSummaryItem('Distancia Total:', '${_routeData!.totalDistance.toStringAsFixed(0)} millas náuticas'),
                        _buildSummaryItem('Puertos en la Ruta:',
                            (_routeData!.portNames.isNotEmpty
                                ? _routeData!.portNames.length
                                : (_routeData!.segments.isNotEmpty
                                    ? _routeData!.segments.length + 1
                                    : 0)).toString()),
                        _buildSummaryItem('Puerto Actual:',
                            (_routeData!.portNames.length >= 2)
                                ? _routeData!.portNames[1]
                                : (_routeData!.portNames.isNotEmpty
                                    ? _routeData!.portNames.last
                                    : '—')),
                        _buildSummaryItem('Próximo Puerto:',
                            (_routeData!.portNames.length >= 3)
                                ? _routeData!.portNames[2]
                                : (_routeData!.portNames.length >= 2
                                    ? _routeData!.portNames[1]
                                    : '—')),
                        _buildSummaryItem('Detección de Tierra:',
                            _routeData!.landDetectionActive == null
                                ? '—'
                                : (_routeData!.landDetectionActive!
                                    ? '✓ Activa${_routeData!.landFeaturesCount != null ? ' (${_routeData!.landFeaturesCount} características)' : ''}'
                                    : 'Inactiva')),
                      ],
                    ),

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
                    userAgentPackageName: 'pe.edu.upc.mushroom',
                    maxZoom: 19,
                    tileProvider: NetworkTileProvider(headers: {
                      'User-Agent': 'pe.edu.upc.mushroom/1.0 (+https://upc.edu.pe)',
                    }),
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
            // IA · Ruta como sección/card
            _buildAiPanel(),

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
    final bool hasSelection = _selectedOriginPort != null && _selectedDestinationPort != null;

    ButtonStyle _fullWidthOutlined() => OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );

    ButtonStyle _fullWidthFilled(Color color) => ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acciones',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Visualizar Ruta (secundario)
          ElevatedButton.icon(
            onPressed: hasSelection ? _visualizeRoute : null,
            style: _fullWidthFilled(Colors.grey.shade600),
            icon: _isCalculatingRoute
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.map),
            label: Text(_isCalculatingRoute ? 'Calculando...' : 'Visualizar Ruta'),
          ),
          const SizedBox(height: 10),

          // Crear Ruta (primario)
          ElevatedButton.icon(
            onPressed: hasSelection ? _createRoute : null,
            style: _fullWidthFilled(const Color(0xFF0A6CBC)),
            icon: const Icon(Icons.add),
            label: const Text('Crear Ruta'),
          ),
          const SizedBox(height: 10),

          // Calcular Incoterm (habilitado tras tener datos de ruta)
          ElevatedButton.icon(
            onPressed: _routeData != null ? _showIncotermCalculator : null,
            style: _fullWidthFilled(Colors.grey.shade600),
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular Incoterm'),
          ),
          const SizedBox(height: 10),

          // Cancelar (último)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: _fullWidthOutlined(),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _originSearchController.dispose();
    _destinationSearchController.dispose();
    _intermediateSearchController.dispose();
    _speedController.dispose();
    _windController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key, required this.points});
  final List<ll.LatLng> points;


  @override
  Widget build(BuildContext context) {
  final curved = _maybeCurve(points);
  final bounds = _bounds(curved);

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
              userAgentPackageName: 'pe.edu.upc.mushroom',
              maxZoom: 19,
              tileProvider: NetworkTileProvider(
                headers: {
                  'User-Agent': 'pe.edu.upc.mushroom/1.0 (+https://upc.edu.pe)',
                },
              ),
            ),
            // Polilínea de la ruta
            if (curved.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: curved, strokeWidth: 4),
                ],
              ),
            // Marcadores origen/destino
            MarkerLayer(markers: [
              if (curved.isNotEmpty)
                Marker(
                  point: curved.first,
                  width: 32, height: 32,
                  child: const Icon(Icons.place, size: 28),
                ),
              if (curved.length > 1)
                Marker(
                  point: curved.last,
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
  // Usar los puntos tal como llegan para evitar re-curvar y generar "onditas".
  final curved = widget.points;
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
                initialCenter: curved.isNotEmpty
                    ? curved.first
                    : const ll.LatLng(0, 0),
                initialZoom: 3.5,
                interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  // OSM estándar sin subdominios
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'pe.edu.upc.mushroom',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: curved, strokeWidth: 4),
                  ],
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    if (curved.isEmpty) return const SizedBox.shrink();
                    final progress = _animation.value;
                    final index = (progress * (curved.length - 1)).toInt();
                    final pos = curved[index.clamp(0, curved.length - 1)];
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

// --- Curvatura con "land mask" opcional ---
/// Construye una ruta curvada entre waypoints y, si existe una máscara de tierra
/// en assets, intenta elegir el lado de la curva y la intensidad para evitar cruces
/// sobre tierra. Si no hay máscara disponible, se comporta como una curva normal.
List<ll.LatLng> _buildCurvedPathAvoidingLand(List<ll.LatLng> waypoints, {double curvatureFactor = 0.33}) {
  if (waypoints.length < 2) return waypoints;
  final out = <ll.LatLng>[];
  final lm = LandMaskService.instance;

  // Normal global basada en el vector start->end para evitar zig-zag entre segmentos.
  final first = waypoints.first;
  final last = waypoints.last;
  final gdx = last.longitude - first.longitude;
  final gdy = last.latitude - first.latitude;
  final gdist = math.sqrt(gdx * gdx + gdy * gdy);
  double nxG = 0.0, nyG = 0.0;
  if (gdist > 0) {
    nxG = -gdy / gdist;
    nyG = gdx / gdist;
    if (gdx.abs() > gdy.abs()) {
      if (nyG < 0) { nxG = -nxG; nyG = -nyG; }
    } else {
      if (nxG < 0) { nxG = -nxG; nyG = -nyG; }
    }
  } else {
    // Fallback: si start==end, usar un normal arbitrario
    nxG = 0.0; nyG = 1.0;
  }

  List<ll.LatLng> buildBezier(
    ll.LatLng a,
    ll.LatLng b,
    double nx,
    double ny,
    double midLat,
    double midLng,
    double dist,
    double factor,
    int sign,
    int segIndex,
  ) {
    final offsetScale = dist * factor;
    final ctrlLat = midLat + (ny * sign) * offsetScale;
    final ctrlLng = midLng + (nx * sign) * offsetScale;
    final control = ll.LatLng(ctrlLat, ctrlLng);
  const samples = 64;
    final pts = <ll.LatLng>[];
    for (int s = 0; s <= samples; s++) {
      final t = s / samples;
      final lat = (1 - t) * (1 - t) * a.latitude + 2 * (1 - t) * t * control.latitude + t * t * b.latitude;
      final lng = (1 - t) * (1 - t) * a.longitude + 2 * (1 - t) * t * control.longitude + t * t * b.longitude;
      if (segIndex > 0 && s == 0) continue;
      pts.add(ll.LatLng(lat, lng));
    }
    return pts;
  }

  int landHits(List<ll.LatLng> pts, {int earlyStop = 9999}) {
    if (!lm.isReady) return 0;
    int hits = 0;
    for (final p in pts) {
      if (lm.isLand(p)) {
        hits++;
        if (hits >= earlyStop) break;
      }
    }
    return hits;
  }

  for (int i = 0; i < waypoints.length - 1; i++) {
    final a = waypoints[i];
    final b = waypoints[i + 1];

    final midLat = (a.latitude + b.latitude) / 2.0;
    final midLng = (a.longitude + b.longitude) / 2.0;
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) continue;

    // Usar la normal global para consistencia visual.
    var seg = buildBezier(a, b, nxG, nyG, midLat, midLng, dist, curvatureFactor, 1, i);
    var segHits = landHits(seg, earlyStop: 12);
    if (segHits > 0) {
      final alt = buildBezier(a, b, nxG, nyG, midLat, midLng, dist, curvatureFactor, -1, i);
      final altHits = landHits(alt, earlyStop: 12);
      if (altHits < segHits) { seg = alt; segHits = altHits; }

      if (segHits > 0) {
        final plus = buildBezier(a, b, nxG, nyG, midLat, midLng, dist, curvatureFactor * 1.5, 1, i);
        final minus = buildBezier(a, b, nxG, nyG, midLat, midLng, dist, curvatureFactor * 1.5, -1, i);
        final plusHits = landHits(plus, earlyStop: 12);
        final minusHits = landHits(minus, earlyStop: 12);
        var best = seg; var bestHits = segHits;
        if (plusHits < bestHits) { best = plus; bestHits = plusHits; }
        if (minusHits < bestHits) { best = minus; bestHits = minusHits; }

        // Aceptar si reduce claramente o si los cruces son muy pocos (tolerancia visual)
        if (bestHits < segHits || bestHits <= 2) {
          seg = best; segHits = bestHits;
        } else {
          // Fallback a gran círculo densificado
          final d = ll.Distance();
          int steps = (d.as(ll.LengthUnit.Kilometer, a, b) / 200).ceil();
          if (steps < 8) steps = 8;
          if (steps > 128) steps = 128;
          seg = _greatCircleSegment(a, b, steps);
          if (i > 0 && seg.isNotEmpty) seg.removeAt(0);
        }
      }
    }

    out.addAll(seg);
  }
  return out;
}
