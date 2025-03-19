import '../../../auth/data/datasources/remote/i_authentication_source.dart';
import '../../../auth/domain/models/authentication_user.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/i_remote_user_source.dart';
import '../../domain/models/user.dart';

class ProductRepository implements IProductRepository {
  late IRemoteUserSource userSource;

  ProductRepository(this.userSource);

  @override
  Future<List<User>> getUsers() async => await userSource.getUsers();

  @override
  Future<bool> addUser(User user) async => await userSource.addUser(user);

  @override
  Future<bool> updateUser(User user) async => await userSource.updateUser(user);

  @override
  Future<bool> deleteUser(User user) async => await userSource.deleteUser(user);

  @override
  Future<bool> deleteUsers() async => await userSource.deleteUsers();
}
