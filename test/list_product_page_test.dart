import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/ui/pages/list_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

// Mock del AuthenticationController
class MockAuthenticationCon extends GetxService
    with Mock
    implements AuthenticationController {
  @override
  final logged = true.obs;

  @override
  Future<void> onInit() async {
    // No hacer nada en el mock
  }

  @override
  AuthenticationUser? get loggedUser => AuthenticationUser(
        id: '1',
        email: 'test@test.com',
        name: 'Test User',
      );

  @override
  Future<void> logOut() async {
    logged.value = false;
  }
}

// Mock del ProductController
class MockProductController extends GetxService
    with Mock
    implements ProductController {
  final _products = <Product>[
    Product(id: '1', name: 'Product 1', description: 'Desc 1', quantity: 10),
    Product(id: '2', name: 'Product 2', description: 'Desc 2', quantity: 20),
  ].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  List<Product> get products => _products;

  @override
  Future<void> getProducts() async {
    isLoading.value = true;
    // Simular retraso si se desea, pero para pruebas unitarias es mejor instantáneo
    isLoading.value = false;
  }

  @override
  Future<void> deleteProduct(Product p) async {
    _products.removeWhere((element) => element.id == p.id);
  }

  @override
  Future<void> deleteProducts() async {
    _products.clear();
  }
}

void main() {
  late MockAuthenticationCon mockAuthController;
  late MockProductController mockProductController;

  setUp(() {
    mockAuthController = MockAuthenticationCon();
    mockProductController = MockProductController();

    Get.put<AuthenticationController>(mockAuthController);
    Get.put<ProductController>(mockProductController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ListProductPage shows product list correctly',
      (WidgetTester tester) async {
    // Cargamos el widget
    await tester.pumpWidget(const GetMaterialApp(
      home: ListProductPage(),
    ));

    // Verificamos el título del AppBar que usa el nombre del usuario mockeado
    expect(find.text("Welcome Test User"), findsOneWidget);

    // Verificamos que los productos del mock aparezcan en la lista
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Desc 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Desc 2'), findsOneWidget);

    // Verificamos las cantidades
    expect(find.text('10'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('ListProductPage loading state', (WidgetTester tester) async {
    mockProductController.isLoading.value = true;

    await tester.pumpWidget(const GetMaterialApp(
      home: ListProductPage(),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Delete all products updates the UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: ListProductPage(),
    ));

    // Verificamos que hay productos inicialmente
    expect(find.byType(ListTile), findsNWidgets(2));

    // Presionamos el botón de borrar todo (el icono de delete en el AppBar)
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verificamos que la lista esté vacía
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Logout button calls logOut', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: ListProductPage(),
    ));

    // Presionamos el botón de logout
    await tester.tap(find.byIcon(Icons.exit_to_app));
    await tester.pump();

    // Verificamos que el estado de logged cambió en el mock
    expect(mockAuthController.logged.value, false);
  });
}
