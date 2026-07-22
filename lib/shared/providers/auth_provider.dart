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
    required String dateOfBirth,
    required String educationLevel,
    required List<String> learningGoals,
  }) async {
    final user = await run(() => _authService.registerStudent(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      dateOfBirth: dateOfBirth,
      educationLevel: educationLevel,
      learningGoals: learningGoals,
    ));
    return user != null;
  }

  Future<bool> registerInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String headline,
    required String qualification,
    required int experienceYears,
    required List<String> expertise,
    required String biography,
  }) async {
    final user = await run(() => _authService.registerInstructor(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      headline: headline,
      qualification: qualification,
      experienceYears: experienceYears,
      expertise: expertise,
      biography: biography,
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
    try {
      await run(() => _authService.logoutCurrentSession());
    } catch (_) {
      // Ignore API errors on logout, still clear local session
    }
    await _tokenStorage.clear();
    currentUser = null;
    currentRole = null;
    notifyListeners();
  }

  Future<bool> resendOtp(String email) async {
    await run(() => _authService.resendVerificationOTP(email));
    return errorMessage == null;
  }

  Future<void> logoutAllDevices() async {
    try {
      await run(() => _authService.logoutFromAllDevices());
    } catch (_) {}
    await _tokenStorage.clear();
    currentUser = null;
    currentRole = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    await run(() => _authService.forgotPassword(email));
    return errorMessage == null;
  }

  Future<String?> verifyPasswordResetOTP(String email, String otp) async {
    return await run(() => _authService.verifyPasswordResetOTP(email: email, otp: otp));
  }

  Future<bool> resetPassword(String resetToken, String newPassword, String confirmPassword) async {
    await run(() => _authService.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    ));
    return errorMessage == null;
  }
}
