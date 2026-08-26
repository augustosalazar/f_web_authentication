import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/message.dart';
import 'i_chat_source.dart';

/// Los mensajes viven en una tabla normal; lo único distinto es que además se
/// escucha.
class ChatSourceRoble with UiLoggy implements IChatSource {
  ChatSourceRoble(this._database);

  static const _table = 'Message';

  final RobleApiDataBase _database;

  @override
  Future<List<Message>> history() async {
    final records = await _database.read(_table);
    final messages = records.map(Message.fromJson).toList();

    // La lectura no garantiza orden, y en un chat el orden es el contenido.
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  @override
  Future<void> send(Message message) async {
    loggy.debug('Enviando mensaje');
    await _database.create(_table, message.toJsonNew());
  }

  @override
  Stream<Message> incoming() {
    // Solo altas: editar o borrar mensajes no es parte de esto, y pedir las
    // tres operaciones traería cambios que la interfaz no sabría colocar.
    return _database
        .watchTable(_table, events: [RobleChangeType.insert])
        .where((change) => change.record != null)
        .map((change) => Message.fromJson(change.record!));
  }

  @override
  Future<String> currentSender() async {
    final profile = await _database.currentUser();
    return profile['email'] as String? ?? 'desconocido';
  }
}
