import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';
import 'package:f_web_authentication/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_web_authentication/features/product/domain/models/product.dart';
import 'package:f_web_authentication/features/product/ui/pages/list_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationController extends GetxService
    with Mock
    implements AuthenticationController {}

class MockProductController extends GetxService
    with Mock
    implements ProductController {}

class FakeProduct extends Fake implements Product {}

void main() {
  late MockAuthenticationController mockAuthController;
  late MockProductController mockProductController;

  late RxBool logged;
  late RxBool isLoading;
  late RxList<Product> products;

  setUpAll(() {
    registerFallbackValue(FakeProduct());
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockAuthController = MockAuthenticationController();
    mockProductController = MockProductController();

    // Estado reactivo real, pero externo al mock
    logged = true.obs;
    isLoading = false.obs;
    products = <Product>[
      Product(id: '1', name: 'Product 1', description: 'Desc 1', quantity: 10),
      Product(id: '2', name: 'Product 2', description: 'Desc 2', quantity: 20),
    ].obs;

    // =========================
    // AuthenticationController
    // =========================
    when(() => mockAuthController.logged).thenReturn(logged);

    when(() => mockAuthController.loggedUser).thenReturn(
      AuthenticationUser(
        id: '1',
        email: 'test@test.com',
        name: 'Test User',
      ),
    );

    when(() => mockAuthController.logOut()).thenAnswer((_) async {
      logged.value = false;
    });

    // =========================
    // ProductController
    // =========================
    when(() => mockProductController.isLoading).thenReturn(isLoading);

    // products en tu controlador devuelve List<Product>
    when(() => mockProductController.products).thenAnswer((_) => products);

    when(() => mockProductController.getProducts()).thenAnswer((_) async {});

    when(() => mockProductController.deleteProduct(any()))
        .thenAnswer((invocation) async {
      final product = invocation.positionalArguments[0] as Product;
      products.removeWhere((element) => element.id == product.id);
    });

    when(() => mockProductController.deleteProducts()).thenAnswer((_) async {
      products.clear();
    });

    Get.put<AuthenticationController>(mockAuthController);
    Get.put<ProductController>(mockProductController);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidgetUnderTest() {
    return const GetMaterialApp(
      home: ListProductPage(),
    );
  }

  testWidgets('ListProductPage shows product list correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Test User'), findsOneWidget);

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Desc 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Desc 2'), findsOneWidget);

    expect(find.text('10'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('ListProductPage loading state', (WidgetTester tester) async {
    isLoading.value = true;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Delete all products updates the UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    verify(() => mockProductController.deleteProducts()).called(1);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Logout button calls logOut', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.exit_to_app));
    await tester.pump();

    verify(() => mockAuthController.logOut()).called(1);
    expect(logged.value, false);
  });
}
