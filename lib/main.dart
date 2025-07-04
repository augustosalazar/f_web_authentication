import 'package:f_web_authentication/features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'central.dart';
import 'features/auth/data/datasources/remote/authentication_source_service.dart';
import 'features/auth/data/datasources/remote/i_authentication_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/use_case/authentication_usecase.dart';
import 'features/auth/ui/controller/authentication_controller.dart';
import 'features/product/data/datasources/i_remote_product_source.dart';
import 'features/product/data/datasources/remote_product_source.dart';
import 'features/product/data/repositories/product_repository.dart';
import 'features/product/domain/repositories/i_product_repository.dart';
import 'features/product/domain/use_case/user_usecase.dart';
import 'features/product/ui/controller/product_controller.dart';

void main() {
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(
      showColors: true,
    ),
  );

  //Get.put<IAuthenticationSource>(AuthenticationSource());
  Get.put<IAuthenticationSource>(AuthenticationSourceServiceRoble());
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationUseCase(Get.find()));
  Get.put(AuthenticationController());

  Get.put<IRemoteUserSource>(RemoteProductSource());
  Get.put<IProductRepository>(ProductRepository(Get.find()));
  Get.put(UserUseCase(Get.find()));
  Get.lazyPut(() => ProductController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Web service Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Central(),
    );
  }
}
