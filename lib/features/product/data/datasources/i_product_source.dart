import '../../domain/models/product.dart';

abstract class IProductSource {
  Future<List<Product>> getProducts();

  Future<bool> addProduct(Product product);

  Future<bool> updateProduct(Product product);

  Future<bool> deleteProduct(Product product);

  Future<bool> deleteProducts();
}
