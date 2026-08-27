import 'package:flutter_test/flutter_test.dart';

import 'package:f_web_authentication/features/auth/domain/models/authentication_user.dart';

Map<String, dynamic> perfil([Map<String, dynamic> extra = const {}]) => {
      'id': 'us-1',
      'userId': '9c1e',
      'email': 'ana@correo.com',
      'name': 'Ana',
      ...extra,
    };

void main() {
  group('rol', () {
    test('se lee del perfil', () {
      final u = AuthenticationUser.fromJson(perfil({'role': 'admin'}));

      expect(u.role, 'admin');
    });

    test('sin rol asignado queda en null, no revienta', () {
      final u = AuthenticationUser.fromJson(perfil({'role': null}));

      // El servidor manda null cuando nadie le asignó rol. No es un error.
      expect(u.role, isNull);
      expect(u.email, 'ana@correo.com');
    });

    test('un backend anterior a v1.7.8 tampoco revienta', () {
      // Antes de esa versión el perfil no traía el campo siquiera.
      final u = AuthenticationUser.fromJson(perfil());

      expect(u.role, isNull);
    });

    test('viaja en toJson', () {
      final u = AuthenticationUser(
        id: '9c1e',
        email: 'ana@correo.com',
        name: 'Ana',
        role: 'admin',
      );

      expect(u.toJson()['role'], 'admin');
    });
  });

  group('identidad', () {
    test('prefiere userId sobre id', () {
      final u = AuthenticationUser.fromJson(perfil());

      // `id` es la fila del perfil; `userId` es el usuario, y es el que
      // referencian las tablas de la app. Coger el otro se nota tarde.
      expect(u.id, '9c1e');
    });
  });
}
