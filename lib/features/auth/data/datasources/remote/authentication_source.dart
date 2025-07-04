import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSource implements IAuthenticationSource {
  final String apiKey = '1zjCuS';
  final http.Client httpClient;

  AuthenticationSource({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<bool> login(String username, String password) async {
    List<AuthenticationUser> users = [];
    var request = Uri.parse("https://retoolapi.dev/$apiKey/data")
        .resolveUri(Uri(queryParameters: {
      "format": 'json',
    }));

    var response = await httpClient.get(request);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      users = List<AuthenticationUser>.from(
          data.skip(1).map((x) => AuthenticationUser.fromJson(x)));

      var userFiltered = users.where((element) =>
          element.username == username && element.password == password);
      if (userFiltered.isNotEmpty) {
        logInfo("User found ${userFiltered.first.username}");
        return Future.value(true);
      } else {
        return Future.error('User not found');
      }
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final response = await httpClient.post(
      Uri.parse("https://retoolapi.dev/$apiKey/data"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      logError(response.body);
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> logOut() async {
    return Future.value(true);
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    return Future.value(true);
  }

  @override
  Future<bool> refreshToken() async {
    return Future.value(true);
  }

  @override
  Future<bool> forgotPassword(String email) async {
    return Future.value(true);
  }

  @override
  Future<bool> resetPassword(
      String email, String newPassword, String validationCode) async {
    return Future.value(true);
  }
}
