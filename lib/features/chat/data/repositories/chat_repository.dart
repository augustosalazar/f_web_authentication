import '../../domain/models/message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/remote/i_chat_source.dart';

class ChatRepository implements IChatRepository {
  ChatRepository(this._source);

  final IChatSource _source;

  @override
  Future<List<Message>> history() => _source.history();

  @override
  Future<void> send(String content) async {
    final sender = await _source.currentSender();
    await _source.send(
      Message(
        id: '',
        content: content,
        sender: sender,
        sentAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<Message> changes() => _source.incoming();

  @override
  Future<String> currentSender() => _source.currentSender();
}
