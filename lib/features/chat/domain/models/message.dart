/// Un mensaje del chat.
class Message {
  const Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.sentAt,
  });

  final String id;
  final String content;

  /// Correo de quien lo envió. Es lo que decide de qué lado se pinta.
  final String sender;

  final DateTime sentAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['_id']?.toString() ?? '',
        content: json['content'] as String? ?? '',
        sender: json['sender'] as String? ?? '',
        // El servidor la pone por omisión, pero un registro viejo o a medio
        // escribir no debe tumbar la lista.
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  /// Sin `_id` ni `sentAt`: los pone la base de datos.
  Map<String, dynamic> toJsonNew() => {
        'content': content,
        'sender': sender,
      };

  @override
  bool operator ==(Object other) => other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
