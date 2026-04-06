import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  final String baseUrl = 'roble-api.openlab.uninorte.edu.co';

  // ✅ Getter para URL de autenticación (usa Uri.parse)
  String get authBaseUrl => 'https://$baseUrl/auth/$contract';

  AuthenticationSourceServiceRoble({
    http.Client? client,
    http.Client? rawClient,
  })  : httpClient = client ?? http.Client(),
        rawHttpClient = rawClient ?? http.Client();

  ILocalPreferences get _prefs => Get.find();

  @override
  Future<void> login(String email, String password) async {
    return _executeHttpCall(() async {
      final response = await httpClient.post(
        Uri.parse("$authBaseUrl/login"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "email": email,
          "password": password,
        }),
      );

      // logInfo(response.statusCode);
      if (response.statusCode == 201) {
        // logInfo(response.body);
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        final refreshToken = data['refreshToken'];
        await _prefs.setString('token', token);
        await _prefs.setString('refreshToken', refreshToken);
        await _prefs.setString('userId', data['user']['id']);
        //logInfo("Token: $token\nRefresh Token: $refreshToken");
        return;
      } else {
        _handleError(response, "login");
      }
    }, 'login');
  }

  @override
  Future<void> signUp(
      String email, String password, String name, bool direct) async {
    return _executeHttpCall(() async {
      late final String endpoint;
      if (direct) {
        logInfo("Signing up directly");
        endpoint = "$authBaseUrl/signup-direct";
      } else {
        logInfo("Signing up with validation");
        endpoint = "$authBaseUrl/signup";
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

      // logInfo(response.statusCode);
      if (response.statusCode == 201) {
        await login(email, password);
        await addUser(email, name);
        return;
      } else {
        logError(response.body);
        _handleError(response, "signUp");
      }
    }, 'signUp');
  }

  @override
  Future<bool> logOut() async {
    return _executeHttpCall(() async {
      final token = await _prefs.getString('token');
      if (token == null) {
        logError("No token found, cannot log out.");
        throw RobleException('No token found', statusCode: 401);
      }

      final response = await httpClient.post(
        Uri.parse("$authBaseUrl/logout"),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      //logInfo(response.statusCode);
      if (response.statusCode == 201) {
        await _prefs.remove('token');
        await _prefs.remove('refreshToken');
        await _prefs.remove('userId');
        logInfo("Logged out successfully");
        return true;
      } else {
        _handleError(response, "logout");
      }
    }, 'logOut');
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    return _executeHttpCall(() async {
      final response = await httpClient.post(
        Uri.parse("$authBaseUrl/verify-email"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "email": email,
          "code": validationCode,
        }),
      );

      //logInfo(response.statusCode);
      if (response.statusCode == 201) {
        return true;
      } else {
        _handleError(response, "validate");
      }
    }, 'validate');
  }

  @override
  Future<bool> refreshToken() async {
    return _executeHttpCall(() async {
      final refreshToken = await _prefs.getString('refreshToken');
      if (refreshToken == null) {
        logError("No refresh token found, cannot refresh.");
        throw RobleException('No refresh token found', statusCode: 400);
      }

      final response = await rawHttpClient.post(
        Uri.parse("$authBaseUrl/refresh-token"),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'refreshToken': refreshToken,
        }),
      );

      //logInfo(response.statusCode);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];
        await _prefs.setString('token', newToken);
        logInfo("Token refreshed successfully");
        return true;
      } else {
        _handleError(response, "refreshToken");
      }
    }, 'refreshToken');
  }

  @override
  Future<bool> forgotPassword(String email) async {
    return _executeHttpCall(() async {
      final response = await httpClient.post(
        Uri.parse("$authBaseUrl/forgot-password"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "email": email,
        }),
      );

      //logInfo(response.statusCode);
      if (response.statusCode == 201) {
        return true;
      } else {
        _handleError(response, "forgotPassword");
      }
    }, 'forgotPassword');
  }

  @override
  Future<bool> resetPassword(
      String email, String newPassword, String validationCode) async {
    return _executeHttpCall(() async {
      final response = await httpClient.post(
        Uri.parse("$authBaseUrl/reset-password"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          "token": validationCode,
          "newPassword": newPassword,
        }),
      );

      //logInfo(response.statusCode);
      if (response.statusCode == 201) {
        return true;
      } else {
        _handleError(response, "forgotPassword");
      }
    }, 'forgotPassword');
  }

  @override
  Future<bool> verifyToken() async {
    return _executeHttpCall(() async {
      final token = await _prefs.getString('token');
      if (token == null) {
        logError("No token found, cannot verify.");
        return false;
      }

      final response = await httpClient.get(
        Uri.parse("$authBaseUrl/verify-token"),
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
            "verifyToken endpoint got error code ${response.statusCode} $errorMessage");
        return false;
      }
    }, 'verifyToken');
  }

  // ========================================
  // ✅ USER MANAGEMENT METHODS
  // ========================================

  Future<bool> addUser(String email, String name) async {
    return _executeHttpCall(() async {
      logInfo("Web service, Adding user");
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
        _handleError(response, "addUser");
      }
    }, 'addUser');
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    return _executeHttpCall(() async {
      final userId = await _prefs.getString('userId');

      var uri = Uri.https(
        baseUrl,
        '/database/$contract/read',
        {'tableName': 'Users', 'userId': userId},
      );
      final token = await _prefs.getString('token');
      var response = await httpClient
          .get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);

        List<AuthenticationUser> users = List<AuthenticationUser>.from(
            decodedJson.map((x) => AuthenticationUser.fromJson(x)));

        return users.first;
      } else {
        _handleError(response, "getLoggedUser");
      }
    }, 'getLoggedUser');
  }

  @override
  Future<List<AuthenticationUser>> getUsers() async {
    return _executeHttpCall(() async {
      var uri = Uri.https(
        baseUrl,
        '/database/$contract/read',
        {'tableName': 'Users'},
      );

      final token = await _prefs.getString('token');
      var response = await httpClient
          .get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);

        List<AuthenticationUser> users = List<AuthenticationUser>.from(
            decodedJson.map((x) => AuthenticationUser.fromJson(x)));

        return users;
      } else {
        _handleError(response, "getUsers");
      }
    }, 'getUsers');
  }

  /// Ejecuta llamadas HTTP con manejo centralizado de errores
  Future<T> _executeHttpCall<T>(
    Future<T> Function() call,
    String context,
  ) async {
    try {
      return await call();
    } on TimeoutException catch (e) {
      logError('$context timeout: ${e.message}');
      throw RobleException('Connection timeout: ${e.message}', statusCode: 408);
    } on SocketException catch (e) {
      logError('$context no internet: ${e.message}');
      throw RobleException('No internet connection: ${e.message}',
          statusCode: 503);
    } on http.ClientException catch (e) {
      logError('$context client error: ${e.message}');
      throw RobleException('Network error: ${e.message}', statusCode: 500);
    } on FormatException catch (e) {
      logError('$context format error: ${e.message}');
      throw RobleException('Invalid response format: ${e.message}',
          statusCode: 500);
    } on RobleException {
      // Re-lanzar RobleException sin envolver
      rethrow;
    } catch (e) {
      logError('$context unexpected error: $e');
      throw RobleException('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Helper para manejar errores de respuesta HTTP
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
