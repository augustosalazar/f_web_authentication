import 'package:roble/roble.dart';

class AuthenticationUser {
  String? id;
  final String email;
  final String name;

  /// Rol asignado en la consola de Roble: `admin`, `user`, el que sea.
  ///
  /// Opcional a propósito. Es `null` cuando a esa persona no se le asignó
  /// ninguno —que no es un error—, y también cuando el backend es anterior a
  /// v1.7.8, que es cuando el perfil empezó a traerlo.
  final String? role;

  AuthenticationUser({
    this.id,
    required this.email,
    required this.name,
    this.role,
  });

  /// Desde el perfil que reparte el paquete con el estado de la sesión.
  ///
  /// Ya viene convertido de allí, así que esto solo se queda con lo que la app
  /// usa. La conversión vive aquí y no en el controlador porque es lo mismo que
  /// hace [AuthenticationUser.fromJson]: traer un perfil de fuera al modelo de
  /// dentro.
  factory AuthenticationUser.fromRoble(RobleUser user) => AuthenticationUser(
        id: user.userId,
        email: user.email,
        name: user.name,
        role: user.role,
      );

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['userId'] ?? json['id'] ?? json['_id'] ?? json['sub'],
      email: json['email'],
      name: json['name'],
      // `as String?` y no un cast directo: si algún día llega un objeto en vez
      // de un nombre, esto revienta aquí y no tres pantallas más allá.
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
