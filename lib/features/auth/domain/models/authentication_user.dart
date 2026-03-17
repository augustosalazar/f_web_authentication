class AuthenticationUser {
  String? id;
  final String username;
  final String name;
  final String password;

  AuthenticationUser({
    this.id,
    required this.username,
    required this.name,
    required this.password,
  });

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': username,
      'name': name,
    };
  }
}
