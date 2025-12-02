import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/route_history_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/route_history_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/popular_routes_provider.dart';
import '../../providers/route_history_provider.dart';
import '../../providers/route_provider.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/map_preview_widget.dart';
import '../routes/port_selector_screen.dart';
import '../routes/quick_route_screen.dart';
import 'package:go_router/go_router.dart';


import 'package:provider/provider.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Future<List<RouteHistoryItem>>? _recentRoutesFuture;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().loadRoutes();

      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      debugPrint('👉 [Dashboard] currentUser=${user?.id}');

      if (user != null) {
        context.read<RouteHistoryProvider>().loadRecentForUser(user.id);
      } else {
        debugPrint('⚠️ [Dashboard] currentUser es null, no se puede cargar historial');
      }
    });
  }

  Future<void> _openPortSelector() async {
    final auth = context.read<AuthProvider>();
    final history = context.read<RouteHistoryProvider>();
    final userId = auth.currentUser?.id;

    // Abrir la pantalla de selección de puertos y esperar a que se cierre
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PortSelectorScreen(),
      ),
    );

    // Al volver, recargar historial
    if (userId != null) {
      await history.loadRecentForUser(userId);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Marítimo'),
        backgroundColor: const Color(0xFF0A6CBC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del usuario
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return DashboardHeader(
                  userName: authProvider.currentUser?.name ?? 'Usuario',
                  userRole: authProvider.currentUser?.role ?? 'Capitán',
                );
              },
            ),
            const SizedBox(height: 24),

            // Botones de acción principales
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openPortSelector,
                    icon: const Icon(Icons.anchor),
                    label: const Text(
                      'Seleccionar Puertos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6CBC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QuickRouteScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_road),
                    label: const Text(
                      'Ruta Rápida',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Accesos rápidos
            _buildQuickAccessSection(),
            const SizedBox(height: 24),

            // Mapa de previsualización
            const MapPreviewWidget(),
            const SizedBox(height: 24),

            // Por esto:
            _buildPopularRoutes(),

            // Rutas recientes
            _buildRecentRoutes(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Versión vertical de accesos rápidos (3 botones full width)
            Column(
              children: [
                _buildQuickAccessCard(
                  'Calcular Incoterms',
                  'Determina los mejores términos comerciales',
                  Icons.calculate,
                  const Color(0xFF0A6CBC),
                      () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PortSelectorScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickAccessCard(
                  'Reportes',
                  'Consulta reportes de envíos',
                  Icons.description,
                  Colors.orange,
                      () {
                        context.push('/shipment-reports');
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickAccessCard(
                  'Configuración',
                  'Ajusta preferencias del sistema',
                  Icons.settings,
                  Colors.purple,
                      () {
                        context.push('/settings');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPopularRoutes() {
    return Consumer<PopularRoutesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (provider.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al cargar rutas populares: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (provider.routes.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay rutas populares todavía'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rutas Populares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...provider.routes.map((r) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        r.searchesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${r.originPortName} → ${r.destinationPortName}'),
                    subtitle: Text('Buscado ${r.searchesCount} veces'),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildRecentRoutes() {
    return Consumer<RouteHistoryProvider>(
      builder: (context, historyProvider, child) {
        final recentRoutes = historyProvider.recent;
        final visibleRoutes = recentRoutes.take(3).toList(); // 👈 solo 3

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
                      'Rutas Recientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/route-history'); // 👈 ver todas
                      },
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (historyProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (recentRoutes.isEmpty)
                  const Text('No hay rutas recientes')
                else
                  ...visibleRoutes.map((item) {        // 👈 aquí usamos SOLO 3
                    final origin =
                    historyProvider.resolvePortName(item.originPortId);
                    final dest =
                    historyProvider.resolvePortName(item.destinationPortId);

                    final distanceStr = item.totalDistance != null
                        ? '${item.totalDistance!.toStringAsFixed(1)} nm'
                        : 'N/D';

                    final dt = item.computedAt.toLocal();
                    final timeStr =
                        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                        title: Text('$origin → $dest'),
                        subtitle: Text('$distanceStr · Calculado $timeStr'),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }








  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda - Dashboard Marítimo'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Funciones principales:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Seleccionar Puertos: Herramienta completa para seleccionar puertos de origen, destino e intermedios, con cálculo de Incoterms.'),
              SizedBox(height: 4),
              Text('• Ruta Rápida: Creación rápida de rutas básicas.'),
              SizedBox(height: 4),
              Text('• Calcular Incoterms: Determina los mejores términos comerciales para tu carga.'),
              SizedBox(height: 4),
              Text('• Estadísticas: Ve el resumen de tus rutas por estado.'),
              SizedBox(height: 4),
              Text('• Rutas Recientes: Acceso rápido a las últimas rutas creadas.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyRecentRoutes() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(
              Icons.route,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay rutas recientes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera ruta para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHistoryStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'NO_VIABLE_ROUTE':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getHistoryStatusIcon(String status) {
    switch (status) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'NO_VIABLE_ROUTE':
        return Icons.warning_amber;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getHistoryStatusText(String status) {
    switch (status) {
      case 'SUCCESS':
        return 'Completada';
      case 'NO_VIABLE_ROUTE':
        return 'No viable';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  String _formatHistorySubtitle(RouteHistoryItem item) {
    final computed = item.computedAt;

    final dateStr =
        '${computed.day.toString().padLeft(2, '0')}/'
        '${computed.month.toString().padLeft(2, '0')} '
        '${computed.hour.toString().padLeft(2, '0')}:'
        '${computed.minute.toString().padLeft(2, '0')}';

    final distanceStr = item.totalDistance != null
        ? '${item.totalDistance!.toStringAsFixed(1)} nm'
        : '—';

    return '$distanceStr · Calculado $dateStr';
  }





  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'planned':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.directions_boat;
      case 'completed':
        return Icons.check_circle;
      case 'planned':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'completed':
        return 'Completada';
      case 'planned':
        return 'Planificada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }
}