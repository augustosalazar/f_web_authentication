import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/public_catalog_controller.dart';

/// Catálogo leído sin sesión.
///
/// Se llega desde la pantalla de entrada, a propósito: que se vean productos
/// sin haber entrado dice más sobre lo que es una tabla pública que cualquier
/// explicación.
///
/// No es `read` sin token —eso da 401—: es otro endpoint, `public-read`, y solo
/// responde para las tablas marcadas como públicas en la consola de Roble.
class PublicCatalogPage extends StatelessWidget {
  const PublicCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogo = Get.find<PublicCatalogController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo público'),
        actions: [
          IconButton(
            key: const Key('catalog_refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: catalogo.load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Esta lista se cargó sin iniciar sesión, con db.publicRead. '
              'Cualquiera con el id del proyecto puede leerla.',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
          Expanded(child: Obx(() => _cuerpo(context, catalogo, scheme))),
        ],
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    PublicCatalogController catalogo,
    ColorScheme scheme,
  ) {
    if (catalogo.isLoading.value && catalogo.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (catalogo.error.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 40, color: scheme.error),
              const SizedBox(height: 12),
              Text(
                catalogo.error.value,
                key: const Key('catalog_error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ],
          ),
        ),
      );
    }

    if (catalogo.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            // Vacío no es lo mismo que prohibido, y aquí conviene que se note:
            // la tabla respondió, solo que no tiene filas.
            'La tabla respondió, pero no hay productos todavía.\n'
            'Entra y crea uno para verlo aparecer aquí sin sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: catalogo.products.length,
      itemBuilder: (context, i) {
        final producto = catalogo.products[i];
        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(producto.name),
          subtitle: Text(producto.description),
          trailing: Text('${producto.quantity}'),
        );
      },
    );
  }
}
