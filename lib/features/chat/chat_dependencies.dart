import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'data/datasources/remote/chat_source_roble.dart';
import 'data/datasources/remote/i_chat_source.dart';
import 'data/repositories/chat_repository.dart';
import 'domain/repositories/i_chat_repository.dart';
import 'ui/viewmodels/chat_controller.dart';

/// Registra el chat en GetX.
///
/// Está aparte de `main` para poder probarse: que cada clase funcione suelta
/// no dice nada sobre si el contenedor sabe construirlas.
///
/// `fenix` en los tres a propósito. Al salir del chat, GetX descarta el
/// controlador —que es lo que se quiere, porque cancela la suscripción— pero
/// también limpia lo que se resolvió durante esa ruta. Sin `fenix`, `lazyPut`
/// consume su fábrica en la primera instanciación, así que lo descartado ya no
/// se puede reconstruir y al volver a entrar falla con
/// «"IChatRepository" not found».
void registerChat(RobleApiDataBase roble) {
  Get.lazyPut<IChatSource>(() => ChatSourceRoble(roble), fenix: true);
  Get.lazyPut<IChatRepository>(() => ChatRepository(Get.find()), fenix: true);
  Get.lazyPut(() => ChatController(Get.find()), fenix: true);
}
