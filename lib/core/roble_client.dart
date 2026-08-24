import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'i_local_preferences.dart';

class RoblePreferencesStorage implements RobleTokenStorage {
  const RoblePreferencesStorage(this._preferences);

  final ILocalPreferences _preferences;

  @override
  Future<String?> getItem(String key) => _preferences.getString(key);

  @override
  Future<void> setItem(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> removeItem(String key) => _preferences.remove(key);
}

/// Esquema propio de la app, declarado en AndroidManifest.xml. Tiene que ser el
/// mismo que el destino de retorno registrado en la consola de Roble
/// (`com.example.fwebauthentication://sso-done`).
const _callbackScheme = 'com.example.fwebauthentication';

/// Abre el proveedor en la pestana de navegador del sistema y espera el retorno.
///
/// Solo se usa fuera de web: alli el paquete trae su propia ventana emergente,
/// que no necesita plugin ni configuracion nativa.
Future<Uri> _abrirProveedorNativo(Uri loginUrl, Duration timeout) async {
  final retorno = await FlutterWebAuth2.authenticate(
    url: loginUrl.toString(),
    callbackUrlScheme: _callbackScheme,
  ).timeout(timeout);

  return Uri.parse(retorno);
}

RobleApiDataBase createRobleClient() {
  final projectId = dotenv.get('EXPO_PUBLIC_ROBLE_PROJECT_ID');
  final configuredBaseUrl = dotenv.get(
    'BASE_URL',
    fallback: 'roble-api.test-openlab.uninorte.edu.co',
  );
  final baseUrl = configuredBaseUrl.startsWith('http')
      ? configuredBaseUrl
      : 'https://$configuredBaseUrl';

  final config = RobleApiConfig.fromContract(
    baseUrl: baseUrl,
    contractId: projectId,
  );

  // Nombre del destino de retorno de esta app en la consola de Roble. Web y
  // movil vuelven a sitios distintos -una URL y un esquema propio-, asi que
  // cada plataforma pide el suyo.
  final ssoRedirect = kIsWeb
      ? dotenv.get('ROBLE_SSO_REDIRECT', fallback: 'f-web-authentication-web')
      : dotenv.get('ROBLE_SSO_REDIRECT_MOBILE',
          fallback: 'f-web-authentication-movil');

  logInfo('Roble config: $ssoRedirect');

  return RobleApiDataBase(
    config: config,
    ssoRedirect: ssoRedirect,
    socialOpener: kIsWeb ? null : _abrirProveedorNativo,
  );
}
