import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart'; // 👈 importa tu theme provider
import '../../widgets/common/custom_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailReports = false;

  @override
  Widget build(BuildContext context) {
    // leemos el estado actual del tema desde el provider
    final isDark =
        context.watch<ThemeProvider>().themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        children: [
          // Cuenta
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Cuenta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  user?.name ?? 'Usuario desconocido',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  user?.role ?? 'Sin rol asignado',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
          const Divider(height: 1),

          // Notificaciones
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Notificaciones',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SwitchListTile(
            title: const Text('Habilitar notificaciones'),
            subtitle: const Text('Recibir alertas de envíos e Incoterms'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() {
                _notificationsEnabled = val;
              });
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          const Divider(height: 1),

          // Aplicación
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Aplicación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            value: isDark,
            onChanged: (val) {

              context.read<ThemeProvider>().toggleTheme(val);
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),

          const Divider(height: 1),

          // Acerca de
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Acerca de',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidad'),
            onTap: () {},
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
