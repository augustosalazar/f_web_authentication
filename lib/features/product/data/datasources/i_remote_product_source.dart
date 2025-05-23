import '../../domain/models/product.dart';

abstract class IRemoteUserSource {
  Future<List<Product>> getProducts();

  Future<bool> addProduct(Product user);

  Future<bool> updateProduct(Product user);

  Future<bool> deleteProduct(Product user);

  Future<bool> deleteProducts();
}
