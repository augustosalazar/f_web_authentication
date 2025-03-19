import '../models/authentication_user.dart';

abstract class IAuthRepository {
  Future<bool> login(String email, String password);

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();
}
