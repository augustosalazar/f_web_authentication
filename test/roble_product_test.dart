import 'dart:async';
import 'dart:convert';

import 'package:f_web_authentication/core/i_local_preferences.dart';
import 'package:f_web_authentication/core/roble_exception.dart';
import 'package:f_web_authentication/features/product/data/datasources/remote_product_roble_source.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
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

// ✅ Mock mejorado
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
  Future<http.Response> put(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      super.noSuchMethod(
        Invocation.method(#put, [
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
  Future<http.Response> patch(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      super.noSuchMethod(
        Invocation.method(#patch, [
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
  Future<http.Response> head(Uri? url, {Map<String, String>? headers}) =>
      super.noSuchMethod(
        Invocation.method(#head, [url], {#headers: headers}),
        returnValue: Future.value(http.Response('', 200)),
        returnValueForMissingStub: Future.value(http.Response('', 200)),
      );

  @override
  void close() => super.noSuchMethod(
        Invocation.method(#close, []),
        returnValueForMissingStub: null,
      );
}

// ✅ Mock preferences
class MockLocalPreferences extends GetxService
    with Mock
    implements ILocalPreferences {
  @override
  Future<String?> getString(String key) async {
    if (key == 'token') return 'mock_token';
    return null;
  }
}

void main() {
  late RemoteProductRobleSource dataSource;
  late MockHttpClient mockHttpClient;
  late MockLocalPreferences mockPreferences;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockPreferences = MockLocalPreferences();

    Get.put<ILocalPreferences>(mockPreferences);

    dataSource = RemoteProductRobleSource(mockHttpClient);
  });

  tearDown(() {
    Get.reset();
  });

  group('RemoteProductRobleSource Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(
          fileName: ".env"); // o ".env.test" si tienes uno separado
    });

    // =========================
    // ✅ SUCCESS CASES
    // =========================

    test('getProducts returns list when status is 200', () async {
      final responseBody = jsonEncode([
        {
          "_id": "1",
          "name": "Laptop",
          "description": "Powerful laptop",
          "quantity": 5
        }
      ]);

      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await dataSource.getProducts();

      expect(result, isA<List<Product>>());
      expect(result.length, 1);
      expect(result[0].name, 'Laptop');
      expect(result[0].description, 'Powerful laptop');
      expect(result[0].quantity, 5);

      verify(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('addProduct returns true when status is 201', () async {
      final product = Product(
        name: 'Mouse',
        description: 'Desc',
        quantity: 1,
      );

      when(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Created', 201));

      final result = await dataSource.addProduct(product);

      expect(result, true);

      verify(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('getProducts returns empty list when response is empty array',
        () async {
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('[]', 200));

      final result = await dataSource.getProducts();

      expect(result, isEmpty);
    });

    test('updateProduct returns true when status is 200', () async {
      final product = Product(
        id: '1',
        name: 'Updated Mouse',
        description: 'Updated Desc',
        quantity: 10,
      );

      when(mockHttpClient.put(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Updated', 200));

      final result = await dataSource.updateProduct(product);

      expect(result, true);
    });

    test('deleteProduct returns true when status is 200', () async {
      final product =
          Product(id: '1', name: 'Mouse', description: 'Desc', quantity: 1);

      // ✅ Ahora funciona porque DELETE está implementado
      when(mockHttpClient.delete(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Deleted', 200));

      final result = await dataSource.deleteProduct(product);

      expect(result, true);
    });

    // =========================
    // ❌ ERROR CASES
    // =========================

    test('getProducts throws RobleException on 500 error', () async {
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({"message": "Server error"}),
            500,
          ));

      expect(
        () => dataSource.getProducts(),
        throwsA(isA<RobleException>()),
      );
    });

    test('getProducts throws RobleException with correct message', () async {
      const errorMessage = "Database connection failed";

      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({"message": errorMessage}),
            503,
          ));

      expect(
        () => dataSource.getProducts(),
        throwsA(predicate(
            (e) => e is RobleException && e.message.contains(errorMessage))),
      );
    });

    test('addProduct throws RobleException on 400 error', () async {
      final product = Product(
        name: 'Mouse',
        description: 'Desc',
        quantity: 1,
      );

      when(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({"message": "Insert failed"}),
            400,
          ));

      expect(
        () => dataSource.addProduct(product),
        throwsA(predicate(
            (e) => e is RobleException && e.message.contains("Insert failed"))),
      );
    });

    test('getProducts throws RobleException on network error', () async {
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenThrow(http.ClientException('Network error'));

      expect(
        () => dataSource.getProducts(),
        throwsA(isA<RobleException>()),
      );
    });

    test('addProduct throws RobleException on timeout', () async {
      final product = Product(
        name: 'Mouse',
        description: 'Desc',
        quantity: 1,
      );

      when(mockHttpClient.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(TimeoutException('Connection timeout'));

      expect(
        () => dataSource.addProduct(product),
        throwsA(isA<RobleException>()),
      );
    });

    test('getProducts handles malformed JSON', () async {
      when(mockHttpClient.get(
        argThat(isAUri),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Invalid JSON', 200));

      expect(
        () => dataSource.getProducts(),
        throwsA(isA<RobleException>()),
      );
    });
  });
}
