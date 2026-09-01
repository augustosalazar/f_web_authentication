import 'package:f_web_authentication/features/files/domain/models/stored_file.dart';
import 'package:flutter_test/flutter_test.dart';

StoredFile conTamano(int? bytes) => StoredFile(
      id: 'a',
      name: 'foto.png',
      uploadedAt: DateTime(2026, 8, 26),
      sizeBytes: bytes,
    );

void main() {
  group('tamaño legible', () {
    test('en bytes cuando es pequeño', () {
      expect(conTamano(512).readableSize, '512 B');
    });

    test('en KB a partir de 1024', () {
      expect(conTamano(1024).readableSize, '1.0 KB');
      expect(conTamano(2560).readableSize, '2.5 KB');
    });

    test('en MB a partir de un mega', () {
      expect(conTamano(1024 * 1024).readableSize, '1.0 MB');
      expect(conTamano((2.5 * 1024 * 1024).round()).readableSize, '2.5 MB');
    });

    test('justo en el salto de unidad', () {
      // 1023 todavía son bytes; 1024 ya es un KB. El límite se equivoca fácil
      // en un sentido o en el otro.
      expect(conTamano(1023).readableSize, '1023 B');
      expect(conTamano(1024 * 1024 - 1).readableSize, '1024.0 KB');
    });

    test('vacío es cero bytes, no «desconocido»', () {
      expect(conTamano(0).readableSize, '0 B');
    });

    test('sin tamaño informado devuelve null', () {
      // El servidor puede no decirlo, y eso no es lo mismo que un archivo
      // vacío: la interfaz debe poder distinguirlo para no pintar «0 B».
      expect(conTamano(null).readableSize, isNull);
    });
  });
}
