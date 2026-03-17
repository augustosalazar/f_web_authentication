import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:get/get.dart';

import 'package:loggy/loggy.dart';

import '../../domain/repositories/i_auth_repository.dart';

class AuthenticationController extends GetxController {
  final IAuthRepository authentication;
  final logged = false.obs;

  AuthenticationController(this.authentication);

  @override
  Future<void> onInit() async {
    super.onInit();
    logInfo('AuthenticationController initialized');
    logged.value = await validateToken();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    logInfo('AuthenticationController: Login $email $password');
    var rta = await authentication.login(email, password);
    logged.value = true;
    return true;
  }

  Future<bool> signUp(email, password, bool direct) async {
    logInfo('AuthenticationController: Sign Up $email $password');
    await authentication.signUp(
        AuthenticationUser(name: email, password: password, username: email),
        direct);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    logInfo('Controller Validate $email $validationCode');
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    logInfo('AuthenticationController: Log Out');
    logged.value = false;
    await authentication.logOut();
    logged.value = false;
  }

  Future<bool> validateToken() async {
    logInfo('validateToken: validateToken');
    var rta = await authentication.validateToken();
    return rta;
  }

  Future<void> forgotPassword(String email) async {
    logInfo('AuthenticationController: Forgot Password $email');
    await authentication.forgotPassword(email);
  }
}
