import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roble/roble.dart';

import 'package:f_web_authentication/features/chat/data/datasources/remote/chat_source_roble.dart';
import 'package:f_web_authentication/features/chat/domain/models/message.dart';

/// Almacén en memoria, para no tocar el llavero del sistema.
class MemoriaStorage implements RobleTokenStorage {
  final _datos = <String, String>{};

  @override
  Future<String?> getItem(String key) async => _datos[key];

  @override
  Future<void> setItem(String key, String value) async => _datos[key] = value;

  @override
  Future<void> removeItem(String key) async => _datos.remove(key);
}

void main() {
  late List<http.Request> peticiones;

  ChatSourceRoble fuente(http.Response Function(http.Request) responder) {
    peticiones = [];
    return ChatSourceRoble(RobleApiDataBase(
      config: RobleApiConfig.fromContract(
        baseUrl: 'https://roble-api.test',
        contractId: 'proyecto_ab12',
      ),
      storage: MemoriaStorage(),
      client: MockClient((req) async {
        peticiones.add(req);
        return responder(req);
      }),
    ));
  }

  http.Response json200(Object body) =>
      http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});

  Map<String, dynamic> mensaje(String texto) => {
        'content': texto,
        'sender': 'ana@correo.com',
        'sentAt': '2026-08-26T12:00:00.000Z',
      };

  group('historial', () {
    test('lee la colección del árbol, no una tabla', () async {
      final chat = fuente((_) => json200({'k1': mensaje('hola')}));

      await chat.history();

      // El árbol JSON cuelga de /realtime, fuera del esquema del proyecto.
      expect(peticiones.single.url.path, '/realtime/proyecto_ab12/mensajes');
    });

    test('ordena por clave, no por la fecha que puso cada cliente', () async {
      // La clave la genera el servidor y empieza por su marca de tiempo; la
      // fecha la pone quien envía, y aquí va al revés a propósito.
      final chat = fuente((_) => json200({
            'zz_segundo': {...mensaje('segundo'), 'sentAt': '2020-01-01T00:00:00Z'},
            'aa_primero': {...mensaje('primero'), 'sentAt': '2030-01-01T00:00:00Z'},
          }));

      final historial = await chat.history();

      expect(historial.map((m) => m.content), ['primero', 'segundo']);
    });

    test('un chat sin estrenar no es un error', () async {
      // La colección no existe hasta que entra el primer mensaje, y hasta
      // entonces el servidor responde 404: propagarlo dejaría la pantalla en
      // error en vez de vacía.
      final chat = fuente((_) => http.Response('{"message":"not found"}', 404,
          headers: {'content-type': 'application/json'}));

      expect(await chat.history(), isEmpty);
    });

    test('un fallo de verdad sí sube', () async {
      final chat = fuente((_) => http.Response('{"message":"boom"}', 500,
          headers: {'content-type': 'application/json'}));

      await expectLater(chat.history(), throwsA(isA<RobleApiHttpException>()));
    });
  });

  group('envío', () {
    test('hace push: la clave la genera el servidor', () async {
      final chat = fuente((_) => json200({'name': 'k9'}));

      await chat.send(Message(
        id: '',
        content: 'hola',
        sender: 'ana@correo.com',
        sentAt: DateTime.utc(2026, 8, 26, 12),
      ));

      final req = peticiones.single;
      expect(req.method, 'POST');
      expect(jsonDecode(req.body), {
        'content': 'hola',
        'sender': 'ana@correo.com',
        'sentAt': '2026-08-26T12:00:00.000Z',
      });
    });
  });
}
