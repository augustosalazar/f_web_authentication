import '../../../../domain/models/user.dart';

abstract class IRemoteUserSource {
  Future<List<User>> getUsers();

  Future<bool> addUser(User user);

  Future<bool> updateUser(User user);

  Future<bool> deleteUser(String id);

  Future<bool> deleteUsers();
}
