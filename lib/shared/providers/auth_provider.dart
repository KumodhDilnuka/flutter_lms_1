import '../../features/auth/services/auth_service.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';
import 'feature_provider.dart';

class AuthProvider extends FeatureProvider {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  
  User? currentUser;
  String? currentRole;
  bool get isAuthenticated => currentRole != null;

  AuthProvider(this._authService, this._tokenStorage) {
    _initSession();
  }

  Future<void> _initSession() async {
    currentRole = await _tokenStorage.readRole();
    if (currentRole != null) {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    final session = await run(() => _authService.login(email: email, password: password));
    if (session != null) {
      await _tokenStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: session.user.role,
      );
      currentUser = session.user;
      currentRole = session.user.role;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final user = await run(() => _authService.registerStudent(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      dateOfBirth: '2000-01-01', // Default for now
      educationLevel: 'Undergraduate',
      learningGoals: ['Learn Flutter'],
    ));
    return user != null;
  }

  Future<bool> registerInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final user = await run(() => _authService.registerInstructor(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      headline: 'Flutter Instructor',
      qualification: 'Software Engineer',
      experienceYears: 1,
      expertise: ['Flutter'],
      biography: 'Instructor biography',
    ));
    return user != null;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final session = await run(() => _authService.verifyEmail(email: email, otp: otp));
    if (session != null) {
      await _tokenStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: session.user.role,
      );
      currentUser = session.user;
      currentRole = session.user.role;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    currentUser = null;
    currentRole = null;
    notifyListeners();
  }
}
