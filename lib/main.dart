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
import 'core/local_preferences_secured.dart';
import 'core/local_preferences_shared.dart';
import 'core/roble_client.dart';
import 'features/auth/auth_dependencies.dart';
import 'features/auth/ui/viewmodels/authentication_controller.dart';
import 'features/chat/chat_dependencies.dart';
import 'features/files/files_dependencies.dart';
import 'features/product/domain/repositories/i_product_repository.dart';
import 'features/product/product_dependencies.dart';

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

  // Cada feature se registra sola. El orden importa solo en que el cliente de
  // Roble y las preferencias ya tienen que estar puestos.
  registerAuth(roble);
  registerProduct(roble);
  registerChat(roble);
  registerFiles(roble);

  clearCachesOnLogOut();

  runApp(const MyApp());
}

/// Al cerrar sesión, tirar lo que se guardó de la sesión anterior.
///
/// Esto vive aquí y no dentro de la autenticación a propósito. Quien cierra la
/// sesión no tiene por qué saber que existen los productos, ni que tienen
/// caché: si lo supiera, cada módulo nuevo con algo que limpiar habría que
/// añadirlo a mano dentro de `logOut`, y cerrar sesión reventaría en cuanto ese
/// módulo no estuviera registrado. `main` es el único sitio que conoce a todos,
/// así que la política de «qué se limpia al salir» es suya.
void clearCachesOnLogOut() {
  final auth = Get.find<AuthenticationController>();

  ever<bool>(auth.logged, (isLogged) {
    if (isLogged) return;
    Get.find<IProductRepository>().clearCache();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'Flutter Roble with Feature Clean Architecture',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const Central(),
    );
  }
}
