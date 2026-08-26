import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/product.dart';
import 'i_product_source.dart';

class RemoteProductRobleSource implements IProductSource {
  RemoteProductRobleSource(this._database);

  static const _table = 'Product';

  final RobleApiDataBase _database;

  @override
  Future<List<Product>> getProducts() async {
    final records = await _database.read(_table);
    return records.map(Product.fromJson).toList();
  }

  @override
  Future<List<Product>> getPublicProducts() async {
    try {
      final records = await _database.publicRead(_table);
      return records.map(Product.fromJson).toList();
    } on RobleApiHttpException catch (e) {
      // El 403 aquí no es un token malo —no se manda ninguno—: es que la tabla
      // no está marcada como pública. Decirlo evita buscar el fallo en la
      // sesión, que es donde nadie lo va a encontrar.
      if (e.statusCode == 403) {
        throw const RobleApiException(
          'La tabla $_table no está marcada como pública en la consola de Roble.',
        );
      }
      rethrow;
    }
  }

  /// Nombre de la consulta guardada en la consola de Roble.
  ///
  /// Por nombre y no por UUID a proposito: el nombre se lee en la consola y
  /// sobrevive a recrear la consulta, mientras que el UUID cambia.
  static const _outOfStockQuery = 'productosSinInventario';

  @override
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      final res = await _database.executeQueryByName(_outOfStockQuery);
      return res.rows
          .whereType<Map>()
          .map((row) => _productoDe(Map<String, dynamic>.from(row)))
          .toList();
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 404) {
        throw const RobleApiException(
          'No hay ninguna consulta guardada llamada "$_outOfStockQuery" en la '
          'consola de Roble.',
        );
      }
      rethrow;
    }
  }

  /// Una consulta guardada no devuelve columnas de la tabla, sino las que pida
  /// su SQL: Postgres entrega `bigint` y `numeric` como texto, asi que la
  /// cantidad puede llegar en String donde la tabla la da en int.
  Product _productoDe(Map<String, dynamic> row) {
    final cantidad = row['quantity'];
    return Product(
      id: row['_id']?.toString(),
      name: row['name']?.toString() ?? '---',
      description: row['description']?.toString() ?? '---',
      quantity:
          cantidad is int ? cantidad : int.tryParse('${cantidad ?? ''}') ?? 0,
    );
  }

  @override
  Future<bool> addProduct(Product product) async {
    logInfo('Adding product through the Roble client');
    await _database.create(_table, product.toJsonNoId());
    return true;
  }

  @override
  Future<bool> updateProduct(Product product) async {
    final id = product.id;
    if (id == null) {
      throw const RobleApiException('Cannot update a product without an id.');
    }

    logInfo('Updating product $id through the Roble client');
    await _database.update(_table, id, product.toJsonNoId());
    return true;
  }

  @override
  Future<bool> deleteProduct(Product product) async {
    final id = product.id;
    if (id == null) {
      throw const RobleApiException('Cannot delete a product without an id.');
    }

    logInfo('Deleting product $id through the Roble client');
    await _database.delete(_table, id);
    return true;
  }

  @override
  Future<bool> deleteProducts() async {
    final products = await getProducts();
    await Future.wait(products.map(deleteProduct));
    return true;
  }
}
