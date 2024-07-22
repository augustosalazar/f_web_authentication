import 'package:f_web_authentication/domain/models/authentication_user.dart';
import 'package:f_web_authentication/domain/repositories/i_repository.dart';
import '../datasources/remote/authentication/i_authentication_source.dart';
import '../datasources/remote/users/i_remote_user_source.dart';
import '../../domain/models/user.dart';

class Repository implements IRepository {
  late IAuthenticationSource authenticationSource;
  late IRemoteUserSource userSource;

  Repository(this.authenticationSource, this.userSource);

  @override
  Future<bool> login(String email, String password) async =>
      await authenticationSource.login(email, password);

  @override
  Future<bool> signUp(AuthenticationUser user) async =>
      await authenticationSource.signUp(user);

  @override
  Future<bool> logOut() async => await authenticationSource.logOut();

  @override
  Future<List<User>> getUsers() async => await userSource.getUsers();

  @override
  Future<bool> addUser(User user) async => await userSource.addUser(user);

  @override
  Future<bool> updateUser(User user) async => await userSource.updateUser(user);

  @override
  Future<bool> deleteUser(int id) async =>
      await userSource.deleteUser(id.toString());

  @override
  Future<bool> deleteUsers() async => await userSource.deleteUsers();
}
