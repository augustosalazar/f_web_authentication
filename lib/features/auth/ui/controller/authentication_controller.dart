import 'package:get/get.dart';

import 'package:loggy/loggy.dart';

import '../../domain/use_case/authentication_usecase.dart';

class AuthenticationController extends GetxController with UiLoggy {
  final AuthenticationUseCase authentication;
  final logged = false.obs;

  AuthenticationController(this.authentication);

  @override
  Future<void> onInit() async {
    super.onInit();
    loggy.info('AuthenticationController initialized');
    logged.value = await validateToken();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    loggy.info('AuthenticationController: Login $email $password');
    var rta = await authentication.login(email, password);
    logged.value = rta;
    return rta;
  }

  Future<bool> signUp(email, password) async {
    loggy.info('AuthenticationController: Sign Up $email $password');
    await authentication.signUp(email, password);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    loggy.info('Controller Validate $email $validationCode');
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    loggy.info('AuthenticationController: Log Out');
    await authentication.logOut();
    logged.value = false;
  }

  Future<bool> validateToken() async {
    loggy.info('validateToken: validateToken');
    var rta = await authentication.validateToken();
    return rta;
  }

  Future<void> forgotPassword(String email) async {
    loggy.info('AuthenticationController: Forgot Password $email');
    await authentication.forgotPassword(email);
  }
}
