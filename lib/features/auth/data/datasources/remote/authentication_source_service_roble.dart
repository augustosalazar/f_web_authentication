import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  AuthenticationSourceServiceRoble(this._database);

  final RobleApiDataBase _database;
  Map<String, dynamic>? _currentIdentity;

  Future<void> restoreSession() async {
    _currentIdentity = null;
    await _database.restoreSession();
  }

  @override
  Future<void> login(String email, String password) async {
    await _database.login(email: email, password: password);
    final accessToken = _database.accessToken;
    final refreshToken = _database.refreshToken;

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      _database.clearTokens();
      throw const RobleApiFormatException(
        'Roble did not return a refresh token.',
      );
    }

    try {
      _currentIdentity = await _database.currentUser();
      await _authenticatedUserId();
    } catch (_) {
      _currentIdentity = null;
      _database.clearTokens();
      rethrow;
    }
  }

  Future<String> _authenticatedUserId() async {
    final identity = _currentIdentity ??= await _database.currentUser();
    final userId = identity['sub'] ?? identity['id'] ?? identity['_id'];
    if (userId == null || '$userId'.isEmpty) {
      throw const RobleApiFormatException(
        'Roble did not return an authenticated user id.',
      );
    }
    return '$userId';
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    String name,
    bool direct,
  ) async {
    if (direct) {
      logInfo('Signing up directly with Roble');
      await _database.register(email: email, password: password, name: name);
      return;
    }

    logInfo('Signing up with email verification through Roble');
    await _database.registerWithVerification(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<void> logOut() async {
    await _database.logout();
    _currentIdentity = null;
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    await _database.verifyEmail(email: email, code: validationCode);
    return true;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    await _database.forgotPassword(email: email);
    return true;
  }

  @override
  Future<bool> resetPassword(
    String email,
    String newPassword,
    String validationCode,
  ) async {
    await _database.resetPassword(
      token: validationCode,
      newPassword: newPassword,
    );
    return true;
  }

  @override
  Future<bool> verifyToken() async {
    if (_database.accessToken == null) return false;

    try {
      _currentIdentity = await _database.currentUser();
      await _authenticatedUserId();
      return true;
    } on RobleApiHttpException catch (error) {
      if (error.statusCode == 401) {
        _database.clearTokens();
        _currentIdentity = null;
        return false;
      }
      rethrow;
    } on RobleApiAuthException {
      _database.clearTokens();
      _currentIdentity = null;
      return false;
    }
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    final identity = _currentIdentity ??= await _database.currentUser();
    return AuthenticationUser.fromJson(identity);
  }
}
