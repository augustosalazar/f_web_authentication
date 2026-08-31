import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/stored_file.dart';
import '../viewmodels/files_controller.dart';

/// Archivos del proyecto: subir, listar, descargar y borrar.
///
/// Los bytes van directo entre el dispositivo y el bucket; Roble solo firma el
/// permiso. Por eso subir un archivo grande no pasa por el servidor y no hay
/// aquí ningún límite impuesto por la app.
class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FilesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isUploading.value
              ? null
              : () => _elegirYSubir(context, controller),
          icon: controller.isUploading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(controller.isUploading.value ? 'Subiendo…' : 'Subir archivo'),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (controller.error.isNotEmpty)
              _Aviso(mensaje: controller.error.value),
            Expanded(
              child: controller.files.isEmpty
                  ? const _Vacio()
                  : ListView.separated(
                      itemCount: controller.files.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _Fila(
                        file: controller.files[i],
                        controller: controller,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _elegirYSubir(
    BuildContext context,
    FilesController controller,
  ) async {
    // `withData` porque el paquete sube desde memoria: en web no hay ruta de
    // archivo que abrir, así que pedir los bytes es el único camino que sirve
    // en las dos plataformas.
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    final archivo = resultado?.files.singleOrNull;
    final bytes = archivo?.bytes;
    if (archivo == null || bytes == null) return;

    await controller.upload(
      fileName: archivo.name,
      data: bytes,
      mimeType: _tipoPorExtension(archivo.extension),
    );

    if (context.mounted && controller.error.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${archivo.name} subido')),
      );
    }
  }

  /// El servidor no adivina el tipo: lo declara quien sube. Sin esto, todo
  /// llega como binario y el navegador descarga en vez de mostrar.
  String? _tipoPorExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      default:
        return null;
    }
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.file, required this.controller});

  final StoredFile file;
  final FilesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ocupado = controller.busyFileId.value == file.id;

      return ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(file.name),
        subtitle: Text([
          if (file.readableSize != null) file.readableSize!,
          '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
        ].join(' · ')),
        trailing: ocupado
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Descargar',
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () => _descargar(context),
                  ),
                  IconButton(
                    tooltip: 'Borrar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmarBorrado(context),
                  ),
                ],
              ),
      );
    });
  }

  Future<void> _descargar(BuildContext context) async {
    final bytes = await controller.download(file);
    if (!context.mounted || bytes == null) return;

    // La app no guarda en disco: esto es una demostración de que los bytes
    // llegan. Guardarlos donde el usuario quiera es cosa de cada plataforma.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${file.name}: ${bytes.lengthInBytes} bytes descargados')),
    );
  }

  Future<void> _confirmarBorrado(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar archivo?'),
        content: Text('"${file.name}" se borra del bucket y no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );

    if (confirmado == true) await controller.remove(file);
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        mensaje,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Todavía no hay archivos.\nSube uno con el botón de abajo.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
