import 'package:f_web_authentication/features/product/ui/pages/add_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

// Mock del ProductController
class MockProductController extends GetxService
    with Mock
    implements ProductController {
  bool productAdded = false;
  String? lastAddedName;

  @override
  final RxBool isLoading = false.obs;

  @override
  Future<void> addProduct(String name, String desc, String quantity) async {
    lastAddedName = name;
    productAdded = true;
    return;
  }
}

void main() {
  late MockProductController mockProductController;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    mockProductController = MockProductController();
    Get.put<ProductController>(mockProductController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AddProductPage interactions and save',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: AddProductPage(),
    ));

    // Verificamos elementos iniciales
    expect(find.text('New Product'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Save"), findsOneWidget);

    // Buscamos los campos de texto por su label
    final nameField = find.widgetWithText(TextField, 'Product Name');
    final descField = find.widgetWithText(TextField, 'Product Description');
    final quantityField = find.widgetWithText(TextField, 'Quantity');

    // Ingresamos datos
    await tester.enterText(nameField, 'New Laptop');
    await tester.enterText(descField, 'High performance laptop');
    await tester.enterText(quantityField, '5');

    // Presionamos guardar
    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pump();

    // Verificamos que se llamó al controlador con los datos correctos
    expect(mockProductController.productAdded, true);
    expect(mockProductController.lastAddedName, 'New Laptop');
  });
}
