/// Un mensaje del chat.
///
/// Vive en el árbol JSON, no en una tabla: no hay columnas declaradas, así que
/// la forma la fija esta clase y nada más.
class Message {
  const Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.sentAt,
  });

  /// Clave que generó el servidor al insertarlo.
  ///
  /// Empieza por la marca de tiempo del servidor en base 36, así que ordenar
  /// las claves ordena los mensajes por cuándo llegaron —sin depender del
  /// reloj de quien escribe, que en un chat entre dos máquinas no coincide.
  final String id;

  final String content;

  /// Correo de quien lo envió. Es lo que decide de qué lado se pinta.
  final String sender;

  /// La pone quien envía: el árbol JSON no tiene valores por omisión. Solo se
  /// muestra; el orden lo da [id].
  final DateTime sentAt;

  /// Reconstruye un mensaje a partir de una entrada del árbol: la clave es el
  /// identificador y el valor, el contenido.
  factory Message.fromEntry(String key, Object? value) {
    final json = value is Map ? value : const {};
    return Message(
      id: key,
      content: json['content'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      // Un mensaje a medio escribir no debe tumbar la lista entera.
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Sin `id`: lo genera el servidor al hacer push.
  Map<String, dynamic> toJson() => {
        'content': content,
        'sender': sender,
        'sentAt': sentAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) => other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
