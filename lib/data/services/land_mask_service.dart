import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart' as ll;

/// Servicio opcional para verificar si un punto cae sobre tierra usando
/// una máscara GeoJSON muy simplificada (p. ej. Natural Earth 110m "land").
///
/// Notas importantes:
/// - No es obligatorio. Si el asset no existe, `isReady` será false y
///   `isLand` devolverá false (no bloquea curvas).
/// - Para activarlo, coloque un archivo como:
///   assets/geo/land_110m.geojson (o ne_110m_land.geojson)
///   y declare el asset en `pubspec.yaml`.
class LandMaskService {
  LandMaskService._();
  static final LandMaskService instance = LandMaskService._();

  bool isReady = false;
  final List<_Polygon> _polys = [];

  Future<void> ensureLoaded() async {
    if (isReady) return;
    final candidates = <String>[
      'assets/geo/land_110m.geojson',
      'assets/geo/ne_110m_land.geojson',
      // También soportar extensión .json como en tu proyecto actual
      'assets/geo/ne_110m_land.json',
      'assets/geo/land.geojson',
    ];
    for (final path in candidates) {
      try {
        final text = await rootBundle.loadString(path);
        _parseGeoJson(text);
        isReady = _polys.isNotEmpty;
        if (isReady) return; // cargado
      } catch (_) {
        // ignorar y probar siguiente
      }
    }
  }

  bool isLand(ll.LatLng p) {
    if (!isReady) return false;
    for (final poly in _polys) {
      if (poly.contains(p)) return true;
    }
    return false;
  }

  void _parseGeoJson(String text) {
    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      return;
    }

    if (data is Map<String, dynamic>) {
      final type = data['type'] as String?;
      if (type == 'FeatureCollection') {
        final features = data['features'] as List? ?? const [];
        for (final f in features) {
          final geom = (f as Map)['geometry'];
          _parseGeometry(geom);
        }
      } else if (type == 'Feature') {
        _parseGeometry(data['geometry']);
      } else {
        _parseGeometry(data);
      }
    }
  }

  void _parseGeometry(dynamic geom) {
    if (geom == null) return;
    final gtype = (geom['type'] as String?) ?? '';
    final coords = geom['coordinates'];
    if (gtype == 'Polygon') {
      final rings = _coordsToRings(coords);
      if (rings.isNotEmpty) _polys.add(_Polygon(rings));
    } else if (gtype == 'MultiPolygon') {
      if (coords is List) {
        for (final poly in coords) {
          final rings = _coordsToRings(poly);
          if (rings.isNotEmpty) _polys.add(_Polygon(rings));
        }
      }
    }
  }

  List<List<ll.LatLng>> _coordsToRings(dynamic coords) {
    final rings = <List<ll.LatLng>>[];
    if (coords is List) {
      for (final ring in coords) {
        if (ring is List) {
          final pts = <ll.LatLng>[];
          for (final p in ring) {
            if (p is List && p.length >= 2) {
              final lng = (p[0] as num).toDouble();
              final lat = (p[1] as num).toDouble();
              pts.add(ll.LatLng(lat, lng));
            }
          }
          if (pts.isNotEmpty) rings.add(pts);
        }
      }
    }
    return rings;
  }
}

class _Polygon {
  _Polygon(this.rings) {
    // bbox
    double minLat = 90, minLng = 180, maxLat = -90, maxLng = -180;
    for (final r in rings) {
      for (final p in r) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }
    _minLat = minLat; _maxLat = maxLat; _minLng = minLng; _maxLng = maxLng;
  }

  final List<List<ll.LatLng>> rings; // [outer, hole1, hole2, ...]
  late final double _minLat, _maxLat, _minLng, _maxLng;

  bool contains(ll.LatLng p) {
    if (p.latitude < _minLat || p.latitude > _maxLat || p.longitude < _minLng || p.longitude > _maxLng) {
      return false;
    }
    if (rings.isEmpty) return false;

    // El primer anillo es el exterior, los siguientes son huecos.
    final insideOuter = _pointInRing(rings.first, p);
    if (!insideOuter) return false;
    for (int i = 1; i < rings.length; i++) {
      if (_pointInRing(rings[i], p)) return false; // cae en un hueco
    }
    return true;
  }

  // Ray casting clásico (lon,lat)
  bool _pointInRing(List<ll.LatLng> ring, ll.LatLng p) {
    bool inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude, yi = ring[i].latitude;
      final xj = ring[j].longitude, yj = ring[j].latitude;

      final intersect = ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude < (xj - xi) * (p.latitude - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
