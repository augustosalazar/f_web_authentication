import 'dart:async';

import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

AuthenticationUser usuario({
  String email = 'ana@correo.com',
  String name = 'Ana',
  String? role,
}) =>
    AuthenticationUser(email: email, name: name, role: role);

/// Autenticación de mentira: apunta lo que le piden y deja al test decidir
/// qué falla.
///
/// A mano y no con `mocktail` por lo mismo que el chat: aquí lo que se prueba
/// es *cuándo* se llama a qué y qué pasa cuando revienta, y eso se lee mejor
/// como una clase pequeña que como una pila de `when()`.
class AutenticacionFalsa implements IAuthRepository {
  AutenticacionFalsa({this.sesionViva = false, this.googleActivo = false});

  /// Lo que contesta [restoreSession]: si había sesión guardada al arrancar.
  bool sesionViva;
  bool googleActivo;

  /// El perfil que devuelve el servidor. Si es `null`, [getLoggedUser] falla.
  AuthenticationUser? perfil = usuario();

  /// Lo que contesta [validate].
  bool validacionCorrecta = true;

  Object? fallaElLogin;
  Object? fallaElLogOut;
  Object? fallaElAlta;
  Object? fallaLaValidacion;
  Object? fallaElOlvido;
  Object? fallaElPerfil;
  Object? fallaGoogle;
  Object? fallaRestaurar;

  final _sesiones = StreamController<RobleAuthState>.broadcast();

  /// El estado que se reparte a quien se suscriba, como hace el paquete.
  RobleAuthState estado = const RobleAuthState(
    user: null,
    reason: RobleAuthReason.signedOut,
  );

  @override
  Stream<RobleAuthState> sessionChanges() {
    // Igual que el paquete, y por lo mismo: con `async*` la suscripción no
    // queda viva hasta después del primer `yield`, y lo que se emitiera en ese
    // hueco no lo vería nadie.
    late StreamController<RobleAuthState> salida;
    StreamSubscription<RobleAuthState>? fuente;

    salida = StreamController<RobleAuthState>(
      onListen: () {
        fuente = _sesiones.stream.listen(salida.add);
        salida.add(estado);
      },
      onCancel: () => fuente?.cancel(),
    );

    return salida.stream;
  }

  /// Manda un cambio de sesión, que es lo que haría el servidor.
  void emite(RobleAuthReason reason, [AuthenticationUser? quien]) {
    estado = RobleAuthState(
      user: quien == null
          ? null
          : RobleUser(
              userId: quien.id ?? 'u1',
              email: quien.email,
              name: quien.name,
              role: quien.role,
            ),
      reason: reason,
    );
    _sesiones.add(estado);
  }

  Future<void> cerrar() => _sesiones.close();

  final entradas = <String>[];
  final altas = <String>[];
  int cierres = 0;
  int perfilesPedidos = 0;

  @override
  Future<void> login(String email, String password) async {
    if (fallaElLogin != null) throw fallaElLogin!;
    // El paquete pide el perfil dentro del propio login y emite con él, así
    // que un perfil que falla se lleva por delante la entrada entera.
    if (fallaElPerfil != null) throw fallaElPerfil!;
    entradas.add(email);
    emite(RobleAuthReason.signedIn, perfil);
  }

  @override
  Future<void> signUp(
      String email, String password, String name, bool direct) async {
    if (fallaElAlta != null) throw fallaElAlta!;
    altas.add(email);
  }

  @override
  Future<void> logOut() async {
    cierres++;
    if (fallaElLogOut != null) throw fallaElLogOut!;
    emite(RobleAuthReason.signedOut);
  }

  @override
  Future<bool> validate(String email, String validationCode) async {
    if (fallaLaValidacion != null) throw fallaLaValidacion!;
    return validacionCorrecta;
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (fallaElOlvido != null) throw fallaElOlvido!;
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    perfilesPedidos++;
    if (fallaElPerfil != null) throw fallaElPerfil!;
    return perfil!;
  }

  @override
  Future<bool> restoreSession() async {
    if (fallaRestaurar != null) throw fallaRestaurar!;
    if (sesionViva) emite(RobleAuthReason.restored, perfil);
    return sesionViva;
  }

  @override
  Future<bool> isGoogleEnabled() async => googleActivo;

  @override
  Future<AuthenticationUser> signInWithGoogle() async {
    if (fallaGoogle != null) throw fallaGoogle!;
    emite(RobleAuthReason.signedIn, perfil);
    return perfil!;
  }
}

/// Deja correr el bucle de eventos: `onInit` arranca `_initialize` sin
/// esperarlo, así que hay que darle un turno.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late AutenticacionFalsa auth;

  setUp(() => auth = AutenticacionFalsa());

  /// El controlador arrancado. Ya no vale construirlo a secas: la sesión llega
  /// por el flujo, y sin `onInit` no hay nadie suscrito.
  AuthenticationController build() => AuthenticationController(auth)..onInit();

  /// Lo mismo, esperando a que termine el arranque.
  Future<AuthenticationController> buildArrancado() async {
    final controller = build();
    await settle();
    return controller;
  }

  group('arranque', () {
    test('con sesión guardada entra y trae el perfil', () async {
      auth
        ..sesionViva = true
        ..perfil = usuario(email: 'ana@correo.com', role: 'admin');

      final controller = await buildArrancado();

      expect(controller.isLogged, isTrue);
      expect(controller.loggedUser?.email, 'ana@correo.com');
      expect(controller.loggedUser?.role, 'admin');
    });

    test('sin sesión guardada no pide el perfil', () async {
      auth.sesionViva = false;

      final controller = await buildArrancado();

      expect(controller.isLogged, isFalse);
      expect(auth.perfilesPedidos, 0);
    });

    test('un fallo al restaurar deja fuera, pero no se le enseña a nadie',
        () async {
      // Un token caducado o un arranque sin red son lo normal, no algo que
      // haya que contarle a quien todavía no ha hecho nada.
      auth.fallaRestaurar = const RobleApiException('token vencido');

      final controller = await buildArrancado();

      expect(controller.isLogged, isFalse);
      expect(controller.error.value, isEmpty);
    });

    test('pregunta si Google está activo en el proyecto', () async {
      auth.googleActivo = true;

      final controller = await buildArrancado();

      expect(controller.googleEnabled.value, isTrue);
    });

    test('con Google apagado el botón no se pinta', () async {
      auth.googleActivo = false;

      final controller = await buildArrancado();

      expect(controller.googleEnabled.value, isFalse);
    });
  });

  group('entrar', () {
    test('deja la sesión iniciada y con perfil', () async {
      final controller = build();

      final ok = await controller.login('ana@correo.com', 'secreto');
      // `login` vuelve en cuanto el servidor contesta; la sesión la aplica el
      // flujo un turno después. Para la pantalla da igual —`Central` se
      // reconstruye cuando llega—, pero aquí hay que esperarlo.
      await settle();

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
      expect(controller.loggedUser?.name, 'Ana');
      expect(controller.error.value, isEmpty);
      expect(auth.entradas, ['ana@correo.com']);
    });

    test('un fallo no lanza: devuelve false y deja el motivo', () async {
      auth.fallaElLogin = const RobleApiException('Contraseña incorrecta');
      final controller = build();

      final ok = await controller.login('ana@correo.com', 'mal');

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, 'Contraseña incorrecta');
    });

    test('si el perfil falla, la sesión no se da por iniciada', () async {
      // Entrar y no saber quién entró no es entrar: la app se quedaría en la
      // pantalla de inicio saludando a nadie.
      auth.fallaElPerfil = const RobleApiException('perfil no disponible');
      final controller = build();

      final ok = await controller.login('ana@correo.com', 'secreto');

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, 'perfil no disponible');
    });

    test('el aviso de un intento no queda para el siguiente', () async {
      auth.fallaElLogin = const RobleApiException('Contraseña incorrecta');
      final controller = build();
      await controller.login('ana@correo.com', 'mal');
      expect(controller.error.value, isNotEmpty);

      auth.fallaElLogin = null;
      await controller.login('ana@correo.com', 'secreto');

      expect(controller.error.value, isEmpty);
    });

    test('suelta el indicador de carga también cuando falla', () async {
      auth.fallaElPerfil = const RobleApiException('perfil no disponible');
      final controller = build();

      await controller.login('ana@correo.com', 'secreto');

      expect(controller.isLoading.value, isFalse);
    });
  });

  group('salir', () {
    test('cierra la sesión y olvida quién era', () async {
      auth.sesionViva = true;
      final controller = await buildArrancado();
      expect(controller.loggedUser, isNotNull);

      final ok = await controller.logOut();
      await settle();

      expect(ok, isTrue);
      expect(controller.isLogged, isFalse);
      expect(controller.loggedUser, isNull);
      expect(auth.cierres, 1);
    });

    test('saca al usuario aunque el servidor falle', () async {
      // Quedarse dentro porque la llamada de salida no llegó es peor que
      // salir: la sesión local ya no vale y no hay forma de volver a intentarlo
      // desde una pantalla que cree que sigues dentro.
      auth.fallaElLogOut = const RobleApiException('sin red');
      final controller = build()..logged.value = true;

      final ok = await controller.logOut();

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, 'sin red');
    });
  });

  group('darse de alta', () {
    test('con validación por correo', () async {
      final controller = build();

      final ok = await controller.signUp('Ana', 'ana@correo.com', 'secreto', false);

      expect(ok, isTrue);
      expect(auth.altas, ['ana@correo.com']);
    });

    test('directa, sin validación', () async {
      final controller = build();

      final ok = await controller.signUp('Ana', 'ana@correo.com', 'secreto', true);

      expect(ok, isTrue);
    });

    test('un correo repetido se avisa, no revienta', () async {
      auth.fallaElAlta = const RobleApiException('Ese correo ya está dado de alta');
      final controller = build();

      final ok = await controller.signUp('Ana', 'ana@correo.com', 'secreto', false);

      expect(ok, isFalse);
      expect(controller.error.value, 'Ese correo ya está dado de alta');
    });

    test('darse de alta no inicia la sesión', () async {
      final controller = build();

      await controller.signUp('Ana', 'ana@correo.com', 'secreto', false);

      expect(controller.isLogged, isFalse);
    });
  });

  group('validar el correo', () {
    test('devuelve lo que diga el servidor', () async {
      auth.validacionCorrecta = false;
      final controller = build();

      expect(await controller.validate('ana@correo.com', '000000'), isFalse);
      expect(controller.error.value, isEmpty);
    });

    test('un código caducado se avisa', () async {
      auth.fallaLaValidacion = const RobleApiException('El código ya no vale');
      final controller = build();

      final ok = await controller.validate('ana@correo.com', '123456');

      expect(ok, isFalse);
      expect(controller.error.value, 'El código ya no vale');
    });
  });

  group('contraseña olvidada', () {
    test('pide el enlace', () async {
      final controller = build();

      expect(await controller.forgotPassword('ana@correo.com'), isTrue);
    });

    test('un fallo se avisa con el motivo del servidor', () async {
      auth.fallaElOlvido = const RobleApiException('Ese correo no existe');
      final controller = build();

      final ok = await controller.forgotPassword('ana@correo.com');

      expect(ok, isFalse);
      expect(controller.error.value, 'Ese correo no existe');
    });
  });

  group('la sesión se cae sola', () {
    test('saca al usuario sin que nadie haya hecho nada', () async {
      auth.sesionViva = true;
      final controller = await buildArrancado();
      expect(controller.isLogged, isTrue);

      // Lo que emite el paquete cuando el refresco falla.
      auth.emite(RobleAuthReason.expired);
      await settle();

      expect(controller.isLogged, isFalse);
      expect(controller.loggedUser, isNull);
    });

    test('y lo dice, que si no la vuelta a la entrada no se explica', () async {
      auth.sesionViva = true;
      final controller = await buildArrancado();

      auth.emite(RobleAuthReason.expired);
      await settle();

      expect(controller.error.value, contains('caducó'));
    });

    test('salir a propósito no deja ese aviso', () async {
      // Es la diferencia entre `signedOut` y `expired`: quien se va sabe por
      // qué está en la entrada.
      auth.sesionViva = true;
      final controller = await buildArrancado();

      await controller.logOut();
      await settle();

      expect(controller.isLogged, isFalse);
      expect(controller.error.value, isEmpty);
    });

    test('una sesión recuperada sin perfil sigue siendo una sesión', () async {
      // `restoreSession(verify: false)` no llama al servidor, así que no hay
      // perfil todavía; borrar el que hubiera dejaría el inicio sin saludo.
      final controller = build();
      await settle();

      auth.emite(RobleAuthReason.restored);
      await settle();

      expect(controller.isLogged, isTrue);
    });
  });

  group('entrar con Google', () {
    test('deja la sesión iniciada', () async {
      auth.perfil = usuario(email: 'ana@gmail.com', name: 'Ana G');
      final controller = build();

      final ok = await controller.loginWithGoogle();
      await settle();

      expect(ok, isTrue);
      expect(controller.isLogged, isTrue);
      expect(controller.loggedUser?.email, 'ana@gmail.com');
    });

    test('si el navegador bloquea la ventana se avisa', () async {
      auth.fallaGoogle =
          const RobleApiAuthException('El navegador bloqueó la ventana');
      final controller = build();

      final ok = await controller.loginWithGoogle();

      expect(ok, isFalse);
      expect(controller.isLogged, isFalse);
      expect(controller.error.value, 'El navegador bloqueó la ventana');
    });

    test('suelta el botón pase lo que pase', () async {
      auth.fallaGoogle = const RobleApiAuthException('cancelado');
      final controller = build();

      await controller.loginWithGoogle();

      expect(controller.isSocialLoading.value, isFalse);
    });
  });
}
