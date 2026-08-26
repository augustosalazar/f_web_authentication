import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/message.dart';
import '../viewmodels/chat_controller.dart';
import '../widgets/message_bubble.dart';

/// Chat en tiempo real, para ver funcionar la suscripción al árbol JSON.
///
/// Nada se añade a la lista al enviar: el mensaje propio vuelve por la
/// suscripción igual que el de cualquier otro, así que si aparece es que el
/// tiempo real funciona de extremo a extremo.
///
/// La disposición es la de WhatsApp, pero los colores son los del tema de la
/// app: fijarlos aquí lo dejaba ilegible en oscuro, que es un modo que la app
/// toma del sistema.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _chat = Get.find();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Al final de la lista cuando llega algo, que es donde mira quien
    // conversa.
    ever<List<Message>>(_chat.messages, (_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    // Se limpia de inmediato: esperar la ida y vuelta hace que la caja se
    // sienta trabada.
    _input.clear();
    await _chat.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    _chat.me.value,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          Obx(() => _chat.error.value.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  color: scheme.errorContainer,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _chat.error.value,
                    key: const Key('chat_error'),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                )),
          Expanded(
            child: Obx(() {
              if (_chat.isLoading.value && _chat.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_chat.messages.isEmpty) {
                return Center(
                  child: Text(
                    'Sin mensajes todavía.\nEscribe el primero.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _chat.messages.length,
                itemBuilder: (context, i) {
                  final message = _chat.messages[i];
                  final previous = i == 0 ? null : _chat.messages[i - 1];
                  return MessageBubble(
                    message: message,
                    isMine: message.sender == _chat.me.value,
                    // Solo en el primero de una tanda del mismo autor.
                    showSender: previous?.sender != message.sender,
                  );
                },
              );
            }),
          ),
          _composer(scheme),
        ],
      ),
    );
  }

  Widget _composer(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        color: scheme.surface,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const Key('chat_input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Obx(() => FloatingActionButton(
                  key: const Key('chat_send'),
                  mini: true,
                  elevation: 1,
                  onPressed: _chat.isSending.value ? null : _send,
                  child: _chat.isSending.value
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimaryContainer,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                )),
          ],
        ),
      ),
    );
  }
}
