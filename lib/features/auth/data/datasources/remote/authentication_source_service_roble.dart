import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceServiceRoble implements IAuthenticationSource {
  AuthenticationSourceServiceRoble(this._database);

  final RobleApiDataBase _database;

  Future<void> restoreSession() async {
    await _database.restoreSession();
  }

  @override
  Future<AuthenticationUser> login(String email, String password) async {
    Map<String, dynamic> currentIdentity = await _database.login(
      email: email,
      password: password,
    );
    return AuthenticationUser.fromJson(currentIdentity);
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
    try {
      if (await _database.restoreSession()) {
        return true;
      }
      return false;
    } on RobleApiHttpException catch (error) {
      if (error.statusCode == 401) {
        _database.clearTokens();

        return false;
      }
      rethrow;
    } on RobleApiAuthException {
      _database.clearTokens();

      return false;
    }
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    return AuthenticationUser.fromJson(await _database.currentUser());
  }
}
