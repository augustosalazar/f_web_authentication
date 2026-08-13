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
    final records = await _database.getAll(_table);
    return records.map(Product.fromJson).toList();
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
