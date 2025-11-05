import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/route_model.dart';

class RouteAnimationScreen extends StatefulWidget {
  /// Puntos de la ruta (inicio -> fin)
  final List<LatLng> polyline;

  /// Velocidad inicial en nudos (1 kn ≈ 0.514444 m/s)
  final double initialKnots;

  /// Si true, la cámara sigue al barco
  final bool followBoat;

  /// Duración deseada para completar la ruta (en segundos). Si la ruta es muy larga,
  /// se ajustará la velocidad inicial para intentar cumplir esta duración.
  final double desiredDurationSeconds;

  /// Información opcional de la ruta devuelta por el API (para mostrar card de info)
  final RouteCalculationResource? routeInfo;
  /// Si no se pasa routeInfo, puedes pasar solo los nombres
  final List<String>? portNames;
  /// Distancia total (en millas náuticas) si no viene en routeInfo
  final double? totalNauticalMiles;

  const RouteAnimationScreen({
    Key? key,
    required this.polyline,
    this.initialKnots = 20,
    this.followBoat = true,
    this.desiredDurationSeconds = 20,
    this.routeInfo,
    this.portNames,
    this.totalNauticalMiles,
  }) : super(key: key);

  static RouteAnimationScreen fromArgs(Object? args) {
    if (args is List<LatLng>) return RouteAnimationScreen(polyline: args);
    if (args is Map && args['polyline'] is List<LatLng>) {
      return RouteAnimationScreen(polyline: (args['polyline'] as List<LatLng>));
    }
    return const RouteAnimationScreen(polyline: []);
  }

  @override
  State<RouteAnimationScreen> createState() => _RouteAnimationScreenState();
}

class _RouteAnimationScreenState extends State<RouteAnimationScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _dist = const Distance();

  // animación
  late AnimationController _ctrl;
  double _mps = 0; // metros/seg
  double _baseMps = 0; // para mostrar factor x
  double _totalMeters = 0;
  List<double> _segLen = [];      // longitudes de cada segmento (m)
  List<double> _cumMeters = [];   // acumulados por vértice (m)
  int _currentSegIdx = 0;         // índice de segmento actual

  // estado del barco
  LatLng? _boatPos;

  bool get _hasRoute => widget.polyline.length >= 2;

  @override
  void initState() {
    super.initState();
    _mps = widget.initialKnots * 0.514444;

    _ctrl = AnimationController(
      vsync: this,
      value: 0.0, // 0..1 a lo largo de la ruta
    )..addListener(_onTick);

    if (_hasRoute) {
      _precompute();
      // Acelera para completar en el tiempo deseado si es necesario
      final desired = widget.desiredDurationSeconds <= 0 ? 20.0 : widget.desiredDurationSeconds;
      final recommended = desired > 0 ? _totalMeters / desired : 0.0; // m/s
      if (recommended.isFinite && recommended > 0 && recommended > _mps) {
        _mps = recommended;
      }
      _baseMps = _mps;
      _boatPos = widget.polyline.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
        // Auto-start suave tras encuadrar la ruta
        Future.delayed(const Duration(milliseconds: 300), _start);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _precompute() {
    _segLen.clear();
    _cumMeters = [0.0];
    _totalMeters = 0;

    for (var i = 0; i < widget.polyline.length - 1; i++) {
      final d = _dist.distance(widget.polyline[i], widget.polyline[i + 1]); // m
      _segLen.add(d);
      _totalMeters += d;
      _cumMeters.add(_totalMeters);
    }
  }

  void _fitBounds() {
    double minLat =  90, minLng =  180;
    double maxLat = -90, maxLng = -180;
    for (final p in widget.polyline) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  // ---- control de animación

  void _onTick() {
    if (!_hasRoute) return;

    final t = _ctrl.value.clamp(0.0, 1.0);
    final traveled = t * _totalMeters;

    // localiza el segmento donde cae "traveled"
    int i = 0;
    while (i < _segLen.length && _cumMeters[i + 1] < traveled) {
      i++;
    }
    _currentSegIdx = i; // para el card de información
    if (i >= _segLen.length) {
      _boatPos = widget.polyline.last;
    } else {
      final a = widget.polyline[i];
      final b = widget.polyline[i + 1];
      final segStart = _cumMeters[i];
      final segLen = _segLen[i] == 0 ? 1.0 : _segLen[i];
      final localT = ((traveled - segStart) / segLen).clamp(0.0, 1.0);
      _boatPos = LatLng(
        a.latitude + (b.latitude - a.latitude) * localT,
        a.longitude + (b.longitude - a.longitude) * localT,
      );
    }

    if (widget.followBoat && _boatPos != null) {
      _mapController.move(_boatPos!, _mapController.camera.zoom);
    }

    if (mounted) setState(() {}); // repinta
  }

  void _start() {
    if (!_hasRoute || _totalMeters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La animación necesita al menos dos puntos.')),
      );
      return;
    }

    // ajusta duración según velocidad actual y progreso actual
    final remainingMeters = (1.0 - _ctrl.value) * _totalMeters;
    final seconds = remainingMeters / (_mps <= 0 ? 0.1 : _mps);
    _ctrl.animateTo(
      1.0,
      duration: Duration(milliseconds: (seconds * 1000).round()),
      curve: Curves.linear,
    );
  }

  void _pause() {
    _ctrl.stop();
  }

  void _reset() {
    _ctrl.stop();
    _ctrl.value = 0.0;
    _boatPos = _hasRoute ? widget.polyline.first : null;
    setState(() {});
    if (widget.followBoat && _boatPos != null) {
      _mapController.move(_boatPos!, _mapController.camera.zoom);
    }
  }

  void _changeSpeed(double newMps) {
    // si está corriendo, re-calcula duración restante con la nueva velocidad
    final wasAnimating = _ctrl.isAnimating;
    _ctrl.stop();
    _mps = newMps;

    if (wasAnimating) {
      _start();
    } else {
      setState(() {}); // solo repinta el texto de velocidad
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = _hasRoute;
    final info = widget.routeInfo;
    final names = info?.portNames.isNotEmpty == true
        ? info!.portNames
        : (widget.portNames ?? const <String>[]);
    final totalNm = info?.totalDistance ?? widget.totalNauticalMiles;
    final origin = names.isNotEmpty ? names.first : null;
    final destination = names.length > 1 ? names.last : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Animación de Ruta')),
      body: Column(
        children: [
          if (hasRoute)
            _HeaderCard(
              origin: origin,
              destination: destination,
              totalNm: totalNm,
            ),
          if (hasRoute)
            _InfoCard(
              totalNm: totalNm,
              portNames: names,
              currentIndex: _currentSegIdx,
              landActive: info?.landDetectionActive,
              landCount: info?.landFeaturesCount,
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: hasRoute ? widget.polyline.first : const LatLng(0, 0),
                initialZoom: hasRoute ? 6 : 3,
              ),
              children: [
                // usa el mismo tile server que funcionó en la otra pantalla
                TileLayer(
                  // OSM estándar sin subdominios (recomendado por operaciones OSM)
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Debe coincidir con el applicationId/bundleId real
                  userAgentPackageName: 'pe.edu.upc.mushroom',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(
                    // Evitar const para permitir que el provider combine headers
                    headers: {
                      'User-Agent': 'pe.edu.upc.mushroom/1.0 (+https://upc.edu.pe)',
                    },
                  ),
                ),
                if (hasRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.polyline,
                        strokeWidth: 4,
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                if (_boatPos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _boatPos!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        // En flutter_map 6.x evitamos rotación por compatibilidad
                        rotate: false,
                        child: const Icon(
                          Icons.directions_boat,
                          size: 28,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _Controls(
            mps: _mps,
            baseMps: _baseMps,
            isRunning: _ctrl.isAnimating,
            onSpeedChanged: _changeSpeed,
            onStart: _start,
            onPause: _pause,
            onReset: _reset,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final double? totalNm;
  final List<String> portNames;
  final int currentIndex;
  final bool? landActive;
  final int? landCount;

  const _InfoCard({
    required this.totalNm,
    required this.portNames,
    required this.currentIndex,
    this.landActive,
    this.landCount,
  });

  String _formatNm(double v) {
    // formato simple con separador de miles
    final s = v.toStringAsFixed(0);
    final reg = RegExp(r"(\d)(?=(\d{3})+(?!\d))");
    return s.replaceAllMapped(reg, (m) => "${m[1]},");
  }

  @override
  Widget build(BuildContext context) {
    final totalPorts = portNames.isNotEmpty ? portNames.length : null;
    final current = (portNames.isNotEmpty && currentIndex < portNames.length)
        ? portNames[currentIndex]
        : null;
    final next = (portNames.isNotEmpty && currentIndex + 1 < portNames.length)
        ? portNames[currentIndex + 1]
        : null;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _kv('Distancia Total:',
                totalNm != null ? '${_formatNm(totalNm!)} millas náuticas' : '—'),
            _kv('Puertos en la Ruta:', totalPorts?.toString() ?? '—'),
            _kv('Puerto Actual:', current ?? '—', strong: true),
            _kv('Próximo Puerto:', next ?? '—'),
            _kv('Detección de Tierra:',
                landActive == null
                    ? '—'
                    : (landActive! ? '✓ Activa${landCount != null ? ' (${_formatNm(landCount!.toDouble())} características)' : ''}'
                                   : 'Inactiva')),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool strong = false}) {
    final styleK = TextStyle(color: Colors.grey.shade600);
    final styleV = TextStyle(
      fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
    );
    return Row(
      children: [
        Text(k, style: styleK),
        const SizedBox(width: 6),
        Text(v, style: styleV),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String? origin;
  final String? destination;
  final double? totalNm;

  const _HeaderCard({
    this.origin,
    this.destination,
    this.totalNm,
  });

  String _formatNm(double v) {
    final s = v.toStringAsFixed(0);
    final reg = RegExp(r"(\d)(?=(\d{3})+(?!\d))");
    return s.replaceAllMapped(reg, (m) => "${m[1]},");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visualización de Ruta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _kv('Origen:', origin ?? '—', bold: true),
                _kv('Destino:', destination ?? '—', bold: true),
                _kv('Distancia Total:',
                    totalNm != null ? '${_formatNm(totalNm!)} millas náuticas' : '—'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    final styleK = TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600);
    final styleV = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(k, style: styleK),
        const SizedBox(width: 6),
        Text(v, style: styleV),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final double mps;
  final double baseMps;
  final bool isRunning;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _Controls({
    required this.mps,
    required this.baseMps,
    required this.isRunning,
    required this.onSpeedChanged,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.speed),
              const SizedBox(width: 10),
              Text('Velocidad:', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: mps,
                  min: baseMps * 0.2, // 0.2x
                  max: math.max(baseMps * 6, mps * 1.5), // hasta 6x o más
                  onChanged: onSpeedChanged,
                ),
              ),
              Text("${(mps / (baseMps == 0 ? 1 : baseMps)).toStringAsFixed(1)}x"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: isRunning ? null : onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Animación'),
              ),
              ElevatedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.replay),
                label: const Text('Reiniciar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
