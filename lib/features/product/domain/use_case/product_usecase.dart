import '../models/product.dart';
import '../repositories/i_product_repository.dart';

class ProductUseCase {
  late IProductRepository repository;

  ProductUseCase(this.repository);

  Future<List<Product>> getProducts() async => await repository.getProducts();

  Future<void> addProduct(
          String name, String description, String quantity) async =>
      await repository.addProduct(Product(
          name: name, description: description, quantity: int.parse(quantity)));

  Future<void> updateProduct(Product user) async =>
      await repository.updateProduct(user);

  Future<void> deleteProduct(Product user) async =>
      await repository.deleteProduct(user);

  Future<void> deleteProducts() async => await repository.deleteProducts();
}
