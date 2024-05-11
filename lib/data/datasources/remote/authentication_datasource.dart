import 'dart:convert';
import 'package:f_web_authentication/domain/models/authentication_user.dart';
import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

class AuthenticationDatatasource {
  final String apiKey = 'mYhsRv';
  final http.Client httpClient;

  AuthenticationDatatasource({http.Client? client})
      : httpClient = client ?? http.Client();

  Future<bool> login(String email, String password) async {
    return Future.value(true);
  }

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
      return Future.value(false);
    }
  }

  Future<bool> logOut() async {
    return Future.value(true);
  }
}
