import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/auth_session_model.dart';
import '../../../shared/models/user_model.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  Future<User> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String dateOfBirth,
    required String educationLevel,
    required List<String> learningGoals,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/auth/register/student',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'confirmPassword': password,
          'dateOfBirth': dateOfBirth,
          'educationLevel': educationLevel,
          'learningGoals': learningGoals,
        },
      );
      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> registerInstructor({
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
    try {
      final response = await apiClient.dio.post(
        '/api/v1/auth/register/instructor',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'confirmPassword': password,
          'headline': headline,
          'qualification': qualification,
          'experienceYears': experienceYears,
          'expertise': expertise,
          'biography': biography,
        },
      );
      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/auth/verify-email',
        data: {
          'email': email,
          'otp': otp,
        },
      );
      return AuthSession.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> resendVerificationOTP(String email) async {
    try {
      await apiClient.dio.post(
        '/api/v1/auth/resend-verification-otp',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logoutCurrentSession() async {
    try {
      await apiClient.dio.post('/api/v1/auth/logout');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logoutFromAllDevices() async {
    try {
      await apiClient.dio.post('/api/v1/auth/logout-all');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post(
        '/api/v1/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/auth/verify-password-reset-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );
      // Backend returns a short-lived reset token
      return response.data['data']['resetToken'] ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiClient.dio.post(
        '/api/v1/auth/reset-password',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return ApiException(
        statusCode: e.response?.statusCode,
        message: e.response?.data['message'],
        errorCode: e.response?.data['errorCode'],
      );
    }
    return ApiException(message: e.message ?? e.error?.toString() ?? e.type.toString());
  }
}
