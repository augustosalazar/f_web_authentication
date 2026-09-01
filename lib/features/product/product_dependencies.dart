import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'data/datasources/cache/local_product_cache_source.dart';
import 'data/datasources/remote/i_product_source.dart';
import 'data/datasources/remote/remote_product_roble_source.dart';
import 'data/repositories/product_repository.dart';
import 'domain/repositories/i_product_repository.dart';
import 'ui/viewmodels/product_controller.dart';
import 'ui/viewmodels/public_catalog_controller.dart';

/// Registra los productos en GetX.
///
/// `fenix` en toda la cadena: sin él, GetX consume la fábrica al descartar la
/// ruta y volver a entrar falla con «not found».
void registerProduct(RobleApiDataBase roble) {
  Get.lazyPut<IProductSource>(() => RemoteProductRobleSource(roble),
      fenix: true);

  Get.lazyPut<LocalProductCacheSource>(() => LocalProductCacheSource(Get.find()),
      fenix: true);

  Get.lazyPut<IProductRepository>(
      () => ProductRepository(Get.find(), Get.find()),
      fenix: true);
  Get.lazyPut(() => ProductController(Get.find()), fenix: true);

  // El catálogo público va aparte del controlador de productos: se lee sin
  // sesión y sin caché, y no da de alta ni de baja.
  Get.lazyPut(() => PublicCatalogController(Get.find()), fenix: true);
}
