import 'package:f_web_authentication/features/product/ui/pages/add_product_page.dart';
import 'package:f_web_authentication/features/product/ui/viewmodels/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockProductController extends GetxController
    with Mock
    implements ProductController {}

void main() {
  late MockProductController mockProductController;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    mockProductController = MockProductController();
    when(() => mockProductController.isLoading).thenReturn(false.obs);
    when(() => mockProductController.products).thenReturn([]);
    when(() => mockProductController.addProduct(any(), any(), any()))
        .thenAnswer((_) async {});

    Get.put<ProductController>(mockProductController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('debe llamar addProduct al presionar Save', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: AddProductPage(),
      ),
    );

    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);

    await tester.enterText(textFields.at(0), 'New Laptop');
    await tester.enterText(textFields.at(1), 'High performance laptop');
    await tester.enterText(textFields.at(2), '5');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    verify(() => mockProductController.addProduct(
          'New Laptop',
          'High performance laptop',
          '5',
        )).called(1);
  });
}
