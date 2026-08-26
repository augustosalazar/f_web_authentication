import '../models/product.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts();

  Future<List<Product>> forceRefresh();

  /// El catálogo tal como lo ve alguien sin cuenta.
  Future<List<Product>> getPublicProducts();

  /// Productos sin inventario, segun la consulta guardada en la consola.
  Future<List<Product>> getOutOfStockProducts();

  Future<void> addProduct(Product p);

  Future<void> updateProduct(Product p);

  Future<void> deleteProduct(Product p);

  Future<void> deleteProducts();

  Future<void> clearCache();
}
