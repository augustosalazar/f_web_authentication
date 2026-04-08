import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../auth/ui/viewmodels/authentication_controller.dart';
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
  AuthenticationController authenticationController = Get.find();

  _logout() async {
    try {
      await authenticationController.logOut();
    } catch (e) {
      logInfo(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${authenticationController.loggedUser?.name}"),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _logout();
            },
          ),
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
