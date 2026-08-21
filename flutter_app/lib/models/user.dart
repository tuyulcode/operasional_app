class User {
  final int id;
  final String username;
  final String role;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      photoUrl: json['photo_url'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPetugas => role == 'petugas';
}
