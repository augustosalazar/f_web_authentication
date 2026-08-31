import 'dart:typed_data';

import '../../domain/models/stored_file.dart';
import '../../domain/repositories/i_files_repository.dart';
import '../datasources/remote/i_files_source.dart';

class FilesRepository implements IFilesRepository {
  FilesRepository(this._source);

  final IFilesSource _source;

  @override
  Future<List<StoredFile>> list() => _source.list();

  @override
  Future<String> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  }) =>
      _source.upload(fileName: fileName, data: data, mimeType: mimeType);

  @override
  Future<Uint8List> download(String fileId) => _source.download(fileId);

  @override
  Future<void> remove(String fileId) => _source.remove(fileId);
}
