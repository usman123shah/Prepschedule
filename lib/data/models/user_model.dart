class User {
  final String? id;
  final String username;
  final String password; // In real app, never store plain text password locally
  final String email;

  User({this.id, required this.username, required this.password, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
    );
  }
}
