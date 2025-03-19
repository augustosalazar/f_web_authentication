import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/product.dart';
import '../../domain/use_case/user_usecase.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final UserUseCase productUseCase = Get.find();

  List<Product> get products => _products;

  @override
  void onInit() {
    getUers();
    super.onInit();
  }

  getUers() async {
    logInfo("Getting products");
    _products.value = await productUseCase.getProducts();
  }

  addProduct(String name, String desc, String quantity) async {
    logInfo("Add product");
    await productUseCase.addProduct(name, desc, quantity);
    getUers();
  }

  updateProduct(Product user) async {
    logInfo("Update product");
    await productUseCase.updateProduct(user);
    getUers();
  }

  void deleteUser(Product p) async {
    await productUseCase.deleteProduct(p);
    getUers();
  }

  void deleteUsers() async {
    await productUseCase.deleteProducts();
    getUers();
  }
}
