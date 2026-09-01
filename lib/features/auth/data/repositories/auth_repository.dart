import 'package:roble/roble.dart';

import '../../domain/models/authentication_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/i_authentication_source.dart';

class AuthRepository implements IAuthRepository {
  late IAuthenticationSource authenticationSource;

  AuthRepository(this.authenticationSource);

  @override
  Stream<RobleAuthState> sessionChanges() =>
      authenticationSource.sessionChanges();

  @override
  Future<void> login(String email, String password) async =>
      await authenticationSource.login(email, password);

  @override
  Future<void> signUp(
          String email, String password, String name, bool direct) async =>
      await authenticationSource.signUp(email, password, name, direct);

  @override
  Future<void> logOut() async => await authenticationSource.logOut();

  @override
  Future<bool> validate(String email, String validationCode) async =>
      await authenticationSource.validate(email, validationCode);

  @override
  Future<void> forgotPassword(String email) async =>
      await authenticationSource.forgotPassword(email);

  @override
  Future<AuthenticationUser> getLoggedUser() async =>
      await authenticationSource.getLoggedUser();

  @override
  Future<bool> restoreSession() async =>
      await authenticationSource.restoreSession();

  @override
  Future<bool> isGoogleEnabled() async =>
      await authenticationSource.isGoogleEnabled();

  @override
  Future<AuthenticationUser> signInWithGoogle() async =>
      await authenticationSource.signInWithGoogle();
}
