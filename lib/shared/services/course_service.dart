import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class CourseService {
  final ApiClient apiClient;

  CourseService(this.apiClient);

  Future<List<CourseModel>> fetchCourses() async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses');
      final data = response.data['data'] as List;
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> createCourse(CourseModel course) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/courses',
        data: course.toJson(),
      );
      return CourseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> updateCourse(CourseModel course) async {
    try {
      final response = await apiClient.dio.put(
        '/api/v1/courses/${course.id}',
        data: course.toJson(),
      );
      return CourseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> enrollStudent(String courseId) async {
    try {
      await apiClient.dio.post('/api/v1/courses/$courseId/enroll');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> approveStudent(String courseId, String studentEmail) async {
    try {
      await apiClient.dio.post(
        '/api/v1/courses/$courseId/approve',
        data: {'studentEmail': studentEmail},
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
    return ApiException(message: e.message ?? e.type.toString());
  }
}
