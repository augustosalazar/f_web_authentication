import 'package:f_web_authentication/features/product/data/datasources/cache/local_product_cache_source.dart';
import 'package:loggy/loggy.dart';

import '../../domain/repositories/i_product_repository.dart';
import '../datasources/remote/i_product_source.dart';
import '../../domain/models/product.dart';

class ProductRepository implements IProductRepository {
  late IProductSource userSource;
  late LocalProductCacheSource cacheSource;

  ProductRepository(this.userSource, this.cacheSource);

  @override
  Future<List<Product>> getProducts() async {
    try {
      if (await cacheSource.isCacheValid()) {
        return await cacheSource.getCachedProductData();
      }
    } catch (e) {
      // Ignore cache errors
    }

    logInfo('🌐 Cache miss: Fetching from API');

    try {
      final products = await userSource.getProducts();
      await cacheSource.cacheProductData(products);
      return products;
    } catch (e) {
      logError('Error fetching products from API: $e');
      rethrow;
    }
  }

  @override
  Future<void> addProduct(Product user) async {
    await userSource.addProduct(user);
    await cacheSource.clearCache(); // Clear cache on add
    return;
  }

  @override
  Future<void> updateProduct(Product user) async {
    await userSource.updateProduct(user);
    await cacheSource.clearCache(); // Clear cache on update
    return;
  }

  @override
  Future<void> deleteProduct(Product user) async {
    await userSource.deleteProduct(user);
    await cacheSource.clearCache(); // Clear cache on delete
    return;
  }

  @override
  Future<void> deleteProducts() async {
    await userSource.deleteProducts();
    await cacheSource.clearCache(); // Clear cache on delete all
    return;
  }

  @override
  Future<List<Product>> forceRefresh() async {
    logInfo('🔄 Force refresh from API');
    final products = await userSource.getProducts();
    await cacheSource.cacheProductData(products);
    return products;
  }

  @override
  Future<void> clearCache() async {
    await cacheSource.clearCache();
  }
}
