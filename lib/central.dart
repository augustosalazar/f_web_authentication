import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/auth/ui/controller/authentication_controller.dart';
import 'features/auth/ui/pages/login_page.dart';
import 'features/product/ui/pages/list_product_page.dart';

class Central extends StatelessWidget {
  const Central({super.key});

  @override
  Widget build(BuildContext context) {
    AuthenticationController authenticationController = Get.find();
    return Obx(() => authenticationController.isLogged
        ? const ListProductPage()
        : const LoginPage());
  }
}
