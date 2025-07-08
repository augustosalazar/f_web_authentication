import '../models/authentication_user.dart';
import '../repositories/i_auth_repository.dart';

class AuthenticationUseCase {
  final IAuthRepository _repository;

  AuthenticationUseCase(this._repository);

  Future<bool> login(String email, String password) async =>
      await _repository.login(email, password);

  Future<bool> signUp(String email, String password) async =>
      await _repository.signUp(AuthenticationUser(
          username: email,
          firstName: email,
          lastName: email,
          password: password));

  Future<bool> validate(String email, String validationCode) async =>
      await _repository.validate(email, validationCode);

  Future<bool> logOut() async => await _repository.logOut();
}
