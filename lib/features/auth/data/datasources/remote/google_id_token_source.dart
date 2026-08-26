import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loggy/loggy.dart';

import 'i_google_id_token_source.dart';

/// Implementacion con `google_sign_in`, el SDK nativo de Google.
///
/// El Client ID **web** no vive aqui: lo trae Roble en `listProviders`, asi que
/// la consola es el unico sitio donde se configura el proveedor. Antes habia
/// que repetirlo en el `.env` de la app, y las dos copias podian separarse: el
/// token se emitia para una audiencia y Roble esperaba otra, lo que sale como
/// un 401 que parece un problema del token y no de la configuracion.
class GoogleIdTokenSource with UiLoggy implements IGoogleIdTokenSource {
  GoogleIdTokenSource({this.clientId});

  /// Client ID de iOS. En Android se deja `null`: alli lo resuelve el propio
  /// SDK a partir de la firma del paquete. Roble no guarda este, que es por
  /// plataforma, asi que es lo unico de Google que queda en la app.
  final String? clientId;

  bool _initialized = false;

  @override
  bool get isSupported {
    if (kIsWeb) return false;

    try {
      return GoogleSignIn.instance.supportsAuthenticate();
    } on UnimplementedError {
      // Linux y Windows no tienen implementacion del plugin, y ahi
      // supportsAuthenticate lanza en vez de devolver false. Sin este catch el
      // boton reventaria en escritorio en lugar de caer al flujo de navegador,
      // que si funciona.
      return false;
    }
  }

  /// `initialize` es idempotente, pero el nonce y el servidor solo se pueden
  /// pasar aqui, asi que se rehace en cada intento.
  Future<void> _initialize(String serverClientId, String? nonce) async {
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
      nonce: nonce,
    );
    _initialized = true;
  }

  @override
  Future<String?> idToken({required String serverClientId, String? nonce}) async {
    if (!isSupported) return null;

    await _initialize(serverClientId, nonce);

    try {
      // `authenticate` es el que abre el selector de cuentas. El SDK tambien
      // trae `attemptLightweightAuthentication`, que es silencioso y devuelve
      // null si no hay una sesion previa: sirve para entrar solo al arrancar,
      // no para responder a un boton.
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;

      if (token == null) {
        loggy.warning('Google no devolvio id_token');
        return null;
      }
      return token;
    } on GoogleSignInException catch (error) {
      // Cancelar no es un fallo: el usuario cerro el selector y la interfaz
      // solo tiene que volver a como estaba.
      if (error.code == GoogleSignInExceptionCode.canceled) {
        loggy.debug('El usuario cancelo el inicio de sesion con Google');
        return null;
      }
      rethrow;
    }
  }

  /// Cierra la sesion del SDK, para que el proximo intento vuelva a preguntar
  /// por la cuenta en vez de reutilizar la anterior en silencio.
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
