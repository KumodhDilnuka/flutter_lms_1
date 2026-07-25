import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient apiClient;

  UserService(this.apiClient);

  Future<User> getMyProfile() async {
    try {
      final response = await apiClient.dio.get('/api/v1/users/me/profile');
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> getMyUserAccount() async {
    try {
      final response = await apiClient.dio.get('/api/v1/users/me');
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> updateMyUserAccount(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/users/me', data: payload);
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> uploadMyProfileImage(File image) async {
    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
      });
      final response = await apiClient.dio.post('/api/v1/users/me/profile-image', data: formData);
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> deleteMyProfileImage() async {
    try {
      final response = await apiClient.dio.delete('/api/v1/users/me/profile-image');
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> changeMyPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiClient.dio.patch('/api/v1/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deactivateMyAccount() async {
    try {
      await apiClient.dio.patch('/api/v1/users/me/deactivate');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      String msg = data['message'] ?? 'An error occurred';

      if (data['details'] != null && data['details'] is List) {
        final details = data['details'] as List;
        if (details.isNotEmpty) {
          final firstError = details.first;
          if (firstError is Map && firstError['message'] != null) {
            msg = '${firstError['message']}';
          }
        }
      }

      if (msg == 'Request validation failed') {
        msg = 'Validation Failed: $data';
      }

      return ApiException(
        statusCode: e.response?.statusCode,
        message: msg,
        errorCode: data['errorCode'],
      );
    }
    return ApiException(message: e.message ?? e.error?.toString() ?? e.type.toString());
  }
}
