import '../../../domain/models/product.dart';

abstract class IProductSource {
  Future<List<Product>> getProducts();

  /// Lee el catálogo sin sesión, por la vía pública.
  ///
  /// No es [getProducts] sin token: es otro endpoint, y solo responde si la
  /// tabla está marcada como pública en la consola de Roble.
  Future<List<Product>> getPublicProducts();

  /// Productos sin inventario, segun la consulta guardada en la consola.
  ///
  /// La lista no se calcula aqui: la decide el SQL guardado, asi que cambiar
  /// que cuenta como «sin inventario» no obliga a publicar la app otra vez.
  Future<List<Product>> getOutOfStockProducts();

  Future<bool> addProduct(Product product);

  Future<bool> updateProduct(Product product);

  Future<bool> deleteProduct(Product product);

  Future<bool> deleteProducts();
}
