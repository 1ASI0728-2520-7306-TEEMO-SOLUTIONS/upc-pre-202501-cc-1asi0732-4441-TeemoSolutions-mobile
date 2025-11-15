import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/map_preview_widget.dart';
import '../reports/shipment_reports_screen.dart';
import '../routes/port_selector_screen.dart';
import '../routes/quick_route_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().loadRoutes();
    });
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PortSelectorScreen(),
                        ),
                      );
                    },
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

            // Estadísticas rápidas
            _buildQuickStats(),
            const SizedBox(height: 24),

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

  Widget _buildQuickStats() {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Rutas Activas',
                        routeProvider.routes
                            .where((route) => route.status == 'active')
                            .length
                            .toString(),
                        Icons.directions_boat,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Rutas Completadas',
                        routeProvider.routes
                            .where((route) => route.status == 'completed')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Rutas Planificadas',
                        routeProvider.routes
                            .where((route) => route.status == 'planned')
                            .length
                            .toString(),
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total de Rutas',
                        routeProvider.routes.length.toString(),
                        Icons.route,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoutes() {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        final recentRoutes = routeProvider.routes.take(3).toList();
        
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
                        // TODO: Navegar a la lista completa de rutas
                      },
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentRoutes.isEmpty)
                  Center(
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PortSelectorScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.anchor),
                            label: const Text('Seleccionar Puertos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A6CBC),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentRoutes.map((route) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(route.status),
                        child: Icon(
                          _getStatusIcon(route.status),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        route.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${route.from} → ${route.to}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getStatusText(route.status),
                            style: TextStyle(
                              color: _getStatusColor(route.status),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${route.vessels} embarcación${route.vessels > 1 ? 'es' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Navegar a los detalles de la ruta
                      },
                    ),
                  )).toList(),
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
