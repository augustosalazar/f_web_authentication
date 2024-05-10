import 'package:f_web_authentication/domain/repositories/i_repository.dart';
import 'package:get/get.dart';

class AuthenticationUseCase {
  final IRepository _repository = Get.find();

  Future<bool> login(String email, String password) async =>
      await _repository.login(email, password);

  Future<bool> signUp(String email, String password) async =>
      await _repository.signUp(email, password);

  Future<bool> logOut() async => await _repository.logOut();
}
