import 'package:f_web_authentication/data/datasources/remote/authentication_datasource.dart';
import 'package:f_web_authentication/domain/models/authentication_user.dart';
import 'package:f_web_authentication/domain/repositories/i_repository.dart';

import '../datasources/remote/users/remote_user_source.dart';
import '../../domain/models/user.dart';

class Repository implements IRepository {
  late AuthenticationDatatasource authenticationDataSource;
  late RemoteUserSource userDatatasource;

  Repository(this.authenticationDataSource, this.userDatatasource);

  @override
  Future<bool> login(String email, String password) async =>
      await authenticationDataSource.login(email, password);

  @override
  Future<bool> signUp(AuthenticationUser user) async =>
      await authenticationDataSource.signUp(user);

  @override
  Future<bool> logOut() async => await authenticationDataSource.logOut();

  @override
  Future<List<User>> getUsers() async => await userDatatasource.getUsers();

  @override
  Future<bool> addUser(User user) async => await userDatatasource.addUser(user);

  @override
  Future<bool> updateUser(User user) async =>
      await userDatatasource.updateUser(user);

  @override
  Future<bool> deleteUser(int id) async =>
      await userDatatasource.deleteUser(id);

  @override
  Future<bool> deleteUsers() async => await userDatatasource.deleteUsers();
}
