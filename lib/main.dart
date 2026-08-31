import 'package:f_web_authentication/core/local_preferences_secured.dart';
import 'package:f_web_authentication/core/local_preferences_shared.dart';
import 'package:f_web_authentication/features/product/data/datasources/cache/local_product_cache_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:roble/roble.dart';
import 'central.dart';
import 'core/app_theme.dart';
import 'core/i_local_preferences.dart';
import 'core/roble_client.dart';
import 'features/chat/chat_dependencies.dart';
import 'features/files/files_dependencies.dart';
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
import 'features/product/ui/viewmodels/public_catalog_controller.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Loggy.initLoggy(
    logPrinter: StreamPrinter(const PrettyDeveloperPrinter()),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );

  final ILocalPreferences preferences =
      kIsWeb ? LocalPreferencesShared() : LocalPreferencesSecured();
  Get.put<ILocalPreferences>(preferences);

  final roble = createRobleClient();
  Get.put<RobleApiDataBase>(roble, permanent: true);

  final authentication = AuthenticationSourceServiceRoble(roble);

  Get.put<IAuthenticationSource>(authentication, permanent: true);

  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationController(Get.find()));

  // fenix en toda la cadena: sin el, GetX consume la fabrica al descartar la
  // ruta y volver a entrar falla con «not found».
  Get.lazyPut<IProductSource>(() => RemoteProductRobleSource(roble),
      fenix: true);

  Get.lazyPut<LocalProductCacheSource>(() => LocalProductCacheSource(Get.find()),
      fenix: true);

  Get.lazyPut<IProductRepository>(() => ProductRepository(Get.find(), Get.find()),
      fenix: true);
  Get.lazyPut(() => ProductController(Get.find()), fenix: true);

  // El catalogo publico va aparte del controlador de productos: se lee sin
  // sesion y sin cache, y no da de alta ni de baja.
  Get.lazyPut(() => PublicCatalogController(Get.find()), fenix: true);

  registerChat(roble);


  registerFiles(roble);
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
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const Central(),
    );
  }
}
