import 'dart:async';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'package:roble/roble.dart';

import '../../../../core/error_message.dart';
import '../../domain/models/authentication_user.dart';
import '../../domain/repositories/i_auth_repository.dart';

/// La sesión: quién entró y si sigue dentro.
///
/// El controlador **no decide** el estado de la sesión: lo refleja. Quién está
/// dentro lo dice `sessionChanges`, que es el flujo del paquete tal cual —con
/// el perfil ya convertido en `RobleUser`—, y aquí solo se copia a [logged] y
/// [loggedUser]. Antes se ponía a mano en cinco métodos, y
/// bastaba con equivocarse de orden en uno para dar por iniciada una sesión que
/// no lo estaba.
///
/// Los métodos no lanzan. Devuelven `true` o `false` y, cuando algo falla,
/// dejan el motivo en [error] —lo mismo que productos, chat y archivos—, así
/// que la pantalla decide qué enseñar sin envolver cada llamada en un `try`.
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

  StreamSubscription<RobleAuthState>? _sesion;

  AuthenticationController(this.authentication);

  AuthenticationUser? get loggedUser => _loggedUser.value;

  set loggedUser(AuthenticationUser? user) {
    _loggedUser.value = user;
  }

  @override
  void onInit() {
    super.onInit();
    _sesion = authentication.sessionChanges().listen(_aplicar);
    unawaited(_initialize());
  }

  @override
  void onClose() {
    unawaited(_sesion?.cancel());
    super.onClose();
  }

  /// Copia lo que diga la sesión.
  void _aplicar(RobleAuthState sesion) {
    loggy.debug('Sesión: ${sesion.reason.name}');
    logged.value = sesion.isSignedIn;

    // El perfil solo se pisa cuando viene: una sesión recuperada sin verificar
    // no lo trae, y borrarlo dejaría el inicio saludando a nadie.
    if (sesion.user != null) {
      _loggedUser.value = AuthenticationUser.fromRoble(sesion.user!);
    }
    if (!sesion.isSignedIn) _loggedUser.value = null;

    // Caerse no es lo mismo que salir: a quien le pasa no ha hecho nada, y sin
    // esto vuelve a la pantalla de entrada sin saber por qué.
    if (sesion.hasExpired) error.value = 'Tu sesión caducó. Vuelve a entrar.';
  }

  Future<void> _initialize() async {
    loggy.debug('AuthenticationController initialized');
    try {
      // No hace falta mirar lo que devuelve: si la sesión valía, llega por
      // `sessionChanges` con el perfil ya dentro.
      await authentication.restoreSession();
      await refreshGoogleAvailability();
    } catch (e) {
      // Arrancar sin sesión es normal —un token caducado, sin red—, así que
      // esto no se le enseña a nadie: se queda en la pantalla de entrada.
      loggy.debug('No se pudo restaurar la sesión: $e');
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

    return authentication.signInWithGoogle().then<bool>((_) => true).catchError(
      (Object e) {
        loggy.error('Error during Google login: $e');
        error.value = errorMessage(e);
        return false;
      },
    ).whenComplete(() => isSocialLoading.value = false);
  }

  bool get isLogged => logged.value;

  Future<bool> login(email, password) async {
    loggy.debug('AuthenticationController: Login $email');
    error.value = '';
    isLoading.value = true;
    try {
      await authentication.login(email, password);
      return true;
    } catch (e) {
      loggy.error('Login error $e');
      error.value = errorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
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
    try {
      await authentication.logOut();
      return true;
    } catch (e) {
      loggy.error('LogOut error $e');
      error.value = errorMessage(e);
      // Se sale igual. El paquete solo emite `signedOut` cuando el servidor
      // contesta, y quedarse dentro porque la llamada de salida no llegó es
      // peor que salir: la sesión local ya no vale y la pantalla creería que
      // sigues dentro.
      logged.value = false;
      _loggedUser.value = null;
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
