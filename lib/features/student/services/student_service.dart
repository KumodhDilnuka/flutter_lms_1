import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/student_profile_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';

class StudentService {
  final ApiClient apiClient;

  StudentService(this.apiClient);

  Future<StudentProfileModel> getMyProfile() async {
    try {
      final response = await apiClient.dio.get('/api/v1/students/me');
      final data = response.data['data'];
      return StudentProfileModel.fromJson(data['student'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return StudentProfileModel(); // return empty if not created yet
      }
      throw _handleDioError(e);
    }
  }

  Future<StudentProfileModel> updateMyProfile(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/students/me', data: payload);
      final data = response.data['data'];
      return StudentProfileModel.fromJson(data['student'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<StudentProfileModel> createMyProfile(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/students/me', data: payload);
      final data = response.data['data'];
      return StudentProfileModel.fromJson(data['student'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMyProfile() async {
    try {
      await apiClient.dio.delete('/api/v1/students/me');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DashboardStatsModel> fetchDashboardStats() async {
    try {
      final response = await apiClient.dio.get('/api/v1/dashboards/student');
      final data = response.data['data']?['stats'] ?? response.data['data'] ?? response.data;
      return DashboardStatsModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      String msg = data['message'] ?? 'An error occurred';
      return ApiException(
        statusCode: e.response?.statusCode,
        message: msg,
        errorCode: data['errorCode'],
      );
    }
    return ApiException(message: e.message ?? e.error?.toString() ?? e.type.toString());
  }
}
