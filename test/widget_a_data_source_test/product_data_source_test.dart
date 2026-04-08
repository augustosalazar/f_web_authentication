import 'dart:convert';

import 'package:f_web_authentication/core/i_local_preferences.dart';
import 'package:f_web_authentication/features/auth/data/datasources/remote/i_authentication_source.dart';
import 'package:f_web_authentication/features/auth/data/repositories/auth_repository.dart';
import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/data/datasources/cache/local_product_cache_source.dart';
import 'package:f_web_authentication/features/product/data/datasources/remote/i_product_source.dart';
import 'package:f_web_authentication/features/product/data/datasources/remote/remote_product_roble_source.dart';
import 'package:f_web_authentication/features/product/data/repositories/product_repository.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:f_web_authentication/features/product/ui/pages/add_product_page.dart';
import 'package:f_web_authentication/features/product/ui/pages/list_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:f_web_authentication/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

// =========================
// MOCKS / FAKES
// =========================

class MockHttpClient extends Mock implements http.Client {}

class MockLocalPreferences extends Mock implements ILocalPreferences {}

class MockAuthenticationSource extends Mock implements IAuthenticationSource {}

class MockLocalProductCacheSource extends Mock
    implements LocalProductCacheSource {}

class FakeUri extends Fake implements Uri {}

class FakeProduct extends Fake implements Product {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockLocalPreferences mockLocalPreferences;
  late MockAuthenticationSource mockAuthSource;
  late MockLocalProductCacheSource mockLocalCacheSource;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');

    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeProduct());
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockHttpClient = MockHttpClient();
    mockLocalPreferences = MockLocalPreferences();
    mockAuthSource = MockAuthenticationSource();
    mockLocalCacheSource = MockLocalProductCacheSource();

    // =========================
    // LocalPreferences
    // =========================
    when(() => mockLocalPreferences.getString('token'))
        .thenAnswer((_) async => 'mock_token');

    when(() => mockLocalPreferences.getString('user')).thenAnswer(
      (_) async => jsonEncode({
        'id': '1',
        'email': 'test@test.com',
        'name': 'Test User',
      }),
    );

    when(() => mockLocalPreferences.getString(any()))
        .thenAnswer((_) async => null);

    when(() => mockLocalPreferences.setString(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockLocalPreferences.remove(any())).thenAnswer((_) async {});

    when(() => mockLocalPreferences.clear()).thenAnswer((_) async {});

    // =========================
    // AuthenticationSource
    // =========================
    when(() => mockAuthSource.login(any(), any())).thenAnswer((_) async {});

    when(() => mockAuthSource.logOut()).thenAnswer((_) async {});

    when(() => mockAuthSource.verifyToken()).thenAnswer((_) async => true);

    when(() => mockAuthSource.getLoggedUser()).thenAnswer(
      (_) async => AuthenticationUser(
        id: '1',
        email: 'test@test.com',
        name: 'Test User',
      ),
    );

    // =========================
    // LocalProductCacheSource
    // =========================
    when(() => mockLocalCacheSource.isCacheValid())
        .thenAnswer((_) async => false);

    when(() => mockLocalCacheSource.cacheProductData(any()))
        .thenAnswer((_) async {});

    when(() => mockLocalCacheSource.getCachedProductData())
        .thenThrow(Exception('Cache error'));

    when(() => mockLocalCacheSource.clearCache()).thenAnswer((_) async {});

    // =========================
    // HTTP Client default stubs
    // =========================
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 201));

    when(() => mockHttpClient.delete(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 200));

    // =========================
    // Inyección DI
    // =========================
    Get.put<ILocalPreferences>(mockLocalPreferences);
    Get.put<IAuthenticationSource>(mockAuthSource);

    Get.put<http.Client>(
      mockHttpClient,
      tag: 'apiClient',
      permanent: true,
    );

    Get.put<IAuthRepository>(AuthRepository(Get.find()));
    Get.put<AuthenticationController>(AuthenticationController(Get.find()));

    Get.lazyPut<IProductSource>(
      () => RemoteProductRobleSource(Get.find<http.Client>(tag: 'apiClient')),
    );

    Get.lazyPut<LocalProductCacheSource>(() => mockLocalCacheSource);

    Get.lazyPut<IProductRepository>(
      () => ProductRepository(Get.find(), Get.find()),
    );

    Get.lazyPut<ProductController>(() => ProductController(Get.find()));
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidgetUnderTest(Widget home) {
    return GetMaterialApp(
      scaffoldMessengerKey: messengerKey,
      home: home,
    );
  }

  group('Integration Tests - Product flow', () {
    testWidgets('Shows products from mocked HTTP response',
        (WidgetTester tester) async {
      final responseBody = jsonEncode([
        {
          "_id": "1",
          "name": "Laptop",
          "description": "High-end laptop",
          "quantity": 5
        },
        {
          "_id": "2",
          "name": "Mouse",
          "description": "Wireless mouse",
          "quantity": 15
        }
      ]);

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('High-end laptop'), findsOneWidget);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Wireless mouse'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .called(greaterThanOrEqualTo(1));
    });

    testWidgets('Shows empty state when no products',
        (WidgetTester tester) async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('[]', 200));

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Shows loading indicator while fetching products',
        (WidgetTester tester) async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return http.Response('[]', 200);
      });

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Delete all products makes request and refreshes UI',
        (WidgetTester tester) async {
      var getCallCount = 0;

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        getCallCount++;

        if (getCallCount == 1) {
          return http.Response(
            jsonEncode([
              {
                "_id": "1",
                "name": "Laptop",
                "description": "High-end laptop",
                "quantity": 5
              }
            ]),
            200,
          );
        }

        return http.Response('[]', 200);
      });

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_all_button')));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsNothing);
    });

    testWidgets('Swipe product deletes it and refreshes UI',
        (WidgetTester tester) async {
      var getCallCount = 0;

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        getCallCount++;

        if (getCallCount == 1) {
          return http.Response(
            jsonEncode([
              {
                "_id": "1",
                "name": "Laptop",
                "description": "High-end laptop",
                "quantity": 5
              }
            ]),
            200,
          );
        }

        return http.Response('[]', 200);
      });

      when(() => mockHttpClient.delete(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Deleted', 200));

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);

      final dismissible = find.byKey(const Key('product_dismiss_1'));
      expect(dismissible, findsOneWidget);

      await tester.drag(dismissible, const Offset(500, 0));
      await tester.pumpAndSettle();

      verify(() => mockHttpClient.delete(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);

      expect(find.text('Laptop'), findsNothing);
    });

    testWidgets('Add product FAB navigation and creation flow',
        (WidgetTester tester) async {
      var getCallCount = 0;

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        getCallCount++;

        if (getCallCount == 1) {
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

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Created', 201));

      await tester.pumpWidget(createWidgetUnderTest(const ListProductPage()));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(AddProductPage), findsOneWidget);

      expect(find.byKey(const Key('nameField')), findsOneWidget);
      expect(find.byKey(const Key('descField')), findsOneWidget);
      expect(find.byKey(const Key('quantityField')), findsOneWidget);
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('nameField')), 'New Laptop');
      await tester.enterText(
        find.byKey(const Key('descField')),
        'A powerful laptop for developers',
      );
      await tester.enterText(find.byKey(const Key('quantityField')), '10');

      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);

      expect(find.byType(ListProductPage), findsOneWidget);
      expect(find.byType(AddProductPage), findsNothing);

      expect(find.text('New Laptop'), findsOneWidget);
      expect(find.text('A powerful laptop for developers'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });
}
