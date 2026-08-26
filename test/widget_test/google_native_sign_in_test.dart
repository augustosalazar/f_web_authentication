import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'package:f_web_authentication/features/auth/data/datasources/remote/i_google_id_token_source.dart';

/// Doble del SDK de Google. Apunta el nonce que recibio, que es lo que hay que
/// comprobar que llega igual a Roble.
class GoogleFalso implements IGoogleIdTokenSource {
  GoogleFalso({this.isSupported = true, this.token = 'el-id-token'});

  @override
  final bool isSupported;

  final String? token;
  String? nonceRecibido;
  int llamadas = 0;

  String? serverClientIdRecibido;

  @override
  Future<String?> idToken({required String serverClientId, String? nonce}) async {
    llamadas++;
    nonceRecibido = nonce;
    serverClientIdRecibido = serverClientId;
    return token;
  }
}

/// Roble de mentira: apunta como se pidio la sesion sin salir a la red.
class RobleFalso implements RobleApiDataBase {
  RobleFalso({this.clientIdConfigurado = 'web-client-id'});

  /// Lo que la consola de Roble tiene configurado para Google.
  final String? clientIdConfigurado;

  String? provider;
  String? idToken;
  String? nonce;
  int provederLlamadas = 0;

  @override
  Future<Map<String, dynamic>> signInWithIdToken({
    required String provider,
    required String idToken,
    String? nonce,
    bool persistSession = true,
  }) async {
    this.provider = provider;
    this.idToken = idToken;
    this.nonce = nonce;
    return {'userId': 'u1', 'email': 'ana@correo.com', 'name': 'Ana'};
  }

  @override
  Future<List<RobleProviderInfo>> listProviders() async => [
        RobleProviderInfo(
          name: 'google',
          displayName: 'Google',
          autoLinkSupported: true,
          clientId: clientIdConfigurado,
        ),
      ];

  @override
  Future<Map<String, dynamic>> signInWithProvider(
    RobleSocialProvider provider, {
    Map<String, dynamic>? extra,
    bool persistSession = true,
    Duration timeout = const Duration(minutes: 5),
    RobleSocialOpener? opener,
  }) async {
    provederLlamadas++;
    return {'userId': 'u2', 'email': 'web@correo.com', 'name': 'Web'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Google nativo', () {
    test('canjea el id_token en Roble, sin abrir navegador', () async {
      final google = GoogleFalso();
      final roble = RobleFalso();

      final user = await AuthenticationSourceServiceRoble(roble, google: google)
          .signInWithGoogle();

      expect(roble.provider, 'google');
      expect(roble.idToken, 'el-id-token');
      // El camino de ventana abriria un navegador que aqui sobra.
      expect(roble.provederLlamadas, 0);
      expect(user.email, 'ana@correo.com');
    });

    test('manda a Roble el mismo nonce que le dio a Google', () async {
      final google = GoogleFalso();
      final roble = RobleFalso();

      await AuthenticationSourceServiceRoble(roble, google: google)
          .signInWithGoogle();

      // Roble compara los dos literalmente: si no coinciden, responde 401.
      expect(google.nonceRecibido, isNotNull);
      expect(roble.nonce, google.nonceRecibido);
    });

    test('usa un nonce distinto en cada intento', () async {
      final roble = RobleFalso();
      final vistos = <String?>{};

      for (var i = 0; i < 5; i++) {
        final google = GoogleFalso();
        await AuthenticationSourceServiceRoble(roble, google: google)
            .signInWithGoogle();
        vistos.add(google.nonceRecibido);
      }

      // Repetirlo dejaria que un id_token capturado sirviera otra vez.
      expect(vistos.length, 5);
    });

    test('pide el token con el clientId que Roble tiene configurado', () async {
      final google = GoogleFalso();
      final roble = RobleFalso(clientIdConfigurado: 'el-de-la-consola');

      await AuthenticationSourceServiceRoble(roble, google: google)
          .signInWithGoogle();

      // Llevarlo en el .env de la app dejaba dos copias que podian separarse, y
      // el desajuste salia como un 401 que parecia un problema del token.
      expect(google.serverClientIdRecibido, 'el-de-la-consola');
    });

    test('sin Google configurado en Roble cae al navegador', () async {
      final google = GoogleFalso();
      final roble = RobleFalso(clientIdConfigurado: null);

      await AuthenticationSourceServiceRoble(roble, google: google)
          .signInWithGoogle();

      // Sin audiencia no se puede pedir el token, pero el flujo de navegador no
      // la necesita: la arma el servidor.
      expect(google.llamadas, 0);
      expect(roble.provederLlamadas, 1);
    });

    test('cancelar no abre el navegador como consuelo', () async {
      final google = GoogleFalso(token: null);
      final roble = RobleFalso();

      await expectLater(
        AuthenticationSourceServiceRoble(roble, google: google)
            .signInWithGoogle(),
        throwsA(isA<RobleApiAuthException>()),
      );
      // Abrir una ventana justo despues de que el usuario cerrara el selector
      // es exactamente lo que no quiere.
      expect(roble.provederLlamadas, 0);
    });

    test('en una plataforma sin soporte usa el flujo de navegador', () async {
      final google = GoogleFalso(isSupported: false);
      final roble = RobleFalso();

      final user = await AuthenticationSourceServiceRoble(roble, google: google)
          .signInWithGoogle();

      expect(google.llamadas, 0);
      expect(roble.provederLlamadas, 1);
      expect(user.email, 'web@correo.com');
    });

    test('sin origen nativo configurado sigue el flujo de navegador', () async {
      final roble = RobleFalso();

      // Es lo que pasa en web, donde no hay SDK nativo que inyectar.
      final user = await AuthenticationSourceServiceRoble(roble).signInWithGoogle();

      expect(roble.provederLlamadas, 1);
      expect(user.email, 'web@correo.com');
    });
  });
}
