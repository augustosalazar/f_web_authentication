import '../../../domain/models/authentication_user.dart';

abstract class IAuthenticationSource {
  Future<void> login(String username, String password);

  Future<void> signUp(String email, String password, String name, bool direct);

  Future<void> logOut();

  Future<bool> validate(String email, String validationCode);

  Future<bool> refreshToken();

  Future<bool> forgotPassword(String email);

  Future<bool> resetPassword(
      String email, String newPassword, String validationCode);

  Future<bool> verifyToken();

  Future<AuthenticationUser> getLoggedUser();

  Future<List<AuthenticationUser>> getUsers();
}
