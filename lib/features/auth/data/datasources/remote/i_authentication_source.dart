import '../../../domain/models/auth_session.dart';
import '../../../domain/models/authentication_user.dart';

abstract class IAuthenticationSource {
  /// La sesión y cada cambio que le pase.
  ///
  /// Quien se suscribe recibe primero el estado actual, así que no hace falta
  /// preguntar aparte si hay sesión al arrancar.
  Stream<AuthSession> sessionChanges();

  Future<AuthenticationUser> login(String username, String password);

  Future<void> signUp(String email, String password, String name, bool direct);

  Future<void> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> forgotPassword(String email);

  Future<bool> resetPassword(
      String email, String newPassword, String validationCode);

  Future<AuthenticationUser> getLoggedUser();

  Future<bool> restoreSession();

  /// `true` si el proyecto tiene Google configurado y activo.
  Future<bool> isGoogleEnabled();

  /// Abre Google en una ventana y devuelve el usuario ya autenticado.
  Future<AuthenticationUser> signInWithGoogle();
}
