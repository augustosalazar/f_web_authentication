import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'data/datasources/remote/files_source_roble.dart';
import 'data/datasources/remote/i_files_source.dart';
import 'data/repositories/files_repository.dart';
import 'domain/repositories/i_files_repository.dart';
import 'ui/viewmodels/files_controller.dart';

/// Registra los archivos en GetX.
///
/// `fenix` en los tres por lo mismo que en el chat: al salir de la pantalla
/// GetX descarta el controlador y limpia lo que se resolvió durante esa ruta,
/// y sin `fenix` la fábrica ya está consumida, así que volver a entrar falla
/// con «"IFilesRepository" not found».
void registerFiles(RobleApiDataBase roble) {
  Get.lazyPut<IFilesSource>(() => FilesSourceRoble(roble), fenix: true);
  Get.lazyPut<IFilesRepository>(() => FilesRepository(Get.find()), fenix: true);
  Get.lazyPut(() => FilesController(Get.find()), fenix: true);
}
