import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/files/domain/repositories/i_files_repository.dart';
import 'package:f_web_authentication/features/files/files_dependencies.dart';
import 'package:f_web_authentication/features/files/ui/viewmodels/files_controller.dart';

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
/// construirlas. Lo mismo que se prueba en el chat, y por el mismo motivo: los
/// tres registros llevan `fenix` para poder volver a entrar a la pantalla.
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

  test('el contenedor sabe construir los archivos enteros', () {
    registerFiles(roble);

    // Resolver el controlador arrastra el repositorio y el origen: si alguno
    // no estuviera registrado, esto lanza igual que en la app.
    expect(Get.find<FilesController>(), isA<FilesController>());
    expect(Get.find<IFilesRepository>(), isA<IFilesRepository>());
  });

  test('se puede volver a entrar a los archivos después de salir', () {
    registerFiles(roble);
    Get.find<FilesController>();

    // Lo que GetX hace al descartar la ruta: borra el controlador y lo que se
    // resolvió con él.
    Get.delete<FilesController>(force: true);
    Get.delete<IFilesRepository>(force: true);

    // Sin fenix, la fábrica ya se habría consumido y esto fallaría.
    expect(Get.find<FilesController>(), isA<FilesController>());
  });
}
