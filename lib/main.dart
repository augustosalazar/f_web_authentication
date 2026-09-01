import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:roble/roble.dart';

import 'app_wiring.dart';
import 'central.dart';
import 'core/app_theme.dart';
import 'core/i_local_preferences.dart';
import 'core/local_preferences_secured.dart';
import 'core/local_preferences_shared.dart';
import 'core/roble_client.dart';
import 'features/auth/auth_dependencies.dart';
import 'features/chat/chat_dependencies.dart';
import 'features/files/files_dependencies.dart';
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

  // Las reglas que cruzan módulos van juntas en app_wiring.dart.
  wireApp();

  runApp(const MyApp());
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
