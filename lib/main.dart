import 'package:f_web_authentication/core/local_preferences_secured.dart';
import 'package:f_web_authentication/core/local_preferences_shared.dart';
import 'package:f_web_authentication/features/product/data/datasources/cache/local_product_cache_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'central.dart';
import 'core/app_theme.dart';
import 'core/i_local_preferences.dart';
import 'core/refresh_client.dart';
import 'features/auth/data/datasources/remote/authentication_source_service_roble.dart';
import 'features/auth/data/datasources/remote/i_authentication_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/ui/viewmodels/authentication_controller.dart';
import 'features/product/data/datasources/remote/i_product_source.dart';
import 'features/product/data/datasources/remote/remote_product_roble_source.dart';
import 'features/product/data/repositories/product_repository.dart';
import 'features/product/domain/repositories/i_product_repository.dart';
import 'features/product/ui/viewmodels/product_controller.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  await dotenv.load(fileName: ".env");
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(
      showColors: true,
    ),
  );

  if (!kIsWeb) {
    Get.put<ILocalPreferences>(LocalPreferencesSecured());
  } else {
    Get.put<ILocalPreferences>(LocalPreferencesShared());
  }

  Get.lazyPut<IAuthenticationSource>(
    () => AuthenticationSourceServiceRoble(),
    fenix: true,
  );

  Get.put<http.Client>(
    RefreshClient(http.Client(), Get.find<IAuthenticationSource>()),
    tag: 'apiClient',
    permanent: true,
  );

  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationController(Get.find()));

  Get.lazyPut<IProductSource>(
      () => RemoteProductRobleSource(Get.find<http.Client>(tag: 'apiClient')));

  Get.lazyPut<LocalProductCacheSource>(
      () => LocalProductCacheSource(Get.find()));

  Get.lazyPut<IProductRepository>(
      () => ProductRepository(Get.find(), Get.find()));
  Get.lazyPut(() => ProductController(Get.find()));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'Web service Demo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const Central(),
    );
  }
}
