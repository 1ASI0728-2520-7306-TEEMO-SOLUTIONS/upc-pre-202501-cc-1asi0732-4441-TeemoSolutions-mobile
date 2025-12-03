import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/route_history_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_history_provider.dart';
import '../../widgets/common/custom_drawer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


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

  Future<void> _downloadRoutePdf(RouteHistoryItem item) async {
    final provider = context.read<RouteHistoryProvider>();

    final origin = provider.resolvePortName(item.originPortName);
    final dest = provider.resolvePortName(item.destinationPortName);

    final date = item.computedAt.toLocal();
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";

    final distanceStr = item.totalDistance != null
        ? "${item.totalDistance!.toStringAsFixed(1)} nm"
        : "N/D";

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de Ruta',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text("ID del historial: ${item.id}"),
              pw.Text("Origen: $origin"),
              pw.Text("Destino: $dest"),
              pw.Text("Distancia: $distanceStr"),
              pw.Text("Estado: ${item.status}"),
              pw.Text("Fuente: ${item.source}"),
              pw.Text("Fecha de cálculo: $dateStr"),

              pw.SizedBox(height: 16),

              pw.Divider(),

              pw.Text(
                "Generado desde Mushroom Marine Navigation",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: "ruta_${item.id}.pdf",
    );
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

              final origin = provider.resolvePortName(item.originPortName);
              final dest = provider.resolvePortName(item.destinationPortName);

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
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.route, color: Colors.white),
                  ),
                  title: Text("$origin → $dest"),
                  subtitle: Text("$distance · Calculado $dateStr"),

                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: "Descargar PDF",
                    onPressed: () => _downloadRoutePdf(item),
                  ),
                ),
              );


            },
          );
        },
      ),
    );
  }
}


