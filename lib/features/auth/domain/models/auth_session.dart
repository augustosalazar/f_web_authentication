import 'authentication_user.dart';

/// Por qué cambió la sesión.
enum AuthSessionReason {
  /// Acaba de entrar.
  signedIn,

  /// Se recuperó al arrancar una sesión que ya estaba guardada.
  restored,

  /// Se cerró a propósito.
  signedOut,

  /// Se cayó sola. A quien le pase no ha hecho nada, así que conviene
  /// decírselo en vez de devolverlo a la entrada sin explicación.
  expired,
}

/// El estado de la sesión después de cada cambio.
///
/// Es el equivalente en el dominio de lo que emite el paquete. Se traduce en la
/// fuente para que ni el repositorio ni el controlador tengan que conocer
/// `roble`, igual que con el resto de modelos.
class AuthSession {
  const AuthSession({required this.user, required this.reason});

  const AuthSession.signedOut()
      : user = null,
        reason = AuthSessionReason.signedOut;

  /// Quién entró, o `null` si no hay nadie.
  ///
  /// Puede ser `null` **con sesión iniciada**: al recuperar una sesión guardada
  /// sin verificarla no hay perfil todavía.
  final AuthenticationUser? user;

  final AuthSessionReason reason;

  bool get isSignedIn =>
      reason == AuthSessionReason.signedIn ||
      reason == AuthSessionReason.restored;

  bool get hasExpired => reason == AuthSessionReason.expired;
}
