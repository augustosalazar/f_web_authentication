import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';

class AuthenticationSourceServiceRoble
    with UiLoggy
    implements IAuthenticationSource {
  AuthenticationSourceServiceRoble(this._database);

  final RobleApiDataBase _database;

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
      loggy.debug('Signing up directly with Roble');
      await _database.register(email: email, password: password, name: name);
      return;
    }

    loggy.debug('Signing up with email verification through Roble');
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
  Future<bool> restoreSession() async {
    try {
      if (await _database.restoreSession()) {
        loggy.debug('Session restored successfully');
        return true;
      }
      return false;
    } on RobleApiHttpException catch (error) {
      if (error.statusCode == 401) {
        loggy.error('Session is not valid');
        return false;
      }
      rethrow;
    } on RobleApiAuthException {
      loggy.error('Authentication error occurred while restoring session');
      return false;
    }
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    return AuthenticationUser.fromJson(await _database.currentUser());
  }
}
