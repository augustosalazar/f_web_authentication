import 'dart:convert';
import 'package:loggy/loggy.dart';
import '../../domain/models/product.dart';
import 'package:http/http.dart' as http;

import 'i_remote_product_source.dart';

class RemoteProductRobleSource implements IRemoteUserSource {
  final http.Client httpClient;

  final String baseUrl = 'https://roble-api.test-openlab.uninorte.edu.co/database/contract_flutterdemo_ebabe79ab0';
  final String table = 'Product';

  RemoteProductRobleSource  ({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<List<Product>> getProducts() async {
    List<Product> products = [];
    var request = Uri.parse("$baseUrl/read")
        .resolveUri(Uri(queryParameters: {
      "format": 'json',
      "table_name": table,
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
      Uri.parse("$baseUrl/insert"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',

      },
      body: jsonEncode({
        'tableName': table,
        'data': product.toJsonNoId(),
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
      Uri.parse("$baseUrl/update"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tableName': table,
        'idColumn': '_id',
        'idValue': product.id ?? "0",
        'updates': product.toJsonNoId(),
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
      Uri.parse("$baseUrl/delete"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tableName': table,
        'idColumn': '_id',
        'idValue': product.id ?? "0",
      }),
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
