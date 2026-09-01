import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/error_message.dart';

import '../../domain/models/message.dart';
import '../../domain/repositories/i_chat_repository.dart';

class ChatController extends GetxController {
  ChatController(this._chat);

  final IChatRepository _chat;

  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxString error = ''.obs;

  /// Correo propio: decide de qué lado se pinta cada burbuja.
  final RxString me = ''.obs;

  StreamSubscription<Message>? _subscription;

  @override
  void onInit() {
    super.onInit();
    unawaited(start());
  }

  @override
  void onClose() {
    // Cancelar avisa al servidor: sin esto la suscripción sigue viva y el
    // socket abierto después de salir de la pantalla.
    unawaited(_subscription?.cancel());
    super.onClose();
  }

  Future<void> start() async {
    isLoading.value = true;
    error.value = '';
    try {
      me.value = await _chat.currentSender();

      // Se escucha antes de leer el historial. Al revés, un mensaje enviado
      // entre la lectura y la suscripción no aparecería en ninguno de los dos.
      _subscription ??= _chat.changes().listen(
            _receive,
            onError: (Object e) => error.value = errorMessage(e),
          );

      // assignAll copia; asignar `.value` haría que la RxList envolviera la
      // lista que devolvió la fuente, y si esa es inmutable —una constante, o
      // un List.unmodifiable— el primer mensaje que llegue revienta y el chat
      // deja de recibir para siempre.
      messages.assignAll(await _chat.history());
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || isSending.value) return;

    isSending.value = true;
    error.value = '';
    try {
      await _chat.send(content);
      // No se añade a la lista aquí: el propio mensaje vuelve por la
      // suscripción como cualquier otro. Añadirlo además lo mostraría dos
      // veces, y esperar a que vuelva es también la prueba de que el tiempo
      // real funciona.
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      isSending.value = false;
    }
  }

  void _receive(Message message) {
    // El slot de replicación puede entregar algo ocurrido justo antes de
    // suscribirse, así que un mensaje puede llegar dos veces.
    if (messages.any((m) => m.id == message.id)) return;
    messages.add(message);
  }
}
