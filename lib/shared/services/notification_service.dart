import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/notification_model.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService(this.apiClient);

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await apiClient.dio.get('/api/v1/notifications');
      final data = response.data['data']?['notifications'] as List?;
      if (data == null) return [];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await apiClient.dio.get('/api/v1/notifications/unread-count');
      return response.data['data']?['count'] ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/notifications/$id/read');
      final data = response.data['data'];
      return NotificationModel.fromJson(data['notification'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await apiClient.dio.patch('/api/v1/notifications/read-all');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await apiClient.dio.delete('/api/v1/notifications/$id');
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
    return ApiException(message: 'An unexpected error occurred: ${e.message}');
  }
}
