class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String status;
  final bool emailVerified;
  final String? profileImageUrl;
  final String? bio;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    required this.emailVerified,
    this.profileImageUrl,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
    );
  }
}
