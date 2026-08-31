import 'dart:typed_data';

import '../../../domain/models/stored_file.dart';

abstract class IFilesSource {
  Future<List<StoredFile>> list();

  Future<String> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  });

  Future<Uint8List> download(String fileId);

  Future<void> remove(String fileId);
}
