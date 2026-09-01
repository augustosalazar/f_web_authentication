import 'dart:async';

import 'package:f_web_authentication/core/session_expiry.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/app_wiring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roble/roble.dart';

class MockAuthenticationController extends GetxController
    with Mock
    implements AuthenticationController {}

class MockRoble extends Mock implements RobleApiDataBase {}

void main() {
  group('reportError', () {
    setUp(() => sessionExpired.value = false);

    test('un error de autenticación levanta la bandera', () {
      final texto = reportError(
          const RobleApiAuthException('Token expirado y no se pudo refrescar'));

      expect(sessionExpired.value, isTrue);
      expect(texto, 'Token expirado y no se pudo refrescar');
    });

    test('cualquier otro error no la levanta', () {
      reportError(const RobleApiException('La tabla no existe'));
      expect(sessionExpired.value, isFalse);

      reportError(const RobleApiNetworkException('Sin conexión a internet'));
      expect(sessionExpired.value, isFalse);
    });

    test('sigue diciendo lo mismo que errorMessage', () {
      // Es un envoltorio, no un cambio de comportamiento: el texto que ve la
      // gente tiene que ser el mismo de antes.
      expect(reportError(const RobleApiException('sin bucket')), 'sin bucket');
      expect(
        reportError(FormatException('no es un número'),
            fallback: 'No se pudo completar la operación.'),
        'No se pudo completar la operación.',
      );
    });
  });

  group('cerrar la sesión cuando caduca', () {
    late MockAuthenticationController auth;
    late MockRoble roble;
    late StreamController<void> caducada;
    late RxBool logged;
    late RxString error;
    VoidCallback? soltar;

    setUp(() {
      Get.testMode = true;
      Get.reset();
      sessionExpired.value = false;

      logged = true.obs;
      error = ''.obs;
      auth = MockAuthenticationController();
      when(() => auth.logged).thenReturn(logged);
      when(() => auth.error).thenReturn(error);
      when(() => auth.isLogged).thenAnswer((_) => logged.value);
      when(() => auth.logOut()).thenAnswer((_) async {
        logged.value = false;
        return true;
      });

      caducada = StreamController<void>.broadcast();
      roble = MockRoble();
      when(() => roble.onSessionExpired).thenAnswer((_) => caducada.stream);

      Get.put<AuthenticationController>(auth);
    });

    tearDown(() async {
      soltar?.call();
      soltar = null;
      await caducada.close();
      sessionExpired.value = false;
      Get.reset();
    });

    test('el aviso del paquete cierra la sesión', () async {
      soltar = closeSessionWhenItExpires(roble);

      caducada.add(null);
      await Future<void>.delayed(Duration.zero);

      verify(() => auth.logOut()).called(1);
      expect(logged.value, isFalse);
    });

    test('y deja dicho por qué, que si no la vuelta a la entrada no se explica',
        () async {
      soltar = closeSessionWhenItExpires(roble);

      caducada.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(error.value, contains('caducó'));
    });

    test('la bandera de los controladores también cierra la sesión', () async {
      soltar = closeSessionWhenItExpires(roble);

      // Lo que haría un controlador al ver un RobleApiAuthException.
      sessionExpired.value = true;
      await Future<void>.delayed(Duration.zero);

      verify(() => auth.logOut()).called(1);
    });

    test('la bandera se baja sola, para que la próxima vez vuelva a avisar',
        () async {
      soltar = closeSessionWhenItExpires(roble);

      sessionExpired.value = true;
      await Future<void>.delayed(Duration.zero);
      expect(sessionExpired.value, isFalse);

      logged.value = true;
      sessionExpired.value = true;
      await Future<void>.delayed(Duration.zero);

      verify(() => auth.logOut()).called(2);
    });

    test('estando ya fuera no hace nada', () async {
      // El aviso puede venir de una llamada que salió antes de cerrar sesión a
      // mano; volver a cerrar solo pondría un mensaje de caducidad a quien
      // acaba de salir por su propio pie.
      logged.value = false;
      soltar = closeSessionWhenItExpires(roble);

      caducada.add(null);
      sessionExpired.value = true;
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => auth.logOut());
      expect(error.value, isEmpty);
    });
  });
}
