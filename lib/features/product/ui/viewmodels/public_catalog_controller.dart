import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/error_message.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/i_product_repository.dart';

/// El catálogo tal como lo ve alguien que no ha entrado.
///
/// Va aparte de [ProductController] porque no comparte casi nada con él: sin
/// sesión, sin caché y sin alta ni baja. Lo único que hace es leer.
class PublicCatalogController extends GetxController {
  PublicCatalogController(this._products);

  final IProductRepository _products;

  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      // assignAll copia; asignar `.value` haría que la RxList envolviera la
      // lista de la fuente, y si esa es inmutable el primer cambio revienta.
      products.assignAll(await _products.getPublicProducts());
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
