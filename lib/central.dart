import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/auth/ui/controller/authentication_controller.dart';
import 'features/auth/ui/pages/login_page.dart';
import 'features/product/ui/pages/product_list_page.dart';

class Central extends StatelessWidget {
  const Central({super.key});

  @override
  Widget build(BuildContext context) {
    AuthenticationController authenticationController = Get.find();
    return Obx(() => authenticationController.isLogged
        ? const ProductListPage()
        : const LoginPage());
  }
}
