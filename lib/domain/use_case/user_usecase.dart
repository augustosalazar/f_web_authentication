import 'package:loggy/loggy.dart';
import '../models/user.dart';
import '../repositories/i_repository.dart';

class UserUseCase {
  late IRepository repository;

  UserUseCase(this.repository);

  Future<List<User>> getUsers() async {
    logInfo("Getting users  from UseCase");
    return await repository.getUsers();
  }

  Future<void> addUser(User user) async => await repository.addUser(user);

  Future<void> updateUser(User user) async => await repository.updateUser(user);

  Future<void> deleteUser(int id) async => await repository.deleteUser(id);

  Future<void> deleteUsers() async => await repository.deleteUsers();
}
