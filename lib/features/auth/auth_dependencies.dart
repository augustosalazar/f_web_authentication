import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'data/datasources/remote/authentication_source_service_roble.dart';
import 'data/datasources/remote/i_authentication_source.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'ui/viewmodels/authentication_controller.dart';

/// Registra la autenticación en GetX.
///
/// Está aparte de `main` por lo mismo que el chat y los archivos: que cada
/// clase funcione suelta no dice nada sobre si el contenedor sabe construirlas.
///
/// Aquí no se usa `lazyPut` con `fenix` sino `put`: la sesión la mira [Central]
/// desde que arranca la app, así que estos tres se construyen de una vez y no
/// hay nada que reconstruir al cambiar de ruta.
void registerAuth(RobleApiDataBase roble) {
  Get.put<IAuthenticationSource>(
    AuthenticationSourceServiceRoble(roble),
    permanent: true,
  );
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationController(Get.find()));
}
