import 'package:f_web_authentication/data/datasources/remote/authentication_datasource.dart';
import 'package:f_web_authentication/domain/repositories/i_repository.dart';

import '../../data/datasources/remote/user_datasource.dart';
import '../../domain/models/user.dart';

class Repository implements IRepository {
  late AuthenticationDatatasource _authenticationDataSource;
  late UserDataSource _userDatatasource;
  String token = "";

  // the base url of the API should end without the /
  final String _baseUrl =
      "http://ip172-18-0-103-cjvmcv8gftqg00dhebr0-8000.direct.labs.play-with-docker.com";

  Repository(this._authenticationDataSource, this._userDatatasource);

  @override
  Future<bool> login(String email, String password) async {
    token = await _authenticationDataSource.login(_baseUrl, email, password);
    return true;
  }

  @override
  Future<bool> signUp(String email, String password) async =>
      await _authenticationDataSource.signUp(_baseUrl, email, password);

  @override
  Future<bool> logOut() async => await _authenticationDataSource.logOut();

  @override
  Future<List<User>> getUsers() async => await _userDatatasource.getUsers();

  @override
  Future<bool> addUser(User user) async =>
      await _userDatatasource.addUser(user);

  @override
  Future<bool> updateUser(User user) async =>
      await _userDatatasource.updateUser(user);

  @override
  Future<bool> deleteUser(int id) async =>
      await _userDatatasource.deleteUser(id);

  @override
  Future<bool> deleteUsers() async => await _userDatatasource.deleteUsers();
}
