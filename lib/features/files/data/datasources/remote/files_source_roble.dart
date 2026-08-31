import 'dart:typed_data';

import 'package:roble/roble.dart';

import '../../../domain/models/stored_file.dart';
import 'i_files_source.dart';

/// Archivos contra el bucket del proyecto, a través de `db.files`.
///
/// Los bytes no pasan por Roble: el paquete pide una URL firmada y sube o baja
/// directo contra el bucket. Por eso no hay aquí ningún límite de tamaño que
/// imponga la app —el que manda es el del bucket—.
class FilesSourceRoble implements IFilesSource {
  FilesSourceRoble(this._database);

  final RobleApiDataBase _database;

  @override
  Future<List<StoredFile>> list() async {
    final archivos = await _database.files.list();

    final ordenados = archivos.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ordenados
        .map((f) => StoredFile(
              id: f.fileId,
              name: f.fileName,
              uploadedAt: f.createdAt,
              mimeType: f.mimeType,
              sizeBytes: f.sizeBytes,
            ))
        .toList(growable: false);
  }

  @override
  Future<String> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  }) =>
      _database.files.upload(
        fileName: fileName,
        data: data,
        mimeType: mimeType,
      );

  @override
  Future<Uint8List> download(String fileId) => _database.files.download(fileId);

  @override
  Future<void> remove(String fileId) => _database.files.remove(fileId);
}
