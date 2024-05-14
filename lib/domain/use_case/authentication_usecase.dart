import 'package:f_web_authentication/domain/models/authentication_user.dart';
import 'package:f_web_authentication/domain/repositories/i_repository.dart';

class AuthenticationUseCase {
  final IRepository _repository;

  AuthenticationUseCase(this._repository);

  Future<bool> login(String email, String password) async =>
      await _repository.login(email, password);

  Future<bool> signUp(String email, String password) async =>
      await _repository.signUp(AuthenticationUser(
          username: email,
          firstName: email,
          lastName: email,
          password: password));

  Future<bool> logOut() async => await _repository.logOut();
}
