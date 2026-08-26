import 'package:flutter/material.dart';

import '../../domain/models/message.dart';

/// Burbuja de mensaje, con la cola del lado que corresponde.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
  });

  final Message message;

  /// Lo envié yo: a la derecha, en verde.
  final bool isMine;

  /// Solo en el primero de una tanda del mismo autor, como en WhatsApp.
  final bool showSender;

  static const _mine = Color(0xFFDCF8C6);
  static const _theirs = Colors.white;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(12);

    return Padding(
      padding: EdgeInsets.only(
        top: showSender ? 8 : 2,
        bottom: 2,
        left: isMine ? 64 : 8,
        right: isMine ? 8 : 64,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: isMine ? _mine : _theirs,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              // La esquina recta hace de cola y marca el lado sin dibujar nada.
              bottomLeft: isMine ? radius : Radius.zero,
              bottomRight: isMine ? Radius.zero : radius,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSender && !isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.sender,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _senderColor(message.sender),
                    ),
                  ),
                ),
              Text(
                message.content,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111B21)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _hhmm(message.sentAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667781),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hhmm(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  /// Un color estable por autor, para distinguirlos de un vistazo.
  static Color _senderColor(String sender) {
    const palette = [
      Color(0xFF1F7A8C), Color(0xFF9C4221), Color(0xFF6B21A8),
      Color(0xFF166534), Color(0xFF9D174D), Color(0xFF1E40AF),
    ];
    return palette[sender.hashCode.abs() % palette.length];
  }
}
