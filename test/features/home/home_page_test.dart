import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/home/ui/pages/home_page.dart';

class MockAuthenticationController extends GetxService
    with Mock
    implements AuthenticationController {}

void main() {
  late MockAuthenticationController auth;
  late Rxn<AuthenticationUser> usuario;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    // Estado reactivo real, pero externo al mock: si `loggedUser` devolviera
    // un valor suelto, el Obx no leeria ningun observable y Get protestaria en
    // vez de pintar —que es como fallan las pruebas viejas de productos—.
    usuario = Rxn<AuthenticationUser>(
      AuthenticationUser(email: 'ana@correo.com', name: 'Ana', role: 'admin'),
    );
    auth = MockAuthenticationController();
    when(() => auth.loggedUser).thenAnswer((_) => usuario.value);
    when(() => auth.logOut()).thenAnswer((_) async => true);

    Get.put<AuthenticationController>(auth);
  });

  tearDown(Get.reset);

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('saluda a quien entró', (tester) async {
    await montar(tester);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
  });

  testWidgets('muestra el rol junto al correo', (tester) async {
    await montar(tester);

    expect(find.text('admin'), findsOneWidget);
    expect(find.byKey(const Key('home_role')), findsOneWidget);
  });

  testWidgets('sin rol asignado no pinta una etiqueta vacía', (tester) async {
    usuario.value =
        AuthenticationUser(email: 'ana@correo.com', name: 'Ana');

    await montar(tester);

    // No tener rol es normal, y una etiqueta en blanco no dice nada.
    expect(find.byKey(const Key('home_role')), findsNothing);
    expect(find.text('ana@correo.com'), findsOneWidget);
  });

  testWidgets('ofrece los dos módulos, no uno dentro del otro', (tester) async {
    await montar(tester);

    // Productos y chat son modelos de datos distintos —tabla SQL y arbol
    // JSON—, y esta pantalla existe para ponerlos al mismo nivel.
    expect(find.byKey(const Key('home_card_products')), findsOneWidget);
    expect(find.byKey(const Key('home_card_chat')), findsOneWidget);
  });

  testWidgets('cada tarjeta dice con qué API se hace', (tester) async {
    await montar(tester);

    // Es lo que alguien viene a copiar: sin esto la tarjeta es solo un enlace.
    expect(find.text('db.json.push · db.json.watch'), findsOneWidget);
  });

  testWidgets('cerrar sesión cuelga del inicio, no de una función',
      (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    // Antes solo se podia cerrar sesion estando en la lista de productos.
    verify(() => auth.logOut()).called(1);
  });

  testWidgets('sin usuario cargado no revienta el saludo', (tester) async {
    usuario.value = null;

    await montar(tester);

    // Pasa entre que la sesion se restaura y llega el perfil.
    expect(find.text('Hola'), findsOneWidget);
  });
}
