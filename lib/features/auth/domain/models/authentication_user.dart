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
