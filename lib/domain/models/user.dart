class User {
  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String? id;
  String firstName;
  String lastName;
  String email;

  String get name => '$firstName $lastName';

  String get emailAddress => email;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["entry_id"],
        firstName: json["firstName"] ?? "somefirstName",
        lastName: json["lastName"] ?? "someLastName",
        email: json["email"] ?? "someemail",
      );

  Map<String, dynamic> toJson() => {
        "entry_id": id ?? "0",
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
      };

  Map<String, dynamic> toJsonNoId() => {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
      };

  @override
  String toString() {
    return 'User{entry_id: $id, firstName: $firstName, lastName: $lastName, email: $email}';
  }
}
