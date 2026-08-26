import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/product/data/datasources/remote/remote_product_roble_source.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/domain/repositories/i_product_repository.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';

class MemoriaStorage implements RobleTokenStorage {
  final _datos = <String, String>{};

  @override
  Future<String?> getItem(String key) async => _datos[key];

  @override
  Future<void> setItem(String key, String value) async => _datos[key] = value;

  @override
  Future<void> removeItem(String key) async => _datos.remove(key);
}

Product producto(String name, {int quantity = 0}) =>
    Product(id: name, name: name, description: '-', quantity: quantity);

/// Repositorio de mentira: distingue el catálogo completo del filtrado.
class RepoFalso implements IProductRepository {
  RepoFalso({
    this.todos = const [],
    this.sinInventario = const [],
    this.fallaElFiltro,
  });

  final List<Product> todos;
  final List<Product> sinInventario;
  final Object? fallaElFiltro;

  int refrescos = 0;

  @override
  Future<List<Product>> getProducts() async => todos;

  @override
  Future<List<Product>> forceRefresh() async {
    refrescos++;
    return todos;
  }

  @override
  Future<List<Product>> getOutOfStockProducts() async {
    if (fallaElFiltro != null) throw fallaElFiltro!;
    return sinInventario;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('fuente', () {
    late List<http.Request> peticiones;

    RemoteProductRobleSource fuente(http.Response Function(http.Request) r) {
      peticiones = [];
      return RemoteProductRobleSource(RobleApiDataBase(
        config: RobleApiConfig.fromContract(
          baseUrl: 'https://roble-api.test',
          contractId: 'proyecto_ab12',
        ),
        storage: MemoriaStorage(),
        client: MockClient((req) async {
          peticiones.add(req);
          return r(req);
        }),
      ));
    }

    http.Response json(Object body, [int code = 200]) =>
        http.Response(jsonEncode(body), code,
            headers: {'content-type': 'application/json'});

    test('ejecuta la consulta guardada por nombre', () async {
      final s = fuente((_) => json({'success': true, 'rows': [], 'fields': []}));

      await s.getOutOfStockProducts();

      // Por nombre y no por UUID: el nombre se lee en la consola y sobrevive a
      // recrear la consulta.
      expect(
        Uri.decodeFull(peticiones.single.url.path),
        endsWith('/saved-queries/by-name/productosSinInventario/execute'),
      );
    });

    test('convierte las filas en productos', () async {
      final s = fuente((_) => json({
            'success': true,
            'rows': [
              {'_id': '1', 'name': 'Café', 'description': 'De Nariño', 'quantity': 0},
            ],
            'fields': [],
          }));

      final lista = await s.getOutOfStockProducts();

      expect(lista.single.name, 'Café');
      expect(lista.single.quantity, 0);
    });

    test('acepta una cantidad que llega como texto', () async {
      final s = fuente((_) => json({
            'success': true,
            'rows': [
              {'_id': '1', 'name': 'Café', 'quantity': '0'},
            ],
            'fields': [],
          }));

      // Una consulta guardada devuelve lo que pida su SQL, y Postgres entrega
      // bigint y numeric como texto: sin convertir, esto reventaba con un
      // TypeError en vez de mostrar la lista.
      expect((await s.getOutOfStockProducts()).single.quantity, 0);
    });

    test('si la consulta no existe lo dice por su nombre', () async {
      final s = fuente((_) => json({'message': 'Not found'}, 404));

      await expectLater(
        s.getOutOfStockProducts(),
        throwsA(predicate((e) =>
            e is RobleApiException &&
            e.message.contains('productosSinInventario'))),
      );
    });
  });

  group('filtro', () {
    test('apagado trae el catálogo entero', () async {
      final c = ProductController(RepoFalso(todos: [producto('a'), producto('b')]));

      await c.getProducts();

      expect(c.products, hasLength(2));
      expect(c.onlyOutOfStock.value, isFalse);
    });

    test('encendido trae solo lo de la consulta guardada', () async {
      final c = ProductController(RepoFalso(
        todos: [producto('a'), producto('b')],
        sinInventario: [producto('b')],
      ));
      await c.getProducts();

      await c.toggleOutOfStock();

      expect(c.products.single.name, 'b');
      expect(c.onlyOutOfStock.value, isTrue);
    });

    test('se puede volver a quitar', () async {
      final c = ProductController(RepoFalso(
        todos: [producto('a'), producto('b')],
        sinInventario: [producto('b')],
      ));

      await c.toggleOutOfStock();
      await c.toggleOutOfStock();

      expect(c.products, hasLength(2));
    });

    test('refrescar con el filtro puesto no devuelve el catálogo completo',
        () async {
      final repo = RepoFalso(
        todos: [producto('a'), producto('b')],
        sinInventario: [producto('b')],
      );
      final c = ProductController(repo);
      await c.toggleOutOfStock();

      await c.forceRefresh();

      // Tirar para refrescar por la vía normal traería todo con el filtro aún
      // marcado, que es peor que no refrescar.
      expect(c.products.single.name, 'b');
      expect(repo.refrescos, 0);
    });

    test('si la consulta falla se avisa y no queda el catálogo viejo', () async {
      final c = ProductController(RepoFalso(
        todos: [producto('a')],
        fallaElFiltro: const RobleApiException('No hay ninguna consulta'),
      ));
      await c.getProducts();

      await c.toggleOutOfStock();

      expect(c.error.value, contains('No hay ninguna consulta'));
      // Dejar la lista anterior mostraría el catálogo completo bajo el filtro.
      expect(c.products, isEmpty);
      expect(c.isLoading.value, isFalse);
    });

    test('quitar el filtro después de un fallo limpia el aviso', () async {
      final c = ProductController(RepoFalso(
        todos: [producto('a')],
        fallaElFiltro: const RobleApiException('no existe'),
      ));

      await c.toggleOutOfStock();
      await c.toggleOutOfStock();

      expect(c.error.value, isEmpty);
      expect(c.products, hasLength(1));
    });
  });
}
