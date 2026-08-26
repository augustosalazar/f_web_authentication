import 'dart:convert';
import 'dart:math';

import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/authentication_user.dart';
import 'i_authentication_source.dart';
import 'i_google_id_token_source.dart';

class AuthenticationSourceServiceRoble
    with UiLoggy
    implements IAuthenticationSource {
  AuthenticationSourceServiceRoble(this._database,
      {IGoogleIdTokenSource? google})
      : _google = google;

  final RobleApiDataBase _database;

  /// Origen del `id_token` nativo. `null`, o no soportado, deja el flujo del
  /// navegador, que es lo que se usa en web.
  final IGoogleIdTokenSource? _google;

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

  @override
  Future<bool> isGoogleEnabled() async {
    return true;
  }

  @override
  Future<AuthenticationUser> signInWithGoogle() async {
    final google = _google;

    // Camino nativo: el SDK devuelve el id_token y Roble lo valida, sin abrir
    // navegador, sin esquema de URL propio y sin retorno que enrutar. Si esta
    // plataforma no lo soporta se sigue por el flujo de ventana de siempre.
    if (google != null && google.isSupported) {
      // El Client ID sale de la consola de Roble, no del build de la app: es la
      // audiencia para la que Google emite el token y la que el servidor
      // comprueba despues, asi que teniendolo de aqui no pueden discrepar.
      final serverClientId = await _googleServerClientId();

      if (serverClientId == null) {
        // Google no esta configurado en el proyecto, o el servidor es anterior
        // a que el endpoint devolviera el clientId. El flujo de navegador no
        // necesita saberlo, asi que se intenta por ahi.
        loggy.debug('Sin clientId de Google en Roble: se usa el navegador');
      } else {
        return _signInWithGoogleNatively(google, serverClientId);
      }
    }

    loggy.debug('Google por navegador');
    final profile =
        await _database.signInWithProvider(RobleSocialProvider.google);
    return AuthenticationUser.fromJson(profile);
  }

  /// El Client ID web que el proyecto tiene configurado, o `null` si no hay.
  Future<String?> _googleServerClientId() async {
    for (final provider in await _database.listProviders()) {
      if (provider.name == 'google') return provider.clientId;
    }
    return null;
  }

  Future<AuthenticationUser> _signInWithGoogleNatively(
    IGoogleIdTokenSource google,
    String serverClientId,
  ) async {
    final nonce = _nonce();
    final idToken = await google.idToken(
      serverClientId: serverClientId,
      nonce: nonce,
    );

    if (idToken == null) {
      // Cancelado. Devolver el flujo del navegador aqui abriria una ventana
      // que el usuario acaba de rechazar.
      throw const RobleApiAuthException(
          'Inicio de sesion con Google cancelado.');
    }

    loggy.debug('Google nativo: canjeando id_token en Roble');
    final profile = await _database.signInWithIdToken(
      provider: 'google',
      idToken: idToken,
      nonce: nonce,
    );
    return AuthenticationUser.fromJson(profile);
  }

  /// Valor de un solo uso que ata el token a esta peticion.
  ///
  /// Viaja a Google, vuelve dentro del token y Roble comprueba que sea el
  /// mismo, que es lo que impide reutilizar un id_token capturado.
  String _nonce() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
