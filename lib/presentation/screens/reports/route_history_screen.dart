import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_history_provider.dart';
import '../../widgets/common/custom_drawer.dart';

class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;

      if (userId != null) {
        context.read<RouteHistoryProvider>().loadRecentForUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Rutas"),
      ),
      drawer: const CustomDrawer(),
      body: Consumer<RouteHistoryProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text("Error: ${provider.errorMessage}"),
            );
          }

          final routes = provider.recent;

          if (routes.isEmpty) {
            return const Center(
              child: Text("No hay rutas registradas"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final item = routes[index];

              final origin = provider.resolvePortName(item.originPortId);
              final dest = provider.resolvePortName(item.destinationPortId);

              final distance = item.totalDistance != null
                  ? "${item.totalDistance!.toStringAsFixed(1)} nm"
                  : "N/D";

              final date = item.computedAt.toLocal();
              final dateStr =
                  "${date.day.toString().padLeft(2, '0')}/"
                  "${date.month.toString().padLeft(2, '0')} "
                  "${date.hour.toString().padLeft(2, '0')}:"
                  "${date.minute.toString().padLeft(2, '0')}";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.route, color: Colors.white),
                  ),
                  title: Text("$origin → $dest"),
                  subtitle: Text("$distance · Calculado $dateStr"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
