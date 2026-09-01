import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart';
import '../../domain/models/authentication_user.dart';
import '../../domain/repositories/i_auth_repository.dart';

/// La sesión: quién entró y si sigue dentro.
///
/// Los métodos no lanzan. Devuelven `true` o `false` y, cuando algo falla,
/// dejan el motivo en [error] —lo mismo que hacen los controladores de
/// productos, chat y archivos—, así que la pantalla decide qué enseñar sin
/// tener que envolver cada llamada en un `try`.
class AuthenticationController extends GetxController with UiLoggy {
  final IAuthRepository authentication;
  final logged = false.obs;
  final _loggedUser = Rxn<AuthenticationUser>();
  final RxBool isLoading = false.obs;

  /// Vacío mientras todo va bien.
  final RxString error = ''.obs;

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
    try {
      logged.value = await authentication.restoreSession();
      if (logged.value) {
        loggy.info('User is logged in');
        await getLoggedUser();
      }
      await refreshGoogleAvailability();
    } catch (e) {
      // Arrancar sin sesión es normal —un token caducado, sin red—, así que
      // esto no se le enseña a nadie: se queda en la pantalla de entrada.
      loggy.debug('No se pudo restaurar la sesión: $e');
      logged.value = false;
    }
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
  Future<bool> loginWithGoogle() {
    loggy.debug('AuthenticationController: Google sign in');
    isSocialLoading.value = true;
    error.value = '';

    return authentication.signInWithGoogle().then<bool>((user) {
      _loggedUser.value = user;
      logged.value = true;
      return true;
    }).catchError((Object e) {
      loggy.error('Error during Google login: $e');
      error.value = errorMessage(e);
      return false;
    }).whenComplete(() => isSocialLoading.value = false);
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    loggy.debug('AuthenticationController: Login $email');
    error.value = '';
    try {
      await authentication.login(email, password);
      await getLoggedUser();
      logged.value = true;
      return true;
    } catch (e) {
      loggy.error('Login error $e');
      error.value = errorMessage(e);
      return false;
    }
  }

  Future<bool> signUp(name, email, password, bool direct) async {
    loggy.debug('AuthenticationController: Sign Up $email');
    error.value = '';
    try {
      await authentication.signUp(email, password, name, direct);
      return true;
    } catch (e) {
      loggy.error('SignUp error $e');
      error.value = errorMessage(e);
      return false;
    }
  }

  Future<bool> validate(String email, String validationCode) async {
    loggy.debug('Controller Validate $email $validationCode');
    error.value = '';
    try {
      return await authentication.validate(email, validationCode);
    } catch (e) {
      loggy.error('Validation error $e');
      error.value = errorMessage(e);
      return false;
    }
  }

  Future<bool> logOut() async {
    loggy.debug('AuthenticationController: Log Out');
    error.value = '';
    // Se baja la bandera antes de llamar al servidor: quien esté mirando sale
    // de la sesión aunque la llamada tarde o falle. Lo que haya que limpiar
    // detrás cuelga de esta misma bandera, en `main`.
    logged.value = false;
    try {
      await authentication.logOut();
      _loggedUser.value = null;
      return true;
    } catch (e) {
      loggy.error('LogOut error $e');
      error.value = errorMessage(e);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    loggy.debug('AuthenticationController: Forgot Password $email');
    error.value = '';
    try {
      await authentication.forgotPassword(email);
      return true;
    } catch (e) {
      loggy.error('ForgotPassword error $e');
      error.value = errorMessage(e);
      return false;
    }
  }

  Future<AuthenticationUser> getLoggedUser() async {
    loggy.debug('AuthenticationController: Get Logged User');
    isLoading.value = true;
    try {
      final rta = await authentication.getLoggedUser();
      _loggedUser.value = rta;
      return rta;
    } finally {
      isLoading.value = false;
    }
  }
}
