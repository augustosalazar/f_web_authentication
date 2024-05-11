import '../models/authentication_user.dart';
import '../models/user.dart';

abstract class IRepository {
  Future<bool> login(String email, String password);

  Future<bool> signUp(AuthenticationUser user);

  Future<bool> logOut();

  Future<List<User>> getUsers();

  Future<bool> addUser(User user);

  Future<bool> updateUser(User user);

  Future<bool> deleteUser(int id);

  Future<bool> deleteUsers();
}
