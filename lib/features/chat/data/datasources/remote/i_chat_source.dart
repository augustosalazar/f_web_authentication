import '../../../domain/models/message.dart';

abstract class IChatSource {
  Future<List<Message>> history();

  Future<void> send(Message message);

  /// Altas en la tabla de mensajes, en tiempo real.
  Stream<Message> incoming();

  Future<String> currentSender();
}
