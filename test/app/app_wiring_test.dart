import 'dart:async';

import 'package:f_web_authentication/app_wiring.dart';
import 'package:f_web_authentication/core/session_expiry.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roble/roble.dart';

class MockAuthenticationController extends GetxController
    with Mock
    implements AuthenticationController {}

class MockProductRepository extends Mock implements IProductRepository {}

class MockRoble extends Mock implements RobleApiDataBase {}

/// `main` ya no llama a las reglas una por una: llama a [wireApp]. Esto
/// comprueba que las deja todas puestas, que es lo único que no se ve desde las
/// pruebas de cada regla por separado.
void main() {
  late MockAuthenticationController auth;
  late MockProductRepository repo;
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

    repo = MockProductRepository();
    when(() => repo.clearCache()).thenAnswer((_) async {});

    caducada = StreamController<void>.broadcast();
    roble = MockRoble();
    when(() => roble.onSessionExpired).thenAnswer((_) => caducada.stream);

    Get.put<AuthenticationController>(auth);
    Get.put<IProductRepository>(repo);
  });

  tearDown(() async {
    soltar?.call();
    soltar = null;
    await caducada.close();
    sessionExpired.value = false;
    Get.reset();
  });

  test('deja puestas las dos reglas', () async {
    soltar = wireApp(roble);

    // Una sesión caída saca a quien la tenía...
    caducada.add(null);
    await Future<void>.delayed(Duration.zero);
    verify(() => auth.logOut()).called(1);

    // ...y al salir se tira la caché.
    verify(() => repo.clearCache()).called(1);
  });

  test('soltarlo deshace las dos', () async {
    wireApp(roble)();

    caducada.add(null);
    logged.value = false;
    sessionExpired.value = true;
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => auth.logOut());
    verifyNever(() => repo.clearCache());
  });
}
