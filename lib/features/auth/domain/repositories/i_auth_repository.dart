import '../models/auth_session.dart';
import '../models/authentication_user.dart';

abstract class IAuthRepository {
  /// La sesión y cada cambio que le pase. Ver [IAuthenticationSource].
  Stream<AuthSession> sessionChanges();

  Future<void> login(String email, String password);

  Future<void> signUp(String email, String password, String name, bool direct);

  Future<void> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<void> forgotPassword(String email);

  Future<AuthenticationUser> getLoggedUser();

  Future<bool> restoreSession();

  Future<bool> isGoogleEnabled();

  Future<AuthenticationUser> signInWithGoogle();
}
