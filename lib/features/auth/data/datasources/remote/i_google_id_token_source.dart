/// Obtiene un `id_token` de Google desde el SDK nativo.
///
/// Vive detras de su propia interfaz porque no habla con Roble: su unico
/// trabajo es conseguir la credencial que Roble luego valida. Asi el origen de
/// Roble no arrastra el SDK de Google, y en pruebas se sustituye por un doble
/// sin tocar nada nativo.
abstract class IGoogleIdTokenSource {
  /// `true` si esta plataforma puede pedir el token de forma nativa.
  ///
  /// En web es `false`: alli el flujo sigue siendo el del navegador, que ya
  /// funciona sin plugin.
  bool get isSupported;

  /// Abre el selector de cuentas de Google y devuelve el `id_token`.
  ///
  /// Devuelve `null` si el usuario cancela, que no es un error: la interfaz
  /// simplemente vuelve a su estado anterior.
  ///
  /// [serverClientId] es el Client ID **web** con el que el proyecto tiene
  /// configurado Google en la consola de Roble. Lo pide quien llama, en vez de
  /// venir fijado aqui, para que la app no lleve una segunda copia: Roble ya lo
  /// devuelve en `listProviders`, y el token se emite para esa audiencia, que
  /// es justo la que el servidor comprueba al validarlo.
  ///
  /// [nonce] viaja hasta Google y vuelve dentro del token; quien lo llame debe
  /// mandarle a Roble el mismo valor para que compruebe que coinciden.
  Future<String?> idToken({required String serverClientId, String? nonce});
}
