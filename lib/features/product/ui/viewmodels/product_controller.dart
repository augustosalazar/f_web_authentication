import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../../domain/models/product.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final IProductRepository productUseCase;
  final RxBool isLoading = false.obs;

  ProductController(this.productUseCase);
  List<Product> get products => _products;

  @override
  void onInit() {
    getProducts();
    super.onInit();
  }

  Future<void> getProducts() async {
    logInfo("ProductController: Getting products");
    isLoading.value = true;
    _products.value = await productUseCase.getProducts();
    isLoading.value = false;
  }

  Future<void> forceRefresh() async {
    logInfo("ProductController: Force refreshing products");
    isLoading.value = true;
    _products.value = await productUseCase.forceRefresh();
    isLoading.value = false;
  }

  Future<void> addProduct(String name, String desc, String quantity) async {
    logInfo("ProductController: Add product");
    await productUseCase.addProduct(
        Product(name: name, description: desc, quantity: int.parse(quantity)));
    getProducts();
  }

  Future<void> updateProduct(Product product) async {
    logInfo("ProductController: Update product");
    await productUseCase.updateProduct(product);
    await getProducts();
  }

  Future<void> deleteProduct(Product p) async {
    logInfo("ProductController: Delete product");

    await productUseCase.deleteProduct(p);
    await getProducts();
  }

  Future<void> deleteProducts() async {
    logInfo("ProductController: Delete all products");
    isLoading.value = true;
    await productUseCase.deleteProducts();
    await getProducts();
    isLoading.value = false;
  }

  Future<void> clearCache() async {
    logInfo("ProductController: Clear product cache");
    await productUseCase.clearCache();
  }
}
