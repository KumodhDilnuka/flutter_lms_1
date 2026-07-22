import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class CourseService {
  final ApiClient apiClient;

  CourseService(this.apiClient);

  Future<List<CourseModel>> fetchCourses({String? categoryId, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 50,
      };
      if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await apiClient.dio.get('/api/v1/courses', queryParameters: queryParams);
      final data = response.data['data']?['courses'] as List?;
      if (data == null) return [];
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> getCourseDetails(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId');
      return CourseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Student Enrollment Endpoints

  Future<void> enrollStudent(String courseId) async {
    try {
      await apiClient.dio.post('/api/v1/courses/$courseId/enroll');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyEnrollments() async {
    try {
      final response = await apiClient.dio.get('/api/v1/users/me/enrollments');
      final data = response.data['data'] as List?;
      if (data == null) return [];
      
      // Each enrollment returns { id, course: CourseModel, status: 'PENDING' | 'APPROVED' | 'REJECTED' }
      return List<Map<String, dynamic>>.from(data);
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
    return ApiException(message: e.message ?? e.type.toString());
  }
}
