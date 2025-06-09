import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../data/models/port_model.dart';
import '../../../data/models/route_model.dart';
import 'dart:math';

class RouteAnimationScreen extends StatefulWidget {
  final String routeName;
  final Port originPort;
  final Port destinationPort;
  final List<Port> intermediatePorts;
  final RouteCalculationResource routeData;
  final DateTime departureDate;
  final int vessels;

  const RouteAnimationScreen({
    Key? key,
    required this.routeName,
    required this.originPort,
    required this.destinationPort,
    required this.intermediatePorts,
    required this.routeData,
    required this.departureDate,
    required this.vessels,
  }) : super(key: key);

  @override
  State<RouteAnimationScreen> createState() => _RouteAnimationScreenState();
}

class _RouteAnimationScreenState extends State<RouteAnimationScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<LatLng> _routePoints = [];
  List<Port> _allRoutePorts = [];
  List<LatLng> _traveledPoints = [];
  LatLng? _currentShipPosition;

  bool _isAnimating = false;
  double _animationSpeed = 3.0;
  int _currentPortIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _processRouteData();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  void _processRouteData() {
    // Crear lista completa de puertos en la ruta
    _allRoutePorts = [
      widget.originPort,
      ...widget.intermediatePorts,
      widget.destinationPort,
    ];

    // Crear puntos de ruta suaves
    _createRoutePoints();

    // Establecer posición inicial del barco
    if (_routePoints.isNotEmpty) {
      _currentShipPosition = _routePoints.first;
    }

    setState(() {});

    // Ajustar el mapa para mostrar toda la ruta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToBounds();
    });
  }

  void _createRoutePoints() {
    _routePoints.clear();

    for (int i = 0; i < _allRoutePorts.length - 1; i++) {
      final currentPort = _allRoutePorts[i];
      final nextPort = _allRoutePorts[i + 1];

      // Añadir el puerto actual
      _routePoints.add(LatLng(
        currentPort.coordinates.latitude,
        currentPort.coordinates.longitude,
      ));

      // Añadir puntos intermedios para suavizar la ruta
      const steps = 20;
      for (int step = 1; step < steps; step++) {
        final ratio = step / steps;
        final lat = currentPort.coordinates.latitude +
            (nextPort.coordinates.latitude - currentPort.coordinates.latitude) *
                ratio;
        final lng = currentPort.coordinates.longitude +
            (nextPort.coordinates.longitude -
                    currentPort.coordinates.longitude) *
                ratio;
        _routePoints.add(LatLng(lat, lng));
      }
    }

    // Añadir el último puerto
    if (_allRoutePorts.isNotEmpty) {
      final lastPort = _allRoutePorts.last;
      _routePoints.add(LatLng(
        lastPort.coordinates.latitude,
        lastPort.coordinates.longitude,
      ));
    }
  }

  void _fitMapToBounds() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitBounds(bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(50)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildAnimationControls(),
          _buildRouteInfo(),
          Expanded(child: _buildMap()),
          _buildPortsList(),
        ],
      ),
    );
  }

  Widget _buildAnimationControls() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _routePoints.isEmpty ? null : _toggleAnimation,
                  icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
                  label: Text(_isAnimating ? 'Pausar' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isAnimating ? Colors.red : const Color(0xFF0A6CBC),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _routePoints.isEmpty ? null : _resetAnimation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Velocidad: '),
                Expanded(
                  child: Slider(
                    value: _animationSpeed,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${_animationSpeed.toInt()}x',
                    onChanged: (value) {
                      setState(() {
                        _animationSpeed = value;
                      });
                      if (_isAnimating) {
                        _stopAnimation();
                        _startAnimation();
                      }
                    },
                  ),
                ),
                Text('${_animationSpeed.toInt()}x'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Ruta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Distancia Total',
                    '${widget.routeData.totalDistance.toStringAsFixed(0)} mn'),
                _buildInfoItem('Puertos', '${_allRoutePorts.length}'),
              ],
            ),
            if (_currentPortIndex < _allRoutePorts.length) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                      'Puerto Actual', _allRoutePorts[_currentPortIndex].name),
                  if (_currentPortIndex < _allRoutePorts.length - 1)
                    _buildInfoItem('Próximo Puerto',
                        _allRoutePorts[_currentPortIndex + 1].name),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center:
                _routePoints.isNotEmpty ? _routePoints.first : LatLng(20, 0),
            zoom: 2,
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mushroom_mobile',
            ),
            // Ruta completa (gris)
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 3,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ],
              ),
            // Ruta recorrida (azul)
            if (_traveledPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _traveledPoints,
                    strokeWidth: 4,
                    color: const Color(0xFF0A6CBC),
                  ),
                ],
              ),
            // Marcadores de puertos
            MarkerLayer(
              markers: _allRoutePorts.asMap().entries.map((entry) {
                final index = entry.key;
                final port = entry.value;

                Color color;
                double size;

                if (index == 0) {
                  color = Colors.green;
                  size = 30;
                } else if (index == _allRoutePorts.length - 1) {
                  color = Colors.red;
                  size = 30;
                } else {
                  color = Colors.purple;
                  size = 25;
                }

                return Marker(
                  point: LatLng(port.latitude, port.longitude),
                  width: size,
                  height: size,
                  child: GestureDetector(
                    onTap: () => _showPortInfo(port, index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
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
                        size: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Marcador del barco
            if (_currentShipPosition != null)
              MarkerLayer(
                markers: _allRoutePorts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final port = entry.value;

                  Color color;
                  double size;

                  if (index == 0) {
                    color = Colors.green;
                    size = 30;
                  } else if (index == _allRoutePorts.length - 1) {
                    color = Colors.red;
                    size = 30;
                  } else {
                    color = Colors.purple;
                    size = 25;
                  }

                  return Marker(
                    point: LatLng(port.latitude, port.longitude),
                    width: size,
                    height: size,
                    child: GestureDetector(
                      // <-- CAMBIO: 'builder' por 'child'
                      onTap: () => _showPortInfo(port, index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
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
                          size: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortsList() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Puertos en la Ruta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _allRoutePorts.length,
              itemBuilder: (context, index) {
                final port = _allRoutePorts[index];
                final isVisited = index < _currentPortIndex;
                final isCurrent = index == _currentPortIndex;
                final isPending = index > _currentPortIndex;

                Color cardColor;
                Color textColor;
                IconData statusIcon;

                if (isVisited) {
                  cardColor = Colors.green.withOpacity(0.1);
                  textColor = Colors.green;
                  statusIcon = Icons.check_circle;
                } else if (isCurrent) {
                  cardColor = const Color(0xFF0A6CBC).withOpacity(0.1);
                  textColor = const Color(0xFF0A6CBC);
                  statusIcon = Icons.access_time;
                } else {
                  cardColor = Colors.grey.withOpacity(0.1);
                  textColor = Colors.grey;
                  statusIcon = Icons.radio_button_unchecked;
                }

                return Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card(
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: textColor,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(statusIcon, color: textColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            port.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${port.coordinates.latitude.toStringAsFixed(2)}°, ${port.coordinates.longitude.toStringAsFixed(2)}°',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPortInfo(Port port, int index) {
    String portType;
    if (index == 0) {
      portType = 'Origen';
    } else if (index == _allRoutePorts.length - 1) {
      portType = 'Destino';
    } else {
      portType = 'Puerto Intermedio';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(port.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $portType'),
            const SizedBox(height: 8),
            Text('Continente: ${port.continent}'),
            const SizedBox(height: 8),
            Text(
                'Coordenadas: ${port.coordinates.latitude.toStringAsFixed(4)}, ${port.coordinates.longitude.toStringAsFixed(4)}'),
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

  void _toggleAnimation() {
    if (_isAnimating) {
      _stopAnimation();
    } else {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_routePoints.isEmpty) return;

    setState(() {
      _isAnimating = true;
    });

    _animationTimer = Timer.periodic(
      Duration(milliseconds: (100 / _animationSpeed).round()),
      (timer) => _animateStep(),
    );
  }

  void _stopAnimation() {
    setState(() {
      _isAnimating = false;
    });

    _animationTimer?.cancel();
    _animationTimer = null;
  }

  void _animateStep() {
    if (_traveledPoints.length >= _routePoints.length - 1) {
      _stopAnimation();
      return;
    }

    setState(() {
      final nextIndex = _traveledPoints.length;
      _traveledPoints.add(_routePoints[nextIndex]);
      _currentShipPosition = _routePoints[nextIndex];

      // Actualizar puerto actual
      _updateCurrentPort();
    });
  }

  void _updateCurrentPort() {
    if (_currentShipPosition == null || _allRoutePorts.isEmpty) return;

    double minDistance = double.infinity;
    int closestPortIndex = 0;

    for (int i = 0; i < _allRoutePorts.length; i++) {
      final port = _allRoutePorts[i];
      final portLatLng =
          LatLng(port.coordinates.latitude, port.coordinates.longitude);
      final distance = _calculateDistance(_currentShipPosition!, portLatLng);

      if (distance < minDistance) {
        minDistance = distance;
        closestPortIndex = i;
      }
    }

    if (closestPortIndex != _currentPortIndex) {
      setState(() {
        _currentPortIndex = closestPortIndex;
      });
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros
    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (3.14159 / 180);

    final a = pow(sin(deltaLatRad / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLngRad / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void _resetAnimation() {
    _stopAnimation();
    setState(() {
      _traveledPoints.clear();
      _currentShipPosition =
          _routePoints.isNotEmpty ? _routePoints.first : null;
      _currentPortIndex = 0;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }
}
