class AuthenticationUser {
  String? id;
  final String email;
  final String name;

  AuthenticationUser({
    this.id,
    required this.email,
    required this.name,
  });

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['sub'] ?? json['id'] ?? json['_id'] ?? json['userId'],
      email: json['email'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
    };
  }
}
