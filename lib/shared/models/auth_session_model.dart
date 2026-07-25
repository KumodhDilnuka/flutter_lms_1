import 'user_model.dart';

class AuthSession {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user']),
      accessToken: json['tokens']['accessToken'],
      refreshToken: json['tokens']['refreshToken'],
    );
  }
}
