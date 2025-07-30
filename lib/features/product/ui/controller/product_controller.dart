import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/product.dart';
import '../../domain/use_case/product_usecase.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final ProductUseCase productUseCase = Get.find();
  final RxBool isLoading = false.obs;
  List<Product> get products => _products;

  @override
  void onInit() {
    getProducts();
    super.onInit();
  }

  getProducts() async {
    logInfo("ProductController: Getting products");
    isLoading.value = true;
    _products.value = await productUseCase.getProducts();
    isLoading.value = false;
  }

  addProduct(String name, String desc, String quantity) async {
    logInfo("ProductController: Add product");
    await productUseCase.addProduct(name, desc, quantity);
    getProducts();
  }

  updateProduct(Product product) async {
    logInfo("ProductController: Update product");
    await productUseCase.updateProduct(product);
    await getProducts();
  }

  void deleteProduct(Product p) async {
    logInfo("ProductController: Delete product");

    await productUseCase.deleteProduct(p);
    await getProducts();
  }

  void deleteProducts() async {
    logInfo("ProductController: Delete all products");
    isLoading.value = true;
    await productUseCase.deleteProducts();
    await getProducts();
    isLoading.value = false;
  }
}
