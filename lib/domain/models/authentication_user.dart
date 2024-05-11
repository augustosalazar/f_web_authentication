class AuthenticationUser {
  int? id;
  final String username;
  final String firstName;
  final String lastName;
  final String password;

  AuthenticationUser({
    this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
    };
  }
}
