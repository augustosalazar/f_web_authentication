import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

import 'central.dart';
import 'core/app_theme.dart';
import 'core/i_local_preferences.dart';
import 'core/local_preferences_shared.dart';
import 'core/refresh_client.dart';
import 'features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'features/auth/data/datasources/remote/i_authentication_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/use_case/authentication_usecase.dart';
import 'features/auth/ui/controller/authentication_controller.dart';
import 'features/product/data/datasources/i_remote_product_source.dart';
import 'features/product/data/datasources/remote_product_roble_source.dart';
import 'features/product/data/repositories/product_repository.dart';
import 'features/product/domain/repositories/i_product_repository.dart';
import 'features/product/domain/use_case/product_usecase.dart';
import 'features/product/ui/controller/product_controller.dart';

void main() {
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(
      showColors: true,
    ),
  );

  Get.put<ILocalPreferences>(LocalPreferencesShared());

  Get.lazyPut<IAuthenticationSource>(
    () => AuthenticationSourceServiceRoble(),
    fenix: true,
  );

  Get.lazyPut<http.Client>(() {
    final auth = Get.find<IAuthenticationSource>();
    return RefreshClient(http.Client(), auth);
  }, tag: 'apiClient');

  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationUseCase(Get.find()));
  Get.put(AuthenticationController());

  Get.lazyPut<IRemoteUserSource>(() {
    final client = Get.find<http.Client>(tag: 'apiClient');
    return RemoteProductRobleSource(client);
  });
  Get.put<IProductRepository>(ProductRepository(Get.find()));
  Get.put(ProductUseCase(Get.find()));
  Get.lazyPut(() => ProductController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Web service Demo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const Central(),
    );
  }
}
