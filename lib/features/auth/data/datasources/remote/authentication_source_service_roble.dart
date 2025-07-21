import 'dart:convert';

import 'package:f_web_authentication/core/local_preferences.dart';
import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  final http.Client httpClient;
  final String baseUrl =
      'https://roble-api.test-openlab.uninorte.edu.co/auth/contract_flutterdemo_ebabe79ab0';

  AuthenticationSourceServiceRoble({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
        "password": password,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      logInfo(response.body);
      final data = jsonDecode(response.body);
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final sharedPreferences = LocalPreferences();
      sharedPreferences.storeData('token', token);
      sharedPreferences.storeData('refreshToken', refreshToken);
      logInfo("Token: $token"
          "\nRefresh Token: $refreshToken");
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> messages = body['message'];
      final String errorMessage = messages.join(" ");
      logError("Got error code ${response.statusCode}");
      return Future.error('Error $errorMessage');
    }
  }

  @override
  Future<bool> signUp(AuthenticationUser user) async {
    final response = await http.post(
      Uri.parse("$baseUrl//signup"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": user.username,
        "name": user.username,
        "password": user.password,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      logError(response.body);
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> messages = body['message'];
      final String errorMessage = messages.join(" ");
      logError("Got error code ${response.statusCode} - $errorMessage");
      return Future.error('Error $errorMessage');
    }
  }

  @override
  Future<bool> logOut() async {
    final sharedPreferences = LocalPreferences();
    final token = await sharedPreferences.retrieveData<String>('token');
    if (token == null) {
      logError("No token found, cannot log out.");
      return Future.error('No token found');
    }

    final response = await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      final sharedPreferences = LocalPreferences();
      sharedPreferences.removeData('token');
      sharedPreferences.removeData('refreshToken');
      logInfo("Logged out successfully");
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-email"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email, // Assuming validationCode is the email
        "code": validationCode,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> refreshToken() async {
    final sharedPreferences = LocalPreferences();
    final refreshToken =
        await sharedPreferences.retrieveData<String>('refreshToken');
    if (refreshToken == null) {
      logError("No refresh token found, cannot refresh.");
      return Future.error('No refresh token found');
    }

    final response = await http.post(
      Uri.parse("$baseUrl/refresh-token"),
      headers: <String, String>{
        'refreshToken': refreshToken,
      },
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final newToken = data['accessToken'];
      sharedPreferences.storeData('token', newToken);
      logInfo("Token refreshed successfully");
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }
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

  @override
  Future<bool> verifyToken() async {
    final sharedPreferences = LocalPreferences();
    final token = await sharedPreferences.retrieveData<String>('token');
    if (token == null) {
      logError("No token found, cannot verify.");
      return Future.error('No token found');
    }
    logInfo("Verifying token: $token");
    final response = await http.get(
      Uri.parse("$baseUrl/verify-token"),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    logInfo(response.statusCode);
    if (response.statusCode == 200) {
      logInfo("Token is valid");
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }
}
