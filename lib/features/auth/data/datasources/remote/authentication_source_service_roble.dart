import 'dart:convert';

import 'package:f_web_authentication/core/roble_exception.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/i_local_preferences.dart';
import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  final http.Client httpClient;
  final http.Client rawHttpClient;
  final contract =
      dotenv.get('EXPO_PUBLIC_ROBLE_PROJECT_ID', fallback: "NO_ENV");
  late final String baseUrl =
      'https://roble-api.openlab.uninorte.edu.co/auth/$contract';

  AuthenticationSourceServiceRoble({
    http.Client? client,
    http.Client? rawClient,
  })  : httpClient = client ?? http.Client(),
        rawHttpClient = rawClient ?? http.Client();

  ILocalPreferences get _prefs => Get.find();

  @override
  Future<void> login(String email, String password) async {
    final response = await httpClient.post(
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
      await _prefs.setString('token', token);
      await _prefs.setString('refreshToken', refreshToken);
      await _prefs.setString('userId', data['user']['id']);
      logInfo("Token: $token"
          "\nRefresh Token: $refreshToken");
      return;
    } else {
      String errorMessage;
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['message'] ?? 'Unknown error';
      } catch (_) {
        errorMessage = 'Invalid server response';
      }
      logError(
          "Login endpoint got error code ${response.statusCode}: $errorMessage");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<void> signUp(
      String email, String password, String name, bool direct) async {
    late final String endpoint;
    if (direct) {
      logInfo("Signing up directly");
      endpoint = "$baseUrl/signup-direct";
    } else {
      logInfo("Signing up with validation");
      endpoint = "$baseUrl/signup";
    }
    final response = await httpClient.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": email,
        "name": name,
        "password": password,
      }),
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      await login(email, password);
      await addUser(email, name);
      return;
    } else {
      logError(response.body);
      String errorMessage;
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['message'] ?? 'Unknown error';
      } catch (_) {
        errorMessage = 'Invalid server response';
      }
      logError(
          "signUp endpoint got error code ${response.statusCode} - $errorMessage");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<bool> logOut() async {
    final token = await _prefs.getString('token');
    if (token == null) {
      logError("No token found, cannot log out.");
      throw Exception('No token found');
    }

    final response = await httpClient.post(
      Uri.parse("$baseUrl/logout"),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    logInfo(response.statusCode);
    if (response.statusCode == 201) {
      await _prefs.remove('token');
      await _prefs.remove('refreshToken');
      await _prefs.remove('userId');
      logInfo("Logged out successfully");
      return true;
    } else {
      String errorMessage;
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['message'] ?? 'Unknown error';
      } catch (_) {
        errorMessage = 'Invalid server response';
      }
      logError(
          "logout endpoint got error code ${response.statusCode} $errorMessage for token: $token");
      throw RobleException(errorMessage, statusCode: response.statusCode);
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
      return true;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "verifyEmail endpoint got error code ${response.statusCode} $errorMessage for email: $email");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<bool> refreshToken() async {
    final refreshToken = await _prefs.getString('refreshToken');
    if (refreshToken == null) {
      logError("No refresh token found, cannot refresh.");
      throw RobleException('No refresh token found', statusCode: 400);
    }

    final response = await rawHttpClient.post(
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
      await _prefs.setString('token', newToken);
      logInfo("Token refreshed successfully");
      return true;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "refreshToken endpoint got error code ${response.statusCode} $errorMessage for refreshToken: $refreshToken");
      throw RobleException(errorMessage, statusCode: response.statusCode);
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
      return true;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "forgotPassword endpoint got error code ${response.statusCode} $errorMessage for email: $email");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<bool> resetPassword(
      String email, String newPassword, String validationCode) async {
    return true;
  }

  @override
  Future<bool> verifyToken() async {
    final token = await _prefs.getString('token');
    if (token == null) {
      logError("No token found, cannot verify.");
      return false;
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
      return true;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError(
          "verifyToken endpoint got error code ${response.statusCode} $errorMessage for token: $token");
      return false;
    }
  }

  Future<bool> addUser(String email, String name) async {
    logInfo("Web service, Adding user");
    final String baseUrl = 'roble-api.openlab.uninorte.edu.co';
    final uri = Uri.https(
      baseUrl,
      '/database/$contract/insert',
    );
    final token = await _prefs.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "tableName": 'Users',
      "records": [
        {
          "userId": await _prefs.getString('userId'),
          "email": email,
          "name": name,
        }
      ],
    });

    final response = await httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode == 201) {
      return true;
    } else {
      final Map<String, dynamic> body = json.decode(response.body);
      final String errorMessage = body['message'];
      logError("addUser got error code ${response.statusCode}: $errorMessage");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    final String baseUrl = 'roble-api.openlab.uninorte.edu.co';

    final userId = await _prefs.getString('userId');

    var uri = Uri.https(
      baseUrl,
      '/database/$contract/read',
      {'tableName': 'Users', 'userId': userId},
    );

    final token = await _prefs.getString('token');
    var response =
        await httpClient.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> decodedJson = jsonDecode(response.body);

      //logInfo(decodedJson);

      List<AuthenticationUser> users = List<AuthenticationUser>.from(
          decodedJson.map((x) => AuthenticationUser.fromJson(x)));

      return users.first;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError("Got error code ${response.statusCode}: $errorMessage");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }

  @override
  Future<List<AuthenticationUser>> getUsers() async {
    final String baseUrl = 'roble-api.openlab.uninorte.edu.co';

    var uri = Uri.https(
      baseUrl,
      '/database/$contract/read',
      {'tableName': 'Users'},
    );

    final token = await _prefs.getString('token');
    var response =
        await httpClient.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      List<dynamic> decodedJson = jsonDecode(response.body);

      //logInfo(decodedJson);

      List<AuthenticationUser> users = List<AuthenticationUser>.from(
          decodedJson.map((x) => AuthenticationUser.fromJson(x)));

      return users;
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final String errorMessage = errorBody['message'];
      logError("Got error code ${response.statusCode}: $errorMessage");
      throw RobleException(errorMessage, statusCode: response.statusCode);
    }
  }
}
