Land mask (optional)

Place a simplified land polygons GeoJSON here to enable client-side land avoidance for curved routes.

Recommended source: Natural Earth "land" at 1:110m scale (very small and fast).
- File name suggestion: land_110m.geojson or ne_110m_land.geojson
- Geometry types supported: Polygon or MultiPolygon (WGS84 lon/lat order)

How to enable:
1) Download and place the GeoJSON file in this folder.
2) Add the asset entry in pubspec.yaml under flutter/assets, for example:

flutter:
  assets:
    - assets/geo/land_110m.geojson

3) Rebuild the app. If the asset is found, the app will:
   - Try both sides of the Bezier curve, and increase curvature if needed.
   - Fall back to great-circle if both still cross land.

Notes:
- If the asset is missing or not declared, the app behaves as before (no land check).
- Keep the file small (e.g., Natural Earth 110m). Very detailed coastlines can be heavy on memory/CPU.
