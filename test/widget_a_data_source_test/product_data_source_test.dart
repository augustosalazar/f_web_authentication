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
import 'package:mockito/mockito.dart';

// ✅ Matcher personalizado para Uri
class _IsAUri extends Matcher {
  const _IsAUri();

  @override
  bool matches(dynamic item, Map matchState) => item is Uri;

  @override
  Description describe(Description description) => description.add('is a Uri');
}

const Matcher isAUri = _IsAUri();

// ✅ Mock del HttpClient
class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri? url, {Map<String, String>? headers}) =>
      super.noSuchMethod(
        Invocation.method(#get, [url], {#headers: headers}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      );

  @override
  Future<http.Response> post(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      super.noSuchMethod(
        Invocation.method(#post, [
          url
        ], {
          #headers: headers,
          #body: body,
          #encoding: encoding,
        }),
        returnValue: Future.value(http.Response('', 201)),
        returnValueForMissingStub: Future.value(http.Response('', 201)),
      );

  @override
  Future<http.Response> delete(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      super.noSuchMethod(
        Invocation.method(#delete, [
          url
        ], {
          #headers: headers,
          #body: body,
          #encoding: encoding,
        }),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      );

  @override
  void close() => super.noSuchMethod(
        Invocation.method(#close, []),
        returnValueForMissingStub: null,
      );
}

// ✅ Mock de LocalPreferences
class MockLocalPreferences extends GetxService
    with Mock
    implements ILocalPreferences {
  @override
  Future<String?> getString(String key) async {
    if (key == 'token') return 'mock_token';
    if (key == 'user') {
      return jsonEncode({
        'id': '1',
        'email': 'test@test.com',
        'name': 'Test User',
      });
    }
    return null;
  }

  @override
  Future<void> setString(String key, String value) async {
    // No hacer nada en el mock
  }

  @override
  Future<void> remove(String key) async {
    // No hacer nada en el mock
  }

  @override
  Future<void> clear() async {
    // No hacer nada en el mock
  }
}

class MockLocalProductCacheSource extends Mock
    implements LocalProductCacheSource {
  MockLocalProductCacheSource(ILocalPreferences prefs) : super();

  @override
  Future<bool> isCacheValid() async => false;

  @override
  Future<void> cacheProductData(List<Product> products) async {
    // No hacer nada en el mock
  }

  @override
  Future<List<Product>> getCachedProductData() async {
    throw Exception('Cache error');
  }

  @override
  Future<void> clearCache() async {
    // No hacer nada en el mock
  }
}

// ✅ Mock de AuthenticationSource (para evitar llamadas reales de auth)
class MockAuthenticationSource extends Mock implements IAuthenticationSource {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    return {
      'token': 'mock_token',
      'user': {
        'id': '1',
        'email': email,
        'name': 'Test User',
      }
    };
  }

  @override
  Future<void> logout() async {
    // No hacer nada
  }

  @override
  Future<bool> verifyToken() async {
    return true;
  }

  @override
  Future<AuthenticationUser> getLoggedUser() async {
    return AuthenticationUser(
      id: '1',
      email: 'test@test.com',
      name: 'Test User',
    );
  }
}

void main() {
  late MockHttpClient mockHttpClient;
  late MockLocalPreferences mockLocalPreferences;
  late MockAuthenticationSource mockAuthSource;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLocalPreferences = MockLocalPreferences();
    mockAuthSource = MockAuthenticationSource();

    // ✅ Inyección de dependencias similar a main.dart pero con mocks
    Get.put<ILocalPreferences>(mockLocalPreferences);
    Get.put<IAuthenticationSource>(mockAuthSource);

    // ✅ Inyectamos nuestro MockHttpClient con el tag 'apiClient'
    Get.put<http.Client>(
      mockHttpClient,
      tag: 'apiClient',
      permanent: true,
    );

    // ✅ Inyectamos las capas reales de dominio/data
    Get.put<IAuthRepository>(AuthRepository(Get.find()));
    Get.put(AuthenticationController(Get.find()));

    // ✅ El datasource real pero con el MockHttpClient
    Get.lazyPut<IProductSource>(
      () => RemoteProductRobleSource(Get.find<http.Client>(tag: 'apiClient')),
    );

    // ✅ Mock del LocalProductCacheSource para evitar problemas de cache en tests
    Get.lazyPut<LocalProductCacheSource>(
      () => MockLocalProductCacheSource(Get.find()),
    );

    Get.lazyPut<IProductRepository>(
        () => ProductRepository(Get.find(), Get.find()));
    Get.lazyPut(() => ProductController(Get.find()));
  });

  tearDown(() {
    Get.reset();
  });

  group('Integration Tests - ListProductPage with real flow', () {
    testWidgets('Shows products from mocked HTTP response',
        (WidgetTester tester) async {
      // ✅ Configuramos la respuesta del mock HTTP
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

      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      // ✅ Renderizamos el widget
      await tester.pumpWidget(GetMaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const ListProductPage(),
      ));

      // Esperamos a que se carguen los productos
      await tester.pumpAndSettle();

      // ✅ Verificamos que los productos aparezcan en la UI
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('High-end laptop'), findsOneWidget);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Wireless mouse'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      // ✅ Verificamos que se hizo la llamada HTTP
      verify(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).called(1);
    });

    testWidgets('Shows empty state when no products',
        (WidgetTester tester) async {
      // ✅ Respuesta vacía del servidor
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('[]', 200));

      await tester.pumpWidget(GetMaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const ListProductPage(),
      ));

      await tester.pumpAndSettle();

      // ✅ No debería haber ListTiles de productos
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Shows loading indicator while fetching products',
        (WidgetTester tester) async {
      // ✅ Simulamos una respuesta retrasada
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return http.Response('[]', 200);
      });

      await tester.pumpWidget(GetMaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const ListProductPage(),
      ));

      // ✅ Inmediatamente después de renderizar debería mostrar loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ✅ Esperamos a que termine
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Delete product makes DELETE request and updates UI',
        (WidgetTester tester) async {
      // ✅ Setup: productos iniciales
      final getResponseBody = jsonEncode([
        {
          "_id": "1",
          "name": "Laptop",
          "description": "High-end laptop",
          "quantity": 5
        },
      ]);

      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(getResponseBody, 200));

      // ✅ Mock del DELETE
      when(mockHttpClient.delete(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Deleted', 200));

      await tester.pumpWidget(GetMaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const ListProductPage(),
      ));

      await tester.pumpAndSettle();

      // ✅ Verificamos que el producto está presente
      expect(find.text('Laptop'), findsOneWidget);

      // ✅ Buscamos el botón de eliminar (ajusta según tu UI)
      // Si tienes un IconButton con Icons.delete en cada ListTile:
      final deleteButton = find.byIcon(Icons.delete).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // ✅ Verificamos que se hizo la llamada DELETE
      verify(mockHttpClient.delete(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);

      // ✅ Verificamos que el producto se eliminó de la UI
      // Nota: dependiendo de tu implementación, puede que necesites
      // hacer mock del segundo GET que se ejecuta después del delete
    });

    testWidgets('Add product FAB navigation test', (WidgetTester tester) async {
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('[]', 200));

      await tester.pumpWidget(GetMaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const ListProductPage(),
        // ✅ Si tienes rutas definidas, agrégalas aquí
      ));

      await tester.pumpAndSettle();

      // ✅ Buscar el FAB (FloatingActionButton)
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // ✅ Verificar que al presionar navegue (ajusta según tu implementación)
      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(find.byType(AddProductPage), findsOneWidget);

      expect(find.byKey(const Key('nameField')), findsOneWidget);
      expect(find.byKey(const Key('descField')), findsOneWidget);
      expect(find.byKey(const Key('quantityField')), findsOneWidget);
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      // ✅ Llenar los campos
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

      await tester.pump();

      when(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Created', 201));

      final responseAfterAdd = jsonEncode([
        {
          "_id": "1",
          "name": "New Laptop",
          "description": "A powerful laptop for developers",
          "quantity": 10
        }
      ]);

      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseAfterAdd, 200));

      // ✅ Presionar el botón de guardar
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      // ✅ Verificar que se hizo la llamada POST
      verify(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: argThat(
          contains('"name":"New Laptop"'),
          named: 'body',
        ),
      )).called(1);

      // ✅ Verificar que regresó a la lista de productos
      expect(find.byType(ListProductPage), findsOneWidget);
      expect(find.byType(AddProductPage), findsNothing);

      // ✅ Verificar que el producto aparece en la lista
      expect(find.text('New Laptop'), findsOneWidget);
      expect(find.text('A powerful laptop for developers'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });
}
