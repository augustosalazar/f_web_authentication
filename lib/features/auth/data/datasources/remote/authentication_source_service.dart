import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceService implements IAuthenticationSource {
  final http.Client httpClient;
  final String appName = 'movil202510';
  final String contractKey = 'e83b7ac8-bdad-4bb8-a532-6aaa5fddefa4';
  final String baseUrl = 'https://authuserver.openlab.uninorte.edu.co';
  String? token;

  AuthenticationSourceService({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "app_name": appName,
        "username": email,
        "password": password,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 200) {
      logInfo(response.body);
      final data = jsonDecode(response.body);
      token = data['access_token'];
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register?contract_key=$contractKey"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "username": user.username,
        "first_name": user.username,
        "last_name": user.username,
        "password": user.password,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 200) {
      //logInfo(response.body);
      return Future.value(true);
    } else {
      logInfo(response.body);
      logError("Got error code ${response.statusCode}");
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
}
