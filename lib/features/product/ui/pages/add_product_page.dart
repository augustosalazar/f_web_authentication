import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/product_controller.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final controllerName = TextEditingController();
  final controllerDesc = TextEditingController();
  final controllerQuantity = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ProductController productController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            TextField(
                controller: controllerName,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                )),
            const SizedBox(
              height: 20,
            ),
            TextField(
                controller: controllerDesc,
                decoration: const InputDecoration(
                  labelText: 'Product Description',
                )),
            const SizedBox(
              height: 20,
            ),
            TextField(
                controller: controllerQuantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                )),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                      flex: 2,
                      child: ElevatedButton(
                          onPressed: () async {
                            await productController.addProduct(
                                controllerName.text,
                                controllerDesc.text,
                                controllerQuantity.text);
                            Get.back();
                          },
                          child: const Text("Save")))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
