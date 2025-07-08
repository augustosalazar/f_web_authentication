import 'package:get/get.dart';

import 'package:loggy/loggy.dart';

import '../../domain/use_case/authentication_usecase.dart';

class AuthenticationController extends GetxController {
  final logged = false.obs;

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    final AuthenticationUseCase authentication = Get.find();
    var rta = await authentication.login(email, password);
    logged.value = rta;
    return rta;
  }

  Future<bool> signUp(email, password) async {
    final AuthenticationUseCase authentication = Get.find();
    logInfo('Controller Sign Up');
    await authentication.signUp(email, password);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    final AuthenticationUseCase authentication = Get.find();
    logInfo('Controller Validate');
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    final AuthenticationUseCase authentication = Get.find();
    logInfo('Controller Log Out');
    await authentication.logOut();
    logged.value = false;
  }
}
