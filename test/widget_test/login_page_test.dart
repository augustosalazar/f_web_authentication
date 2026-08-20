import 'package:roble/roble.dart';
import 'package:f_web_authentication/features/auth/ui/pages/login_page.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationController extends GetxController
    with Mock
    implements AuthenticationController {}

void main() {
  late MockAuthenticationController mockAuthController;

  late RxBool logged;
  late RxBool isLoading;
  late RxBool googleEnabled;
  late RxBool isSocialLoading;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockAuthController = MockAuthenticationController();

    logged = false.obs;
    isLoading = false.obs;
    googleEnabled = false.obs;
    isSocialLoading = false.obs;

    when(() => mockAuthController.logged).thenReturn(logged);
    when(() => mockAuthController.isLoading).thenReturn(isLoading);
    when(() => mockAuthController.isLogged).thenAnswer((_) => logged.value);
    when(() => mockAuthController.googleEnabled).thenReturn(googleEnabled);
    when(() => mockAuthController.isSocialLoading).thenReturn(isSocialLoading);

    when(() => mockAuthController.login(any(), any())).thenAnswer((_) async {
      logged.value = true;
      return true;
    });

    Get.put<AuthenticationController>(mockAuthController);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidgetUnderTest() {
    return GetMaterialApp(
      scaffoldMessengerKey: messengerKey,
      home: LoginPage(),
    );
  }

  testWidgets('Login page validation and interaction test',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Login to access your account'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);

    final emailField = find.widgetWithText(TextFormField, 'Email address');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    // 1. Email vacío
    await tester.enterText(emailField, '');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter email'), findsOneWidget);

    // 2. Email inválido
    await tester.enterText(emailField, 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter valid email address'), findsOneWidget);

    // 3. Password corto
    await tester.enterText(emailField, 'test@test.com');
    await tester.enterText(passwordField, '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Password should have at least 6 characters'),
        findsOneWidget);

    // 4. Login exitoso
    await tester.enterText(passwordField, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    verify(() => mockAuthController.login('test@test.com', 'password123'))
        .called(1);

    expect(logged.value, true);
  });

  testWidgets('Login failure shows snackbar', (WidgetTester tester) async {
    when(() => mockAuthController.login('error@test.com', 'password123'))
        .thenThrow(const RobleApiException('Login failed'));

    await tester.pumpWidget(createWidgetUnderTest());

    final emailField = find.widgetWithText(TextFormField, 'Email address');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    await tester.enterText(emailField, 'error@test.com');
    await tester.enterText(passwordField, 'password123');

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    verify(() => mockAuthController.login('error@test.com', 'password123'))
        .called(1);

    expect(find.textContaining('Login failed'), findsOneWidget);
  });

  group('Entrar con Google', () {
    testWidgets('el boton no aparece si el proveedor esta apagado',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byKey(const Key('google_login_button')), findsNothing);
    });

    testWidgets('pulsarlo pide el login social y deja la sesion iniciada',
        (WidgetTester tester) async {
      googleEnabled.value = true;
      when(() => mockAuthController.loginWithGoogle()).thenAnswer((_) async {
        logged.value = true;
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pump();

      verify(() => mockAuthController.loginWithGoogle()).called(1);
      expect(logged.value, isTrue);
    });

    testWidgets('un fallo del proveedor se muestra en un snackbar',
        (WidgetTester tester) async {
      googleEnabled.value = true;
      when(() => mockAuthController.loginWithGoogle()).thenThrow(
          const RobleApiAuthException('El navegador bloqueo la ventana'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('bloqueo la ventana'), findsOneWidget);
    });
  });
}
