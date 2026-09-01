import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/session_expiry.dart';
import '../../domain/models/stored_file.dart';
import '../../domain/repositories/i_files_repository.dart';

class FilesController extends GetxController {
  FilesController(this._repository);

  final IFilesRepository _repository;

  final RxList<StoredFile> _files = <StoredFile>[].obs;
  List<StoredFile> get files => _files;

  final RxBool isLoading = false.obs;

  /// Qué archivo está ocupado, para deshabilitar solo su fila y no la lista
  /// entera mientras se baja o se borra.
  final RxString busyFileId = ''.obs;

  final RxBool isUploading = false.obs;

  /// Vacío mientras todo va bien.
  ///
  /// El caso que más se va a dar en clase es que el proyecto no tenga bucket
  /// conectado. El servidor lo dice con un mensaje que ya explica qué hacer y
  /// dónde, así que se muestra tal cual en vez de traducirlo a un «error al
  /// cargar» que manda a buscar el fallo en el sitio equivocado.
  final RxString error = ''.obs;

  @override
  void onInit() {
    load();
    super.onInit();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      _files.assignAll(await _repository.list());
    } catch (e) {
      logError('FilesController: no se pudo listar', e);
      error.value = reportError(e, fallback: 'No se pudo completar la operación.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  }) async {
    isUploading.value = true;
    error.value = '';
    try {
      await _repository.upload(fileName: fileName, data: data, mimeType: mimeType);
      // Se relee en vez de añadir a mano: el servidor decide el id y la fecha,
      // y adivinarlos aquí deja la lista distinta de lo que hay de verdad.
      await load();
    } catch (e) {
      logError('FilesController: no se pudo subir $fileName', e);
      error.value = reportError(e, fallback: 'No se pudo completar la operación.');
    } finally {
      isUploading.value = false;
    }
  }

  Future<Uint8List?> download(StoredFile file) async {
    busyFileId.value = file.id;
    error.value = '';
    try {
      return await _repository.download(file.id);
    } catch (e) {
      logError('FilesController: no se pudo bajar ${file.name}', e);
      error.value = reportError(e, fallback: 'No se pudo completar la operación.');
      return null;
    } finally {
      busyFileId.value = '';
    }
  }

  Future<void> remove(StoredFile file) async {
    busyFileId.value = file.id;
    error.value = '';
    try {
      await _repository.remove(file.id);
      _files.removeWhere((f) => f.id == file.id);
    } catch (e) {
      logError('FilesController: no se pudo borrar ${file.name}', e);
      error.value = reportError(e, fallback: 'No se pudo completar la operación.');
    } finally {
      busyFileId.value = '';
    }
  }
}
