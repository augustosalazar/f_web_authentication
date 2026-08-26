import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/product.dart';
import '../viewmodels/product_controller.dart';
import 'edit_product_page.dart';
import 'add_product_page.dart';

class ListProductPage extends StatefulWidget {
  const ListProductPage({super.key});

  @override
  State<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends State<ListProductPage> {
  ProductController productController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // El saludo y el cerrar sesion viven en el inicio: esta es una
        // pantalla de funcion, no la entrada de la app.
        title: const Text('Productos'),
        actions: [
          IconButton(
            key: const Key('delete_all_button'),
            icon: const Icon(Icons.delete),
            onPressed: () {
              productController.deleteProducts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _filtro(context),
          Obx(() => productController.error.value.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    productController.error.value,
                    key: const Key('product_error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                )),
          Expanded(child: Center(child: _getXlistView())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_product_fab'),
        onPressed: () async {
          Get.to(() => const AddProductPage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// La lista filtrada no la calcula la app: la decide la consulta guardada
  /// `productosSinInventario` en la consola de Roble, asi que cambiar que
  /// cuenta como «sin inventario» no obliga a publicar la app otra vez.
  Widget _filtro(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Obx(() => FilterChip(
              key: const Key('out_of_stock_filter'),
              avatar: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('Sin inventario'),
              selected: productController.onlyOutOfStock.value,
              onSelected: productController.isLoading.value
                  ? null
                  : (_) => productController.toggleOutOfStock(),
            )),
      ),
    );
  }

  Widget _getXlistView() {
    return Obx(
      () => productController.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await productController.forceRefresh();
              },
              child: productController.products.isEmpty
                  ? ListView(
                      // Lista y no Center: el RefreshIndicator necesita algo
                      // desplazable para que el tiron funcione tambien vacio.
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            productController.onlyOutOfStock.value
                                ? 'No hay productos sin inventario.'
                                : 'No hay productos todavia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: productController.products.length,
                      itemBuilder: (context, index) {
                        Product user = productController.products[index];
                        return Dismissible(
                          key: Key('product_dismiss_${user.id}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerLeft,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                "Deleting",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          onDismissed: (direction) {
                            productController.deleteProduct(user);
                          },
                          child: Card(
                            child: ListTile(
                              key: Key('product_tile_${user.id}'),
                              title: Text(user.name),
                              subtitle: Text(user.description),
                              trailing: Text(user.quantity.toString()),
                              onTap: () {
                                Get.to(
                                  () => const EditProductPage(),
                                  arguments: [user, user.id],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
