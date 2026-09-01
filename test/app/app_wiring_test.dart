import 'package:f_web_authentication/app_wiring.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationController extends GetxController
    with Mock
    implements AuthenticationController {}

class MockProductRepository extends Mock implements IProductRepository {}

/// `main` no llama a las reglas una por una: llama a [wireApp]. Esto comprueba
/// que las deja puestas, que es lo único que no se ve desde las pruebas de cada
/// regla por separado.
void main() {
  late MockAuthenticationController auth;
  late MockProductRepository repo;
  late RxBool logged;
  late RxString error;
  VoidCallback? soltar;

  setUp(() {
    Get.testMode = true;
    Get.reset();

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

    Get.put<AuthenticationController>(auth);
    Get.put<IProductRepository>(repo);
  });

  tearDown(() {
    soltar?.call();
    soltar = null;
    Get.reset();
  });

  test('al salir se tira la caché', () async {
    soltar = wireApp();

    logged.value = false;
    await Future<void>.delayed(Duration.zero);

    verify(() => repo.clearCache()).called(1);
  });

  test('soltarlo lo deshace', () async {
    wireApp()();

    logged.value = false;
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => repo.clearCache());
  });
}
