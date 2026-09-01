import 'dart:async';
import 'dart:typed_data';

import 'package:f_web_authentication/features/files/domain/models/stored_file.dart';
import 'package:f_web_authentication/features/files/domain/repositories/i_files_repository.dart';
import 'package:f_web_authentication/features/files/ui/viewmodels/files_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

StoredFile archivo(
  String id, {
  String name = 'foto.png',
  DateTime? cuando,
  int? bytes,
}) =>
    StoredFile(
      id: id,
      name: name,
      uploadedAt: cuando ?? DateTime(2026, 8, 26, 12, 0),
      mimeType: 'image/png',
      sizeBytes: bytes,
    );

/// Archivos de mentira: apunta lo que le piden y deja al test decidir qué falla.
class ArchivosFalsos implements IFilesRepository {
  ArchivosFalsos({this.guardados = const []});

  /// Lo que devuelve [list]. Se puede cambiar entre llamadas para comprobar
  /// que el controlador relee en vez de adivinar.
  List<StoredFile> guardados;

  Object? fallaAlListar;
  Object? fallaAlSubir;
  Object? fallaAlBajar;
  Object? fallaAlBorrar;

  /// Se completa a mano: sirve para mirar el estado *mientras* la operación
  /// sigue en marcha, no solo cuando ya terminó.
  Completer<void>? esperaAlBajar;

  int listados = 0;
  final subidos = <String>[];
  final bajados = <String>[];
  final borrados = <String>[];

  @override
  Future<List<StoredFile>> list() async {
    listados++;
    if (fallaAlListar != null) throw fallaAlListar!;
    return guardados;
  }

  @override
  Future<String> upload({
    required String fileName,
    required Uint8List data,
    String? mimeType,
  }) async {
    if (fallaAlSubir != null) throw fallaAlSubir!;
    subidos.add(fileName);
    return 'id-nuevo';
  }

  @override
  Future<Uint8List> download(String fileId) async {
    bajados.add(fileId);
    if (esperaAlBajar != null) await esperaAlBajar!.future;
    if (fallaAlBajar != null) throw fallaAlBajar!;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> remove(String fileId) async {
    if (fallaAlBorrar != null) throw fallaAlBorrar!;
    borrados.add(fileId);
  }
}

/// Deja correr el bucle de eventos.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late ArchivosFalsos archivos;

  /// El controlador ya arrancado: `onInit` pide la lista, como en la app.
  Future<FilesController> build() async {
    final controller = FilesController(archivos)..onInit();
    await settle();
    return controller;
  }

  setUp(() => archivos = ArchivosFalsos());

  group('cargar la lista', () {
    test('la pide al arrancar', () async {
      archivos.guardados = [archivo('a'), archivo('b')];

      final controller = await build();

      expect(controller.files, hasLength(2));
      expect(archivos.listados, 1);
      expect(controller.error.value, isEmpty);
    });

    test('sin archivos no es un error', () async {
      final controller = await build();

      expect(controller.files, isEmpty);
      expect(controller.error.value, isEmpty);
    });

    test('un proyecto sin bucket lo dice con las palabras del servidor',
        () async {
      // Es el caso que más se da en clase. El servidor ya explica qué hacer y
      // dónde; traducirlo a un «error al cargar» mandaría a buscar el fallo en
      // el sitio equivocado.
      archivos.fallaAlListar = const RobleApiException(
          'El proyecto no tiene un bucket conectado. Conéctalo en la consola.');

      final controller = await build();

      expect(controller.error.value, contains('bucket conectado'));
      expect(controller.files, isEmpty);
    });

    test('suelta el indicador tanto si sale bien como si falla', () async {
      archivos.fallaAlListar = const RobleApiException('sin bucket');

      final controller = await build();

      expect(controller.isLoading.value, isFalse);
    });

    test('el aviso de un intento no queda para el siguiente', () async {
      archivos.fallaAlListar = const RobleApiException('sin bucket');
      final controller = await build();
      expect(controller.error.value, isNotEmpty);

      archivos.fallaAlListar = null;
      await controller.load();

      expect(controller.error.value, isEmpty);
    });
  });

  group('subir', () {
    test('relee la lista en vez de añadir a mano lo subido', () async {
      // El servidor decide el id y la fecha; adivinarlos aquí dejaría la lista
      // distinta de lo que hay de verdad.
      final controller = await build();
      archivos.guardados = [archivo('id-nuevo', name: 'nuevo.png')];

      await controller.upload(
        fileName: 'nuevo.png',
        data: Uint8List.fromList([1]),
      );

      expect(archivos.subidos, ['nuevo.png']);
      expect(archivos.listados, 2); // el arranque y la relectura
      expect(controller.files.single.id, 'id-nuevo');
    });

    test('un fallo al subir no toca la lista que ya había', () async {
      archivos.guardados = [archivo('a')];
      final controller = await build();

      archivos.fallaAlSubir = const RobleApiException('El archivo es enorme');
      await controller.upload(
        fileName: 'grande.zip',
        data: Uint8List.fromList([1]),
      );

      expect(controller.error.value, contains('enorme'));
      expect(controller.files.single.id, 'a');
      expect(controller.isUploading.value, isFalse);
    });
  });

  group('bajar', () {
    test('devuelve los bytes', () async {
      archivos.guardados = [archivo('a')];
      final controller = await build();

      final bytes = await controller.download(archivo('a'));

      expect(bytes, [1, 2, 3]);
      expect(archivos.bajados, ['a']);
    });

    test('marca solo la fila que está ocupada', () async {
      // La lista entera no se bloquea: se puede seguir usando el resto
      // mientras uno baja.
      archivos.guardados = [archivo('a'), archivo('b')];
      final controller = await build();

      archivos.esperaAlBajar = Completer<void>();
      final bajando = controller.download(archivo('b'));
      await settle();

      expect(controller.busyFileId.value, 'b');

      archivos.esperaAlBajar!.complete();
      await bajando;

      expect(controller.busyFileId.value, isEmpty);
    });

    test('un fallo devuelve null y libera la fila', () async {
      archivos.guardados = [archivo('a')];
      final controller = await build();

      archivos.fallaAlBajar = const RobleApiException('La URL ya caducó');
      final bytes = await controller.download(archivo('a'));

      expect(bytes, isNull);
      expect(controller.error.value, contains('caducó'));
      expect(controller.busyFileId.value, isEmpty);
    });
  });

  group('borrar', () {
    test('quita la fila sin volver a pedir la lista', () async {
      // Aquí no hace falta releer: se sabe exactamente qué desapareció, y
      // pedir la lista entera por una fila menos es un viaje de más.
      archivos.guardados = [archivo('a'), archivo('b')];
      final controller = await build();

      await controller.remove(archivo('a'));

      expect(archivos.borrados, ['a']);
      expect(controller.files.single.id, 'b');
      expect(archivos.listados, 1);
    });

    test('si el borrado falla la fila sigue ahí', () async {
      // Quitarla igualmente enseñaría una lista que no existe: al recargar
      // volvería a aparecer.
      archivos.guardados = [archivo('a'), archivo('b')];
      final controller = await build();

      archivos.fallaAlBorrar = const RobleApiException('No tienes permiso');
      await controller.remove(archivo('a'));

      expect(controller.files, hasLength(2));
      expect(controller.error.value, contains('permiso'));
      expect(controller.busyFileId.value, isEmpty);
    });
  });

  test('lo que no viene de Roble no se enseña tal cual', () async {
    // Un fallo de la plataforma no le dice nada a quien está mirando, y su
    // texto puede ser cualquier cosa.
    archivos.fallaAlListar = StateError('Bad state: no platform channel');

    final controller = await build();

    expect(controller.error.value, 'No se pudo completar la operación.');
  });
}
