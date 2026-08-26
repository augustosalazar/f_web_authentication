import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/chat/chat_dependencies.dart';
import 'package:f_web_authentication/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_web_authentication/features/chat/ui/viewmodels/chat_controller.dart';

/// Almacén en memoria, para no tocar el llavero del sistema.
class MemoriaStorage implements RobleTokenStorage {
  final _datos = <String, String>{};

  @override
  Future<String?> getItem(String key) async => _datos[key];

  @override
  Future<void> setItem(String key, String value) async => _datos[key] = value;

  @override
  Future<void> removeItem(String key) async => _datos.remove(key);
}

/// Que cada clase funcione suelta no dice nada sobre si el contenedor sabe
/// construirlas. Esta es la prueba que faltaba cuando la app reventó con
/// «"IChatRepository" not found» mientras las doce del controlador pasaban.
void main() {
  late RobleApiDataBase roble;

  setUp(() {
    Get.reset();
    roble = RobleApiDataBase(
      config: RobleApiConfig.fromContract(
        baseUrl: 'https://roble-api.test',
        contractId: 'proyecto_ab12',
      ),
      storage: MemoriaStorage(),
    );
  });

  tearDown(Get.reset);

  test('el contenedor sabe construir el chat entero', () {
    registerChat(roble);

    // Resolver el controlador arrastra el repositorio y el origen: si alguno
    // no estuviera registrado, esto lanza igual que en la app.
    expect(Get.find<ChatController>(), isA<ChatController>());
    expect(Get.find<IChatRepository>(), isA<IChatRepository>());
  });

  test('se puede volver a entrar al chat después de salir', () {
    registerChat(roble);
    Get.find<ChatController>();

    // Lo que GetX hace al descartar la ruta: borra el controlador y lo que se
    // resolvió con él.
    Get.delete<ChatController>(force: true);
    Get.delete<IChatRepository>(force: true);

    // Sin fenix, la fábrica ya se habría consumido y esto fallaría — que es
    // exactamente lo que ocurría al volver a abrir el chat.
    expect(Get.find<ChatController>(), isA<ChatController>());
  });
}
