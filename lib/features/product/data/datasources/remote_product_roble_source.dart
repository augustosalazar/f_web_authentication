import 'dart:convert';
import 'package:f_web_authentication/core/roble_exception.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../../../../core/i_local_preferences.dart';
import '../../domain/models/product.dart';
import 'package:http/http.dart' as http;

import 'i_product_source.dart';

class RemoteProductRobleSource implements IProductSource {
  final http.Client httpClient;

  final String contract =
      dotenv.get('EXPO_PUBLIC_ROBLE_PROJECT_ID', fallback: "NO_ENV");
  final String baseUrl = 'roble-api.openlab.uninorte.edu.co';
  String get contractUrl => '$baseUrl/$contract';
  final String table = 'Product';

  RemoteProductRobleSource(this.httpClient);

  @override
  Future<List<Product>> getProducts() async {
    List<Product> products = [];

    var uri = Uri.https(
      baseUrl,
      '/database/$contract/read',
      {'tableName': table},
    );
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');
    var response =
        await httpClient.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> decodedJson = jsonDecode(response.body);

      //logInfo(decodedJson);

      products =
          List<Product>.from(decodedJson.map((x) => Product.fromJson(x)));
    } else {
      _handleError(response, "getProducts");
    }

    return Future.value(products);
  }

  @override
  Future<bool> addProduct(Product product) async {
    logInfo("Web service, Adding product");

    final uri = Uri.https(
      baseUrl,
      '/database/$contract/insert',
    );
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "tableName": table,
      "records": [
        product.toJsonNoId(),
      ],
    });

    final response = await httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      _handleError(response, "addProduct");
    }
  }

  @override
  Future<bool> updateProduct(Product product) async {
    logInfo("Web service, Updating product with id $product");
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');

    final uri = Uri.https(
      baseUrl,
      '/database/$contract/update',
    );

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await httpClient.put(
      uri,
      headers: headers,
      body: jsonEncode({
        'tableName': table,
        'idColumn': '_id',
        'idValue': product.id ?? "0",
        'updates': product.toJsonNoId(),
      }),
    );

    //logInfo("update response status code ${response.statusCode}");
    //logInfo("update response body ${response.body}");
    if (response.statusCode == 200) {
      return Future.value(true);
    } else {
      _handleError(response, "updateProduct");
    }
  }

  @override
  Future<bool> deleteProduct(Product product) async {
    logInfo("Web service, Deleting product with id $product");
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');

    final uri = Uri.https(
      baseUrl,
      '/database/$contract/delete',
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await httpClient.delete(uri,
        headers: headers,
        body: jsonEncode({
          'tableName': table,
          'idColumn': '_id',
          'idValue': product.id ?? "0",
        }));

    //logInfo("delete response status code ${response.statusCode}");
    //logInfo("delete response body ${response.body}");
    if (response.statusCode == 200) {
      return Future.value(true);
    } else {
      _handleError(response, "deleteProduct");
    }
  }

  @override
  Future<bool> deleteProducts() async {
    List<Product> products = await getProducts();
    for (var product in products) {
      await deleteProduct(product);
    }
    return Future.value(true);
  }

  Never _handleError(http.Response response, String context) {
    String errorMessage;
    try {
      final body = jsonDecode(response.body);
      errorMessage = body['message'] ?? 'Unknown error';
    } catch (_) {
      errorMessage = 'Invalid server response';
    }

    logError("$context failed (${response.statusCode}): $errorMessage");

    throw RobleException(errorMessage, statusCode: response.statusCode);
  }
}
