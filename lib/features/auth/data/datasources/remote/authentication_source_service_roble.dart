import 'dart:convert';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/i_local_preferences.dart';
import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  final http.Client httpClient;
  final contract =
      dotenv.get('EXPO_PUBLIC_ROBLE_PROJECT_ID', fallback: "NO_ENV");
  late final String baseUrl =
      'https://roble-api.openlab.uninorte.edu.co/auth/$contract';

  AuthenticationSourceServiceRoble({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<AuthenticationUser> login(String email, String password) async {
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
      final ILocalPreferences sharedPreferences = Get.find();
      await sharedPreferences.setString('token', token);
      await sharedPreferences.setString('refreshToken', refreshToken);
      logInfo("Token: $token"
          "\nRefresh Token: $refreshToken");

      AuthenticationUser user = AuthenticationUser(
        username: data['user']['email'],
        password: password,
        name: data['user']['name'],
        id: data['user']['id'],
      );

      return Future.value(user);
    } else {
      final Map<String, dynamic> body = json.decode(response.body);
      final String errorMessage = body['message'];
      logError(
          "Login endpoint got error code ${response.statusCode}: $errorMessage");
      return Future.error('Error $errorMessage');
    }
  }

  @override
  Future<bool> signUp(AuthenticationUser user, bool direct) async {
    late final String endpoint;
    if (direct) {
      logInfo("Signing up directly");
      endpoint = "$baseUrl/signup-direct";
    } else {
      logInfo("Signing up with validation");
      endpoint = "$baseUrl/signup";
    }
    final response = await http.post(
      Uri.parse(endpoint),
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
      AuthenticationUser loggedUser = await login(user.username, user.password);
      await addUser(loggedUser);
      return Future.value(true);
    } else {
      logError(response.body);
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> messages = body['message'];
      final String errorMessage = messages.join(" ");
      logError(
          "signUp endpoint got error code ${response.statusCode} - $errorMessage");
      return Future.error('Error $errorMessage');
    }
  }

  @override
  Future<bool> logOut() async {
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');
    if (token == null) {
      logError("No token found, cannot log out.");
      return Future.error('No token found');
    }

    final response = await httpClient.post(
      Uri.parse("$baseUrl/logout"),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      final ILocalPreferences sharedPreferences = Get.find();
      await sharedPreferences.remove('token');
      await sharedPreferences.remove('refreshToken');
      logInfo("Logged out successfully");
      return Future.value(true);
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "logout endpoint got error code ${response.statusCode} $errorMessage for token: $token");
      return Future.error('Error code $errorMessage');
    }
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    final response = await httpClient.post(
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
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "verifyEmail endpoint got error code ${response.statusCode} $errorMessage for email: $email");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> refreshToken() async {
    final ILocalPreferences sharedPreferences = Get.find();
    final refreshToken = await sharedPreferences.getString('refreshToken');
    if (refreshToken == null) {
      logError("No refresh token found, cannot refresh.");
      return Future.value(false);
    }

    final response = await http.post(
      Uri.parse("$baseUrl/refresh-token"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'refreshToken': refreshToken,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final newToken = data['accessToken'];
      await sharedPreferences.setString('token', newToken);
      logInfo("Token refreshed successfully");
      return Future.value(true);
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "refreshToken endpoint got error code ${response.statusCode} $errorMessage for refreshToken: $refreshToken");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    final response = await httpClient.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "forgotPassword endpoint got error code ${response.statusCode} $errorMessage for email: $email");
      return Future.error('Error code ${response.statusCode}');
    }
  }

  @override
  Future<bool> resetPassword(
      String email, String newPassword, String validationCode) async {
    return Future.value(true);
  }

  @override
  Future<bool> verifyToken() async {
    final ILocalPreferences sharedPreferences = Get.find();
    final token = await sharedPreferences.getString('token');
    if (token == null) {
      logError("No token found, cannot verify.");
      return Future.value(false);
    }
    //logInfo("Verifying token: $token");
    final response = await httpClient.get(
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
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "verifyToken endpoint got error code ${response.statusCode} $errorMessage for token: $token");
      return Future.value(false);
    }
  }

  Future<bool> addUser(AuthenticationUser user) async {
    logInfo("Web service, Adding user");
    final String baseUrl = 'roble-api.openlab.uninorte.edu.co';
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
      "tableName": 'Users',
      "records": [
        user.toJson(),
      ],
    });

    final response = await httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode == 201) {
      return Future.value(true);
    } else {
      final Map<String, dynamic> body = json.decode(response.body);
      final String errorMessage = body['message'];
      logError("addUser got error code ${response.statusCode}: $errorMessage");
      return Future.error('AddUser error code ${response.statusCode}');
    }
  }
}
