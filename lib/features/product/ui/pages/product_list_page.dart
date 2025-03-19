import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../auth/ui/controller/authentication_controller.dart';
import '../../domain/models/user.dart';

import '../controller/user_controller.dart';
import 'edit_product_page.dart';
import 'new_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  UserController userController = Get.find();
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
      appBar: AppBar(title: const Text("Welcome"), actions: [
        IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _logout();
            }),
        IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              userController.deleteUsers();
            }),
      ]),
      body: Center(child: _getXlistView()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          logInfo("Add user from UI");
          Get.to(() => const NewProductPage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getXlistView() {
    return Obx(
      () => ListView.builder(
        itemCount: userController.users.length,
        itemBuilder: (context, index) {
          User user = userController.users[index];
          return Dismissible(
            key: UniqueKey(),
            background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    "Deleting",
                    style: TextStyle(color: Colors.white),
                  ),
                )),
            onDismissed: (direction) {
              userController.deleteUser(user);
            },
            child: Card(
              child: ListTile(
                leading: Text(user.id.toString()),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Get.to(() => const EditUserPage(),
                      arguments: [user, user.id]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
