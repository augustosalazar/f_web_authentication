import 'dart:convert';

import 'package:f_web_authentication/core/i_local_preferences.dart';
import 'package:f_web_authentication/features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'package:f_web_authentication/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:f_web_authentication/features/auth/data/repositories/auth_repository.dart';
import 'package:f_web_authentication/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_web_authentication/features/auth/ui/pages/login_page.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/data/datasources/cache/local_product_cache_source.dart';
import 'package:f_web_authentication/features/product/data/datasources/remote/i_product_source.dart';
import 'package:f_web_authentication/features/product/data/datasources/remote/remote_product_roble_source.dart';
import 'package:f_web_authentication/features/product/data/repositories/product_repository.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:f_web_authentication/features/product/ui/pages/list_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:f_web_authentication/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockLocalPreferences extends Mock implements ILocalPreferences {}

class FakeUri extends Fake implements Uri {}

late MockHttpClient mockHttpClient;
late MockLocalPreferences mockLocalPreferences;

Future<Widget> createAuthApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.testMode = true;
  Get.reset();

  mockHttpClient = MockHttpClient();
  mockLocalPreferences = MockLocalPreferences();

  final storage = <String, String?>{
    'token': null,
    'refreshToken': null,
    'userId': null,
  };

  when(() => mockLocalPreferences.getString(any()))
      .thenAnswer((invocation) async {
    final key = invocation.positionalArguments[0] as String;
    return storage[key];
  });

  when(() => mockLocalPreferences.setString(any(), any()))
      .thenAnswer((invocation) async {
    final key = invocation.positionalArguments[0] as String;
    final value = invocation.positionalArguments[1] as String;
    storage[key] = value;
  });

  when(() => mockLocalPreferences.remove(any())).thenAnswer((invocation) async {
    final key = invocation.positionalArguments[0] as String;
    storage.remove(key);
  });

  when(() => mockLocalPreferences.clear()).thenAnswer((_) async {
    storage.clear();
  });

  // Default fallback stubs
  when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
      .thenAnswer(
          (_) async => http.Response('{"message":"unauthorized"}', 401));

  when(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{}', 201));

  when(() => mockHttpClient.put(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{}', 200));

  when(() => mockHttpClient.delete(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{}', 200));

  Get.put<ILocalPreferences>(mockLocalPreferences);

  Get.put<IAuthenticationSource>(
    AuthenticationSourceServiceRoble(
      client: mockHttpClient,
      rawClient: mockHttpClient,
    ),
  );

  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put<AuthenticationController>(AuthenticationController(Get.find()));

  Get.put<http.Client>(mockHttpClient, tag: 'apiClient', permanent: true);

  Get.put<IProductSource>(
    RemoteProductRobleSource(Get.find<http.Client>(tag: 'apiClient')),
  );
  Get.put<LocalProductCacheSource>(LocalProductCacheSource(Get.find()));
  Get.put<IProductRepository>(ProductRepository(Get.find(), Get.find()));
  Get.put<ProductController>(ProductController(Get.find()));

  return MyApp();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    registerFallbackValue(FakeUri());
  });

  tearDown(() async {
    Get.reset();
  });

  const bool kDemoMode = true;

  Future<void> demoPause(WidgetTester tester, [int ms = 1000]) async {
    if (kDemoMode) {
      await tester.pump(Duration(milliseconds: ms));
    }
  }

  Future<void> enterTextAndPause(
    WidgetTester tester,
    Finder finder,
    String text, {
    int milliseconds = 700,
  }) async {
    await tester.enterText(finder, text);
    await tester.pump();
    await demoPause(tester, milliseconds);
  }

  Future<void> tapAndPause(
    WidgetTester tester,
    Finder finder, {
    int milliseconds = 1200,
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await demoPause(tester, milliseconds);
  }

  testWidgets('sign up -> login -> logout flow', (WidgetTester tester) async {
    final widget = await createAuthApp();

    // 1. verify-token inicial: sin sesión
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/verify-token'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'message': 'unauthorized'}),
          401,
        ));

    // 2. signup-direct
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/signup-direct'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{}', 201));

    // 3. login
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/login'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessToken': 'mock_token',
            'refreshToken': 'mock_refresh_token',
            'user': {'id': '1'}
          }),
          201,
        ));

    // 4. addUser (database insert)
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('/insert'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{}', 201));

    // 5. getLoggedUser
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('tableName=Users'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode([
            {
              '_id': 'db_user_1',
              'userId': '1',
              'email': 'a@a.com',
              'name': 'One name',
            }
          ]),
          200,
        ));

    // 6. products luego de login
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('tableName=Product'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response('[]', 200));

    // 7. logout
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/logout'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response('{}', 201));

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // =========================
    // Login inicial visible
    // =========================
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Login to access your account'), findsOneWidget);

    // =========================
    // Ir a SignUp
    // =========================
    await tapAndPause(tester, find.text('Create account'), milliseconds: 1500);
    await tester.pumpAndSettle();

    expect(find.text('Sign Up Information'), findsOneWidget);

    // =========================
    // Sign up
    // =========================
    final signUpNameField = find.widgetWithText(TextFormField, 'Name');
    final signUpEmailField =
        find.widgetWithText(TextFormField, 'Email address');
    final signUpPasswordField = find.widgetWithText(TextFormField, 'Password');
    final signUpConfirmPasswordField =
        find.widgetWithText(TextFormField, 'Confirm password');

    await tester.enterText(signUpNameField, 'One name');
    await tester.enterText(signUpEmailField, 'a@a.com');
    await tester.enterText(signUpPasswordField, 'ThePassword!1');
    await tester.enterText(signUpConfirmPasswordField, 'ThePassword!1');

    await tapAndPause(tester, find.widgetWithText(FilledButton, 'Submit'),
        milliseconds: 1500);
    await tester.pumpAndSettle();

    expect(find.textContaining('User created successfully'), findsOneWidget);

    verify(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
                  (uri) => uri.toString().contains('/signup-direct'))),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).called(1);

    // =========================
    // Volver a login
    // =========================
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    // =========================
    // Login
    // =========================
    final loginEmailField = find.widgetWithText(TextFormField, 'Email address');
    final loginPasswordField = find.widgetWithText(TextFormField, 'Password');

    await tester.enterText(loginEmailField, 'a@a.com');
    await tester.enterText(loginPasswordField, 'ThePassword!1');

    await tapAndPause(tester, find.widgetWithText(FilledButton, 'Login'),
        milliseconds: 1500);
    await tester.pumpAndSettle();

    verify(() => mockHttpClient.post(
          any(that: predicate<Uri>((uri) => uri.toString().contains('/login'))),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).called(greaterThanOrEqualTo(1));

    // =========================
    // Debe entrar a la lista
    // =========================
    expect(find.byType(ListProductPage), findsOneWidget);
    expect(find.text('Welcome One name'), findsOneWidget);

    // =========================
    // Logout
    // =========================
    await tapAndPause(tester, find.byIcon(Icons.exit_to_app),
        milliseconds: 1500);
    await tester.pumpAndSettle();

    verify(() => mockHttpClient.post(
          any(
              that:
                  predicate<Uri>((uri) => uri.toString().contains('/logout'))),
          headers: any(named: 'headers'),
        )).called(1);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('login and add product flow', (WidgetTester tester) async {
    final widget = await createAuthApp();

    var productGetCount = 0;

    // 1. verify-token inicial: sin sesión
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/verify-token'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'message': 'unauthorized'}),
          401,
        ));

    // 2. login
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) => uri.toString().contains('/login'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessToken': 'mock_token',
            'refreshToken': 'mock_refresh_token',
            'user': {'id': '1'}
          }),
          201,
        ));

    // 3. getLoggedUser
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('tableName=Users'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode([
            {
              '_id': 'db_user_1',
              'userId': '1',
              'email': 'a@a.com',
              'name': 'One name',
            }
          ]),
          200,
        ));

    // 4. getProducts secuencial:
    //    - primera vez: vacío
    //    - segunda vez: producto agregado
    when(() => mockHttpClient.get(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('tableName=Product'),
          )),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async {
      productGetCount++;

      if (productGetCount == 1) {
        return http.Response('[]', 200);
      }

      return http.Response(
        jsonEncode([
          {
            "_id": "1",
            "name": "New Laptop",
            "description": "A powerful laptop for developers",
            "quantity": 10
          }
        ]),
        200,
      );
    });

    // 5. add product
    when(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('/insert'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{}', 201));

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // =========================
    // Login
    // =========================
    expect(find.text('Login to access your account'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'a@a.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'ThePassword!1',
    );

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    verify(() => mockHttpClient.post(
          any(that: predicate<Uri>((uri) => uri.toString().contains('/login'))),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).called(1);

    // =========================
    // Lista inicial
    // =========================
    expect(find.byType(ListProductPage), findsOneWidget);
    expect(find.text('Welcome One name'), findsOneWidget);
    expect(find.text('New Laptop'), findsNothing);

    // =========================
    // Ir a AddProductPage
    // =========================
    await tester.tap(find.byKey(const Key('add_product_fab')));
    await tester.pumpAndSettle();

    expect(find.byType(ListProductPage), findsNothing);

    // =========================
    // Llenar formulario
    // =========================
    await tester.enterText(
      find.byKey(const Key('nameField')),
      'New Laptop',
    );
    await tester.enterText(
      find.byKey(const Key('descField')),
      'A powerful laptop for developers',
    );
    await tester.enterText(
      find.byKey(const Key('quantityField')),
      '10',
    );

    // =========================
    // Guardar
    // =========================
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    verify(() => mockHttpClient.post(
          any(
              that: predicate<Uri>(
            (uri) =>
                uri.toString().contains('/database/') &&
                uri.toString().contains('/insert'),
          )),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).called(1);

    // =========================
    // Verificar regreso a lista
    // =========================
    expect(find.byType(ListProductPage), findsOneWidget);

    // =========================
    // Verificar producto agregado
    // =========================
    expect(find.text('New Laptop'), findsOneWidget);
    expect(find.text('A powerful laptop for developers'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets(
    'login, add two products, edit first, delete first, then delete all',
    (WidgetTester tester) async {
      final widget = await createAuthApp();

      final backendProducts = <Map<String, dynamic>>[];
      var nextId = 1;

      // =========================
      // AUTH STUBS
      // =========================

      // verify-token inicial: sin sesión
      when(() => mockHttpClient.get(
            any(
                that: predicate<Uri>(
              (uri) => uri.toString().contains('/verify-token'),
            )),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'message': 'unauthorized'}),
            401,
          ));

      // login
      when(() => mockHttpClient.post(
            any(
                that: predicate<Uri>(
              (uri) => uri.toString().contains('/login'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'accessToken': 'mock_token',
              'refreshToken': 'mock_refresh_token',
              'user': {'id': '1'}
            }),
            201,
          ));

      // getLoggedUser
      when(() => mockHttpClient.get(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('tableName=Users'),
            )),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode([
              {
                '_id': 'db_user_1',
                'userId': '1',
                'email': 'a@a.com',
                'name': 'One name',
              }
            ]),
            200,
          ));

      // =========================
      // PRODUCT GET
      // =========================
      when(() => mockHttpClient.get(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('tableName=Product'),
            )),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(backendProducts),
            200,
          ));

      // =========================
      // PRODUCT INSERT
      // =========================
      when(() => mockHttpClient.post(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/insert'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as String;
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final records = decoded['records'] as List<dynamic>;
        final record = Map<String, dynamic>.from(records.first);

        backendProducts.add({
          '_id': '${nextId++}',
          ...record,
        });

        return http.Response('{}', 201);
      });

      // =========================
      // PRODUCT UPDATE
      // =========================
      when(() => mockHttpClient.put(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/update'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as String;
        final decoded = jsonDecode(body) as Map<String, dynamic>;

        final idValue = decoded['idValue'].toString();
        final updates = Map<String, dynamic>.from(decoded['updates']);

        final index =
            backendProducts.indexWhere((p) => p['_id'].toString() == idValue);

        if (index != -1) {
          backendProducts[index] = {
            ...backendProducts[index],
            ...updates,
          };
        }

        return http.Response('{}', 200);
      });

      // =========================
      // PRODUCT DELETE
      // =========================
      when(() => mockHttpClient.delete(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/delete'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as String;
        final decoded = jsonDecode(body) as Map<String, dynamic>;

        final idValue = decoded['idValue'].toString();
        backendProducts.removeWhere((p) => p['_id'].toString() == idValue);

        return http.Response('{}', 200);
      });

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // =========================
      // LOGIN
      // =========================
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'a@a.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'ThePassword!1',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ListProductPage), findsOneWidget);
      expect(find.text('Welcome One name'), findsOneWidget);

      // =========================
      // ADD PRODUCT 1
      // =========================
      await tester.tap(find.byKey(const Key('add_product_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('nameField')),
        'Laptop',
      );
      await tester.enterText(
        find.byKey(const Key('descField')),
        'Gaming laptop',
      );
      await tester.enterText(
        find.byKey(const Key('quantityField')),
        '5',
      );
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Gaming laptop'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // =========================
      // ADD PRODUCT 2
      // =========================
      await tester.tap(find.byKey(const Key('add_product_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('nameField')),
        'Mouse',
      );
      await tester.enterText(
        find.byKey(const Key('descField')),
        'Wireless mouse',
      );
      await tester.enterText(
        find.byKey(const Key('quantityField')),
        '10',
      );
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Gaming laptop'), findsOneWidget);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Wireless mouse'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      // =========================
      // EDIT FIRST PRODUCT
      // =========================
      await tester.tap(find.byKey(const Key('product_tile_1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_name_field')),
        'Laptop Pro',
      );
      await tester.enterText(
        find.byKey(const Key('edit_desc_field')),
        'High-end gaming laptop',
      );
      await tester.enterText(
        find.byKey(const Key('edit_quantity_field')),
        '7',
      );

      await tester.tap(find.byKey(const Key('update_button')));
      await tester.pumpAndSettle();

      expect(find.text('Laptop Pro'), findsOneWidget);
      expect(find.text('High-end gaming laptop'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Gaming laptop'), findsNothing);

      // =========================
      // DELETE FIRST PRODUCT
      // =========================
      await tester.drag(
        find.byKey(const Key('product_dismiss_1')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laptop Pro'), findsNothing);
      expect(find.text('High-end gaming laptop'), findsNothing);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Wireless mouse'), findsOneWidget);

      // =========================
      // DELETE ALL
      // =========================
      await tester.tap(find.byKey(const Key('delete_all_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);

      // =========================
      // OPTIONAL VERIFY CALLS
      // =========================
      verify(() => mockHttpClient.post(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/insert'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(2);

      verify(() => mockHttpClient.put(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/update'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);

      verify(() => mockHttpClient.delete(
            any(
                that: predicate<Uri>(
              (uri) =>
                  uri.toString().contains('/database/') &&
                  uri.toString().contains('/delete'),
            )),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(greaterThanOrEqualTo(2));
    },
  );
}
