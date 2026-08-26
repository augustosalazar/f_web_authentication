import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/product/data/datasources/remote/remote_product_roble_source.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/public_catalog_controller.dart';

class MemoriaStorage implements RobleTokenStorage {
  MemoriaStorage([Map<String, String>? inicial]) : _datos = {...?inicial};

  final Map<String, String> _datos;

  @override
  Future<String?> getItem(String key) async => _datos[key];

  @override
  Future<void> setItem(String key, String value) async => _datos[key] = value;

  @override
  Future<void> removeItem(String key) async => _datos.remove(key);
}

/// Repositorio de mentira, para el controlador.
class RepoFalso implements IProductRepository {
  RepoFalso({this.catalogo = const [], this.falla});

  final List<Product> catalogo;
  final Object? falla;
  int lecturas = 0;

  @override
  Future<List<Product>> getPublicProducts() async {
    lecturas++;
    if (falla != null) throw falla!;
    return catalogo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('fuente', () {
    late List<http.Request> peticiones;

    Future<RemoteProductRobleSource> fuente(
      http.Response Function(http.Request) responder,
    ) async {
      peticiones = [];
      final db = RobleApiDataBase(
        config: RobleApiConfig.fromContract(
          baseUrl: 'https://roble-api.test',
          contractId: 'proyecto_ab12',
        ),
        // Con sesión guardada a propósito: así la ausencia del token en la
        // petición prueba algo. Sin sesión no probaría nada.
        storage: MemoriaStorage({
          'roble.session.proyecto_ab12':
              '{"accessToken":"at-1","refreshToken":"rt-1"}',
        }),
        client: MockClient((req) async {
          peticiones.add(req);
          return responder(req);
        }),
      );
      await db.restoreSession(verify: false);
      return RemoteProductRobleSource(db);
    }

    http.Response json(Object body, [int code = 200]) =>
        http.Response(jsonEncode(body), code,
            headers: {'content-type': 'application/json'});

    test('pega a public-read, no a read', () async {
      final s = await fuente((_) => json([]));

      await s.getPublicProducts();

      // `read` sin token da 401: es otro endpoint, no el mismo sin cabecera.
      expect(peticiones.single.url.path, endsWith('/public-read'));
      expect(peticiones.single.url.queryParameters['tableName'], 'Product');
    });

    test('no manda el token aunque haya sesión', () async {
      final s = await fuente((_) => json([]));

      await s.getPublicProducts();

      // Es el sentido de la lectura pública: si viajara el token, la prueba de
      // que la tabla es pública no probaría nada.
      expect(peticiones.single.headers.containsKey('Authorization'), isFalse);
    });

    test('un 403 dice que la tabla no es pública, no que falle el token',
        () async {
      final s = await fuente((_) => json({'message': 'prohibido'}, 403));

      await expectLater(
        s.getPublicProducts(),
        throwsA(predicate((e) =>
            e is RobleApiException && e.message.contains('pública'))),
      );
    });

    test('convierte lo que llega en productos', () async {
      final s = await fuente((_) => json([
            {'_id': '1', 'name': 'Café', 'description': 'De Nariño', 'quantity': 5},
          ]));

      final catalogo = await s.getPublicProducts();

      expect(catalogo.single.name, 'Café');
    });
  });

  group('controlador', () {
    test('carga el catálogo', () async {
      final repo = RepoFalso(catalogo: [
        Product(id: '1', name: 'Café', description: 'De Nariño', quantity: 5),
      ]);
      final c = PublicCatalogController(repo);

      await c.load();

      expect(c.products.single.name, 'Café');
      expect(c.isLoading.value, isFalse);
    });

    test('un fallo se muestra y suelta el indicador', () async {
      final c = PublicCatalogController(
        RepoFalso(falla: const RobleApiException('no es pública')),
      );

      await c.load();

      expect(c.error.value, contains('no es pública'));
      // Si se quedara en true, la pantalla giraría para siempre.
      expect(c.isLoading.value, isFalse);
    });

    test('vacío no es error', () async {
      final c = PublicCatalogController(RepoFalso());

      await c.load();

      // La tabla respondió; simplemente no tiene filas. La pantalla lo dice
      // distinto que un 403, que es lo que hay que poder distinguir.
      expect(c.products, isEmpty);
      expect(c.error.value, isEmpty);
    });

    test('se puede reintentar', () async {
      final repo = RepoFalso();
      final c = PublicCatalogController(repo);

      await c.load();
      await c.load();

      expect(repo.lecturas, 2);
    });
  });

  group('contenedor', () {
    tearDown(Get.reset);

    test('sabe construir el catálogo público', () {
      Get.reset();
      Get.lazyPut<IProductRepository>(() => RepoFalso(), fenix: true);
      Get.lazyPut(() => PublicCatalogController(Get.find()), fenix: true);

      final c = Get.find<PublicCatalogController>();
      Get.delete<PublicCatalogController>(force: true);

      // Sin fenix la fábrica se consume y volver a entrar falla con
      // «not found», que es como reventó el chat.
      expect(c, isA<PublicCatalogController>());
      expect(Get.find<PublicCatalogController>(), isA<PublicCatalogController>());
    });
  });
}
