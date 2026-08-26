import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../auth/ui/viewmodels/authentication_controller.dart';
import '../../../chat/ui/pages/chat_page.dart';
import '../../../product/ui/pages/list_product_page.dart';

/// Pantalla de entrada de la app.
///
/// Antes se entraba directamente a la lista de productos y el chat colgaba de
/// un icono en su barra, junto al de borrarlo todo. Pero productos y chat no
/// son dos pantallas de lo mismo: son **dos módulos distintos de Roble** —una
/// tabla SQL y un árbol JSON—, y meter uno dentro del otro escondía justo la
/// diferencia que esta app existe para enseñar.
///
/// Así que cada módulo tiene su tarjeta, y la tarjeta dice qué demuestra y con
/// qué API. Cuando el paquete gane una capacidad nueva, entra aquí como una
/// tarjeta más.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthenticationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roble'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(auth),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Obx(() {
            final user = auth.loggedUser;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Sin usuario, sin coma colgando: pasa entre que la sesion
                  // se restaura y llega el perfil.
                  user == null ? 'Hola' : 'Hola, ${user.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (user != null)
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            );
          }),
          const SizedBox(height: 24),
          Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ModuleCard(
            cardKey: const Key('home_card_products'),
            icon: Icons.table_chart,
            title: 'Productos',
            what: 'Tabla SQL: el esquema se declara antes, y la tabla aparece '
                'entre las del proyecto.',
            api: 'db.read · insert · update · delete',
            onTap: () => Get.to(() => const ListProductPage()),
          ),
          _ModuleCard(
            cardKey: const Key('home_card_chat'),
            icon: Icons.chat,
            title: 'Chat',
            what: 'Árbol JSON: sin esquema, nace con el primer mensaje y los '
                'cambios llegan en vivo.',
            api: 'db.json.push · db.json.watch',
            onTap: () => Get.to(() => const ChatPage()),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(AuthenticationController auth) async {
    try {
      await auth.logOut();
    } catch (e) {
      logInfo(e);
    }
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.what,
    required this.api,
    required this.onTap,
  });

  final Key cardKey;
  final IconData icon;
  final String title;

  /// Qué modelo de datos demuestra el módulo.
  final String what;

  /// Las llamadas del paquete que usa, que es lo que se viene a copiar.
  final String api;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      what,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      api,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
