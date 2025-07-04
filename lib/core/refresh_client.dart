import 'package:f_web_authentication/core/local_preferences.dart';
import 'package:f_web_authentication/features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'package:http/http.dart' as http;

class RefreshClient extends http.BaseClient {
  final http.Client _inner;
  final AuthenticationSourceServiceRoble _auth;

  RefreshClient(this._inner, this._auth);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async {
    // Obtenemos el token de acceso almacenado localmente
    final prefs = LocalPreferences();
    final token = await prefs.retrieveData<String>('token');
    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    // hacemos la solicitud original
    var response = await _inner.send(req);

    // si la respuesta es 401 (no autorizado), intentamos refrescar el token
    if (response.statusCode == 401) {
      final ok = await _auth.refreshToken();
      if (ok) {
        // pull new token & retry
        final newToken = await prefs.retrieveData<String>('token');
        if (newToken != null) {
          req.headers['Authorization'] = 'Bearer $newToken';
          return _inner.send(req);
        }
      }
    }
    return response;
  }
}
