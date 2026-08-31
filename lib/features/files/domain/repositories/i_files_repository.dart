import 'dart:typed_data';

import '../models/stored_file.dart';

abstract class IFilesRepository {
  /// Los archivos ya subidos, del más reciente al más antiguo.
  Future<List<StoredFile>> list();

  /// Sube [data] y devuelve el identificador que le dio el servidor.
  Future<String> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  });

  /// Los bytes de un archivo ya subido.
  Future<Uint8List> download(String fileId);

  Future<void> remove(String fileId);
}
