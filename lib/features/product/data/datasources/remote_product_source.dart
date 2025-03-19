import 'dart:convert';
import 'package:loggy/loggy.dart';
import '../../domain/models/product.dart';
import 'package:http/http.dart' as http;

import 'i_remote_product_source.dart';

class RemoteProductSource implements IRemoteUserSource {
  final http.Client httpClient;

  final String contractKey = '87f1ab21-327b-4dcc-bea0-067a47214eca';
  final String baseUrl = 'http://unidb.openlab.uninorte.edu.co';
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
      //logInfo(response.body);
      //final data = jsonDecode(response.body);

      Map<String, dynamic> decodedJson = jsonDecode(response.body);
      final data = decodedJson['data'];

      logInfo(data);

      products = List<Product>.from(data.map((x) => Product.fromJson(x)));
      //users.removeAt(1);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }

    return Future.value(products);
  }

  @override
  Future<bool> addProduct(Product product) async {
    logInfo("Web service, Adding user");

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
      //logInfo(response.body);
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      logError(response.body);
      return Future.value(false);
    }
  }

  @override
  Future<bool> updateProduct(Product product) async {
    logInfo("Web service, Updating user with id $product");
    final response = await httpClient.put(
      Uri.parse("$baseUrl/$contractKey/data/$table/update/${product.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': product.toJsonNoId(),
      }),
    );

    logInfo("updateUser response status code ${response.statusCode}");
    logInfo("updateUser response body ${response.body}");
    if (response.statusCode == 200) {
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteProduct(Product product) async {
    logInfo("Web service, Deleting user with id $product");
    final response = await httpClient.delete(
      Uri.parse("$baseUrl/$contractKey/data/$table/delete/${product.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    logInfo("deleteUser response status code ${response.statusCode}");
    logInfo("deleteUser response body ${response.body}");
    if (response.statusCode == 200) {
      //logInfo(response.body);
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
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
