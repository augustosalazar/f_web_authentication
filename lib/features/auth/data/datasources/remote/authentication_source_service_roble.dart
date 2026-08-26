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
  // El paquete ya devuelve false ante un token revocado o caducado; solo deja
  // subir los fallos de red, que si merecen distinguirse de «no hay sesion».
  Future<bool> restoreSession() => _database.restoreSession();

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    return AuthenticationUser.fromJson(await _database.currentUser());
  }

  @override
  Future<bool> isGoogleEnabled() async {
    return true;
  }

  @override
  Future<AuthenticationUser> signInWithGoogle() async {
    // El paquete decide el camino: SDK nativo donde lo haya, ventana de
    // navegador donde no. La app solo traduce el perfil a su modelo.
    return AuthenticationUser.fromJson(await _database.signInWithGoogle());
  }
}
