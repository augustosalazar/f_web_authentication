import 'package:f_web_authentication/core/roble_exception.dart';
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

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockAuthController = MockAuthenticationController();

    logged = false.obs;
    isLoading = false.obs;

    when(() => mockAuthController.logged).thenReturn(logged);
    when(() => mockAuthController.isLoading).thenReturn(isLoading);
    when(() => mockAuthController.isLogged).thenAnswer((_) => logged.value);

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
        .thenThrow(RobleException('Login failed'));

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
}
