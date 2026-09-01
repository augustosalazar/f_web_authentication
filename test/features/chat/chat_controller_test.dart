import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:f_web_authentication/features/chat/domain/models/message.dart';
import 'package:f_web_authentication/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_web_authentication/features/chat/ui/viewmodels/chat_controller.dart';

Message message(String id, {String sender = 'ana@correo.com', String text = 'hola'}) =>
    Message(
      id: id,
      content: text,
      sender: sender,
      sentAt: DateTime(2026, 8, 26, 12, 0),
    );

/// Chat de mentira: apunta lo enviado y deja al test entregar lo que llegaría
/// por la suscripción.
class ChatFalso implements IChatRepository {
  ChatFalso({this.historial = const [], this.sender = 'ana@correo.com'});

  final List<Message> historial;
  final String sender;
  final enviados = <String>[];
  final _entrantes = StreamController<Message>.broadcast();

  Object? fallaAlEnviar;
  Object? fallaElHistorial;
  int suscripciones = 0;
  int cancelaciones = 0;

  @override
  Future<List<Message>> history() async {
    if (fallaElHistorial != null) throw fallaElHistorial!;
    return historial;
  }

  @override
  Future<void> send(String content) async {
    if (fallaAlEnviar != null) throw fallaAlEnviar!;
    enviados.add(content);
  }

  @override
  Stream<Message> changes() {
    suscripciones++;
    return _entrantes.stream;
  }

  @override
  Future<String> currentSender() async => sender;

  void entrega(Message m) => _entrantes.add(m);
  void falla(Object e) => _entrantes.addError(e);
  Future<void> cerrar() => _entrantes.close();
}

/// Deja correr el bucle de eventos: la entrega por stream no es síncrona.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late ChatFalso chat;
  late ChatController controller;

  ChatController build(ChatFalso c) => ChatController(c);

  tearDown(() async {
    controller.onClose();
    await chat.cerrar();
  });

  group('arranque', () {
    test('carga el historial y sabe quién soy', () async {
      chat = ChatFalso(historial: [message('1')]);
      controller = build(chat);

      await controller.start();

      expect(controller.messages, hasLength(1));
      expect(controller.me.value, 'ana@correo.com');
    });

    test('se suscribe antes de leer el historial', () async {
      chat = ChatFalso();
      controller = build(chat);

      await controller.start();

      // Al revés, un mensaje enviado entre la lectura y la suscripción no
      // aparecería en ninguno de los dos.
      expect(chat.suscripciones, 1);
    });

    test('un fallo del historial se muestra, no se traga', () async {
      chat = ChatFalso()..fallaElHistorial = Exception('sin red');
      controller = build(chat);

      await controller.start();

      expect(controller.error.value, contains('sin red'));
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('recepción', () {
    test('añade lo que llega por la suscripción', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      chat.entrega(message('nuevo', text: '¿todo bien?'));
      await settle();

      expect(controller.messages.single.content, '¿todo bien?');
    });

    test('no repite un mensaje que llega dos veces', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      chat.entrega(message('m1'));
      chat.entrega(message('m1'));
      await settle();

      // El slot de replicación puede entregar algo ocurrido justo antes de
      // suscribirse, así que un mensaje puede llegar repetido.
      expect(controller.messages, hasLength(1));
    });

    test('no repite uno que ya venía en el historial', () async {
      chat = ChatFalso(historial: [message('m1')]);
      controller = build(chat);
      await controller.start();

      chat.entrega(message('m1'));
      await settle();

      expect(controller.messages, hasLength(1));
    });

    test('un error del stream se muestra sin tumbar el chat', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      chat.falla(Exception('se cayó el socket'));
      await settle();
      chat.entrega(message('m2'));
      await settle();

      expect(controller.error.value, contains('se cayó'));
      // Sigue recibiendo: el error no cerró la suscripción.
      expect(controller.messages, hasLength(1));
    });
  });

  group('envío', () {
    test('manda el texto', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      await controller.send('hola');

      expect(chat.enviados, ['hola']);
    });

    test('no lo añade a la lista: vuelve por la suscripción', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      await controller.send('hola');

      // Añadirlo aquí lo mostraría dos veces cuando vuelva, y esperar a que
      // vuelva es la prueba de que el tiempo real funciona.
      expect(controller.messages, isEmpty);

      chat.entrega(message('m1', text: 'hola'));
      await settle();
      expect(controller.messages, hasLength(1));
    });

    test('ignora el vacío y los espacios', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      await controller.send('   ');
      await controller.send('');

      expect(chat.enviados, isEmpty);
    });

    test('recorta antes de enviar', () async {
      chat = ChatFalso();
      controller = build(chat);
      await controller.start();

      await controller.send('  hola  ');

      expect(chat.enviados, ['hola']);
    });

    test('un fallo al enviar se muestra y libera el botón', () async {
      chat = ChatFalso()..fallaAlEnviar = Exception('sin permisos');
      controller = build(chat);
      await controller.start();

      await controller.send('hola');

      expect(controller.error.value, contains('sin permisos'));
      // Si se quedara en true, el botón no volvería nunca.
      expect(controller.isSending.value, isFalse);
    });
  });
}
