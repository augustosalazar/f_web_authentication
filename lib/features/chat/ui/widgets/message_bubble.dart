import 'package:flutter/material.dart';

import '../../domain/models/message.dart';

/// Burbuja de mensaje, con la cola del lado que corresponde.
///
/// Los colores salen del tema de la app. Antes eran los de WhatsApp, fijos:
/// se veían bien en claro y desaparecían en oscuro, que es el modo que la app
/// toma del sistema.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
  });

  final Message message;

  /// Lo envié yo: a la derecha, y con el color de acento del tema.
  final bool isMine;

  /// Solo en el primero de una tanda del mismo autor, como en WhatsApp.
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const radius = Radius.circular(12);

    final background =
        isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        isMine ? scheme.onPrimaryContainer : scheme.onSurface;

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
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              // La esquina recta hace de cola y marca el lado sin dibujar nada.
              bottomLeft: isMine ? radius : Radius.zero,
              bottomRight: isMine ? Radius.zero : radius,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
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
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _senderColor(context, message.sender),
                    ),
                  ),
                ),
              Text(
                message.content,
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _hhmm(message.sentAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.6),
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
  ///
  /// El tono sale del nombre y la luminosidad del tema: una paleta fija de
  /// tonos oscuros se lee sobre fondo claro y se pierde sobre uno oscuro.
  static Color _senderColor(BuildContext context, String sender) {
    final hue = (sender.hashCode.abs() % 360).toDouble();
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, hue, 0.55, oscuro ? 0.75 : 0.35).toColor();
  }
}
