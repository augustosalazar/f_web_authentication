import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthenticationController extends GetxController with UiLoggy {
  final IAuthRepository authentication;
  final logged = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final RxBool isLoading = false.obs;

  /// `true` cuando el proyecto tiene Google activo: decide si se pinta el boton.
  final RxBool googleEnabled = false.obs;

  /// `true` mientras la ventana del proveedor está abierta.
  final RxBool isSocialLoading = false.obs;

  AuthenticationController(this.authentication);

  AuthenticationUser? get loggedUser => _loggedUser.value;

  set loggedUser(AuthenticationUser? user) {
    _loggedUser.value = user;
  }

  Future<void> _initialize() async {
    loggy.debug('AuthenticationController initialized');
    logged.value = await authentication.restoreSession();
    if (logged.value) {
      loggy.info('User is logged in');
      await getLoggedUser();
    }
    await refreshGoogleAvailability();
  }

  /// Consulta si Google esta habilitado en el proyecto.
  Future<void> refreshGoogleAvailability() async {
    googleEnabled.value = await authentication.isGoogleEnabled();
    loggy.debug('Google login enabled: ${googleEnabled.value}');
  }

  /// Entra con Google. Devuelve cuando la sesión ya está iniciada.
  ///
  /// La ventana la abre el paquete y hay que pedirla desde el gesto del
  /// usuario, así que este método no puede hacer nada asíncrono antes.
  Future<void> loginWithGoogle() {
    loggy.debug('AuthenticationController: Google sign in');
    isSocialLoading.value = true;

    return authentication.signInWithGoogle().then((user) {
      _loggedUser.value = user;
      logged.value = true;
    }).whenComplete(() => isSocialLoading.value = false);
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    loggy.debug('AuthenticationController: Login $email $password');
    await authentication.login(email, password);
    await getLoggedUser();
    logged.value = true;

    return true;
  }

  Future<bool> signUp(name, email, password, bool direct) async {
    loggy.debug('AuthenticationController: Sign Up $email $password');
    await authentication.signUp(email, password, name, direct);
    return true;
  }

  Future<bool> validate(String email, String validationCode) async {
    loggy.debug('Controller Validate $email $validationCode');
    var rta = await authentication.validate(email, validationCode);
    return rta;
  }

  Future<void> logOut() async {
    loggy.debug('AuthenticationController: Log Out');
    ProductController productController = Get.find();
    logged.value = false;
    await authentication.logOut();
    await productController.clearCache();
    logged.value = false;
  }

  Future<void> forgotPassword(String email) async {
    loggy.debug('AuthenticationController: Forgot Password $email');
    await authentication.forgotPassword(email);
  }

  Future<AuthenticationUser> getLoggedUser() async {
    loggy.debug('AuthenticationController: Get Logged User');
    isLoading.value = true;
    var rta = await authentication.getLoggedUser();
    _loggedUser.value = rta;
    isLoading.value = false;
    return rta;
  }
}
