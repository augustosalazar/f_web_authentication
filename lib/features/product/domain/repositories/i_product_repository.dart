import '../models/user.dart';

abstract class IProductRepository {
  Future<List<User>> getUsers();

  Future<bool> addUser(User user);

  Future<bool> updateUser(User user);

  Future<bool> deleteUser(User user);

  Future<bool> deleteUsers();
}
