import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:get/get.dart';

import 'package:loggy/loggy.dart';

import '../../domain/repositories/i_auth_repository.dart';

class AuthenticationController extends GetxController {
  final IAuthRepository authentication;
  final logged = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final RxBool isLoading = false.obs;

  AuthenticationController(this.authentication);

  AuthenticationUser? get loggedUser => _loggedUser.value;

  set loggedUser(AuthenticationUser? user) {
    _loggedUser.value = user;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    logInfo('AuthenticationController initialized');
    logged.value = await validateToken();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    logInfo('AuthenticationController: Login $email $password');
    await authentication.login(email, password);
    await getLoggedUser();
    logged.value = true;

    return true;
  }

  Future<bool> signUp(name, email, password, bool direct) async {
    logInfo('AuthenticationController: Sign Up $email $password');
    await authentication.signUp(email, password, name, direct);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    logInfo('Controller Validate $email $validationCode');
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    logInfo('AuthenticationController: Log Out');
    ProductController productController = Get.find();
    logged.value = false;
    await authentication.logOut();
    await productController.clearCache();
    logged.value = false;
  }

  Future<bool> validateToken() async {
    logInfo('validateToken: validateToken');
    var rta = await authentication.validateToken();
    if (rta) {
      await getLoggedUser();
    }
    return rta;
  }

  Future<void> forgotPassword(String email) async {
    logInfo('AuthenticationController: Forgot Password $email');
    await authentication.forgotPassword(email);
  }

  Future<AuthenticationUser> getLoggedUser() async {
    logInfo('AuthenticationController: Get Logged User');
    isLoading.value = true;
    var rta = await authentication.getLoggedUser();
    _loggedUser.value = rta;
    isLoading.value = false;
    return rta;
  }

  Future<List<AuthenticationUser>> getUsers() async {
    logInfo('AuthenticationController: Get Users');
    var rta = await authentication.getUsers();
    return rta;
  }
}
