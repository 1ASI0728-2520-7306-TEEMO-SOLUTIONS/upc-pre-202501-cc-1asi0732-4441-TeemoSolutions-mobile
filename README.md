# mushroom

Aplicación Flutter

## Ruta marítima: máscara de tierra (opcional)

Para que las curvas de las rutas eviten pasar por tierra sin depender del backend, puedes activar una "máscara de tierra" local:

1) Coloca un GeoJSON de polígonos de tierra simplificado (por ejemplo, Natural Earth 110m "land") dentro de `assets/geo/`.
	- Nombre sugerido: `land_110m.geojson` o `ne_110m_land.geojson`.
	- Formatos soportados: `Polygon` o `MultiPolygon` (WGS84 lon/lat).
2) Declara el asset en `pubspec.yaml`:

```
flutter:
  assets:
	 - assets/geo/land_110m.geojson
```

3) Ejecuta la app. Si el asset está disponible, el trazado:
	- Probará ambos lados de la curva y aumentará la curvatura si es necesario para evitar tierra.
	- Hará fallback a gran círculo si aún cruza tierra.

Si no agregas el asset, la app seguirá funcionando como siempre (sin comprobación de tierra).
