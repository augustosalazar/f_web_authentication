import '../models/product.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts();

  Future<List<Product>> forceRefresh();

  Future<void> addProduct(Product p);

  Future<void> updateProduct(Product p);

  Future<void> deleteProduct(Product p);

  Future<void> deleteProducts();

  Future<void> clearCache();
}
