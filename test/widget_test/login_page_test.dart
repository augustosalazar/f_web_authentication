import 'package:f_web_authentication/core/roble_exception.dart';
import 'package:f_web_authentication/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/auth/ui/pages/login_page.dart';

class MockAuthenticationController extends GetxService
    with Mock
    implements AuthenticationController {
  @override
  final logged = false.obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  Future<bool> login(dynamic email, dynamic password) async {
    if (email == 'error@test.com') {
      throw RobleException('Login failed');
    }
    logged.value = true;
    return true;
  }

  @override
  bool get isLogged => logged.value;

  @override
  Future<void> onInit() async {
    // No hacer nada en el mock
  }
}

void main() {
  late MockAuthenticationController mockAuthController;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    mockAuthController = MockAuthenticationController();
    // Registramos el mock en el DI de Get
    Get.put<AuthenticationController>(mockAuthController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Login page validation and interaction test',
      (WidgetTester tester) async {
    // Cargamos el widget envuelto en GetMaterialApp para que funcione GetX
    await tester.pumpWidget(GetMaterialApp(
      scaffoldMessengerKey: messengerKey, //esta llave se usa para los snackbars
      home: LoginPage(),
    ));

    // Verificamos que los elementos iniciales estén presentes
    expect(find.text("Login to access your account"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Login"), findsOneWidget);

    // Buscamos los campos de texto
    final emailField = find.widgetWithText(TextFormField, "Email address");
    final passwordField = find.widgetWithText(TextFormField, "Password");

    // 1. Probar validación de email vacío
    await tester.enterText(emailField, '');
    await tester.tap(find.widgetWithText(FilledButton, "Login"));
    await tester.pump();
    expect(find.text("Enter email"), findsOneWidget);

    // 2. Probar validación de email inválido
    await tester.enterText(emailField, 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, "Login"));
    await tester.pump();
    expect(find.text("Enter valid email address"), findsOneWidget);

    // 3. Probar validación de password corto
    await tester.enterText(emailField, 'test@test.com');
    await tester.enterText(passwordField, '123');
    await tester.tap(find.widgetWithText(FilledButton, "Login"));
    await tester.pump();
    expect(find.text("Password should have at least 6 characters"),
        findsOneWidget);

    // 4. Probar login exitoso
    await tester.enterText(passwordField, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, "Login"));
    await tester.pump();

    // Verificamos que se haya llamado al método login (en el mock cambia el estado)
    expect(mockAuthController.isLogged, true);
  });

  testWidgets('Login failure shows snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      scaffoldMessengerKey: messengerKey, //esta llave se usa para los snackbars
      home: LoginPage(),
    ));

    final emailField = find.widgetWithText(TextFormField, "Email address");
    final passwordField = find.widgetWithText(TextFormField, "Password");

    // Ingresar credenciales que disparan el error en nuestro mock
    await tester.enterText(emailField, 'error@test.com');
    await tester.enterText(passwordField, 'password123');

    await tester.tap(find.widgetWithText(FilledButton, "Login"));
    // pumpAndSettle para esperar a que las animaciones (como el snackbar) terminen
    await tester.pumpAndSettle();

    // Verificamos que aparezca el mensaje de error en el snackbar
    expect(find.textContaining("Login failed"), findsOneWidget);
  });
}
