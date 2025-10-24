import 'dart:convert';
import 'package:loggy/loggy.dart';
import '../../domain/models/product.dart';
import 'package:http/http.dart' as http;

import 'i_product_source.dart';

class RemoteProductSource with UiLoggy implements IProductSource {
  final http.Client httpClient;

  final String contractKey = 'e83b7ac8-bdad-4bb8-a532-6aaa5fddefa4';
  final String baseUrl = 'https://unidb.openlab.uninorte.edu.co';
  final String table = 'products';

  RemoteProductSource({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<List<Product>> getProducts() async {
    List<Product> products = [];
    var request = Uri.parse("$baseUrl/$contractKey/data/$table/all")
        .resolveUri(Uri(queryParameters: {
      "format": 'json',
    }));

    var response = await httpClient.get(request);

    if (response.statusCode == 200) {
      //loggy.info(response.body);
      //final data = jsonDecode(response.body);

      Map<String, dynamic> decodedJson = jsonDecode(response.body);
      final data = decodedJson['data'];

      loggy.info(data);

      products = List<Product>.from(data.map((x) => Product.fromJson(x)));
      //users.removeAt(1);
    } else {
      loggy.error("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }

    return Future.value(products);
  }

  @override
  Future<bool> addProduct(Product product) async {
    loggy.info("Web service, Adding user");

    final response = await httpClient.post(
      Uri.parse("$baseUrl/$contractKey/data/store"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'table_name': table,
        'data': product.toJson(),
      }),
    );

    if (response.statusCode == 201) {
      //loggy.info(response.body);
      return Future.value(true);
    } else {
      loggy.error("Got error code ${response.statusCode}");
      loggy.error(response.body);
      return Future.value(false);
    }
  }

  @override
  Future<bool> updateProduct(Product product) async {
    loggy.info("Web service, Updating user with id $product");
    final response = await httpClient.put(
      Uri.parse("$baseUrl/$contractKey/data/$table/update/${product.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': product.toJsonNoId(),
      }),
    );

    loggy.info("updateUser response status code ${response.statusCode}");
    loggy.info("updateUser response body ${response.body}");
    if (response.statusCode == 200) {
      return Future.value(true);
    } else {
      loggy.error("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteProduct(Product product) async {
    loggy.info("Web service, Deleting user with id $product");
    final response = await httpClient.delete(
      Uri.parse("$baseUrl/$contractKey/data/$table/delete/${product.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    loggy.info("deleteUser response status code ${response.statusCode}");
    loggy.info("deleteUser response body ${response.body}");
    if (response.statusCode == 200) {
      //loggy.info(response.body);
      return Future.value(true);
    } else {
      loggy.error("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteProducts() async {
    List<Product> users = await getProducts();
    for (var user in users) {
      await deleteProduct(user);
    }
    return Future.value(true);
  }
}
