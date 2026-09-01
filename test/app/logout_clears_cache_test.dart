import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:f_web_authentication/app_wiring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationController extends GetxController
    with Mock
    implements AuthenticationController {}

class MockProductRepository extends Mock implements IProductRepository {}

void main() {
  late MockAuthenticationController auth;
  late MockProductRepository repo;
  late RxBool logged;
  VoidCallback? soltar;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    logged = true.obs;
    auth = MockAuthenticationController();
    when(() => auth.logged).thenReturn(logged);

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

  test('cerrar sesión tira la caché de productos', () async {
    soltar = clearCachesOnLogOut();

    logged.value = false;
    await Future<void>.delayed(Duration.zero);

    verify(() => repo.clearCache()).called(1);
  });

  test('entrar no tira nada', () async {
    logged.value = false;
    soltar = clearCachesOnLogOut();

    logged.value = true;
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => repo.clearCache());
  });

  test('sin el enlace puesto, la sesión no toca los productos', () async {
    // La autenticación ya no busca el ProductController al salir. Sin este
    // enlace nadie limpia nada, que es justo lo que prueba que la dependencia
    // vive aquí y no dentro de `logOut`.
    logged.value = false;
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => repo.clearCache());
  });
}
