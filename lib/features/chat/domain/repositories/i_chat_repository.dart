import '../models/message.dart';

abstract class IChatRepository {
  /// Los mensajes que ya existen, del más antiguo al más reciente.
  Future<List<Message>> history();

  /// Envía uno. Llega de vuelta por [changes], como el de cualquier otro.
  Future<void> send(String content);

  /// Mensajes nuevos, según van ocurriendo.
  Stream<Message> changes();

  /// Correo de quien está usando la app, para saber qué mensajes son suyos.
  Future<String> currentSender();
}
