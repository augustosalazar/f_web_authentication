import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import '../../../domain/models/message.dart';
import 'i_chat_source.dart';

/// Los mensajes viven en el árbol JSON, no en una tabla.
///
/// Es el módulo que corresponde: un chat no necesita esquema, y la colección
/// nace con el primer mensaje. Puesto en una tabla, además, aparecería entre
/// las del proyecto como si fuera un dato de negocio.
class ChatSourceRoble with UiLoggy implements IChatSource {
  ChatSourceRoble(this._database);

  static const _collection = 'mensajes';

  final RobleApiDataBase _database;

  @override
  Future<List<Message>> history() async {
    final tree = await _leerColeccion();
    if (tree == null) return const [];

    final messages = tree.entries
        .map((e) => Message.fromEntry(e.key.toString(), e.value))
        .toList();

    // Por clave, que lleva la marca de tiempo del servidor: ordenar por la
    // fecha que puso cada cliente dejaría el orden a merced de sus relojes.
    messages.sort((a, b) => a.id.compareTo(b.id));
    return messages;
  }

  /// `null` cuando todavía no hay colección.
  Future<Map<dynamic, dynamic>?> _leerColeccion() async {
    try {
      final tree = await _database.json.read(_collection);
      return tree is Map ? tree : null;
    } on RobleApiHttpException catch (e) {
      // Un chat sin estrenar no es un error: la colección aparece cuando entra
      // el primer mensaje, y hasta entonces el servidor responde 404.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> send(Message message) async {
    loggy.debug('Enviando mensaje');
    await _database.json.push(_collection, message.toJson());
  }

  @override
  Stream<Message> incoming() {
    // Solo altas: editar o borrar mensajes no es parte de esto, y pedir las
    // tres operaciones traería cambios que la interfaz no sabría colocar.
    return _database.json
        .watch(_collection, events: [RobleChangeType.insert])
        .expand(_mensajesDe);
  }

  /// Un push publica `{clave: contenido}`, así que un mismo evento puede traer
  /// más de un mensaje si alguien escribió varios de una vez.
  Iterable<Message> _mensajesDe(RobleChange change) {
    final record = change.record;
    if (record == null) return const [];
    return record.entries.map((e) => Message.fromEntry(e.key, e.value));
  }

  @override
  Future<String> currentSender() async {
    final profile = await _database.currentUser();
    return profile['email'] as String? ?? 'desconocido';
  }
}
