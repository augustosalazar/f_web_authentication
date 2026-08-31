/// Un archivo guardado en el bucket del proyecto.
///
/// Roble no guarda los bytes: guarda esta ficha y firma URLs temporales para
/// que el archivo viaje directo entre la app y el bucket. Por eso aquí no hay
/// contenido, solo el `id` con el que se pide una de esas URLs.
class StoredFile {
  const StoredFile({
    required this.id,
    required this.name,
    required this.uploadedAt,
    this.mimeType,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime uploadedAt;

  /// Lo declara quien sube; el bucket no lo deduce. Puede faltar.
  final String? mimeType;

  final int? sizeBytes;

  /// Tamaño en unidades legibles, o `null` si el servidor no lo informó.
  String? get readableSize {
    final bytes = sizeBytes;
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
