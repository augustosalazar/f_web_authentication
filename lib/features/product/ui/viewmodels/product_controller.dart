import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../../../../core/session_expiry.dart';
import '../../domain/models/product.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final IProductRepository productUseCase;
  final RxBool isLoading = false.obs;

  /// El filtro está puesto: la lista viene de la consulta guardada.
  final RxBool onlyOutOfStock = false.obs;

  /// Vacío mientras todo va bien. Antes una lectura fallida subía sin que
  /// nadie la recogiera; con la consulta guardada eso pasa en cuanto la
  /// consulta no existe todavía, que es el caso normal la primera vez.
  final RxString error = ''.obs;

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
    error.value = '';
    try {
      _products.assignAll(onlyOutOfStock.value
          ? await productUseCase.getOutOfStockProducts()
          : await productUseCase.getProducts());
    } catch (e) {
      error.value = reportError(e);
      // La lista se vacía: dejar la anterior mostraría el catálogo completo
      // bajo el filtro puesto, que es lo contrario de lo que se pidió.
      _products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Pone o quita el filtro y recarga.
  Future<void> toggleOutOfStock() async {
    onlyOutOfStock.value = !onlyOutOfStock.value;
    await getProducts();
  }

  Future<void> forceRefresh() async {
    logInfo("ProductController: Force refreshing products");

    // Con el filtro puesto no hay caché que saltarse —la consulta guardada la
    // resuelve el servidor cada vez—, y refrescar por la vía normal devolvería
    // el catálogo completo con el filtro aún marcado.
    if (onlyOutOfStock.value) return getProducts();

    isLoading.value = true;
    error.value = '';
    try {
      _products.assignAll(await productUseCase.forceRefresh());
    } catch (e) {
      error.value = reportError(e);
      _products.clear();
    } finally {
      isLoading.value = false;
    }
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
