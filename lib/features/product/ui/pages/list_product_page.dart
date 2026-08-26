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
      body: Center(child: _getXlistView()),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_product_fab'),
        onPressed: () async {
          Get.to(() => const AddProductPage());
        },
        child: const Icon(Icons.add),
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
              child: ListView.builder(
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
