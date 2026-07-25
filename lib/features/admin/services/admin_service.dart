import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/models/category_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';

class AdminService {
  final ApiClient apiClient;

  AdminService(this.apiClient);

  Future<List<User>> fetchUsers({String? role, String? status, String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': 1,
        'limit': 50,
      };
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      
      final endpoint = search != null && search.isNotEmpty 
          ? '/api/v1/users/search?q=$search' 
          : '/api/v1/users';

      final response = await apiClient.dio.get(endpoint, queryParameters: queryParams);
      print('=== ADMIN USERS RESPONSE ===');
      print(response.data);
      final dynamic resData = response.data['data'];
      final data = (resData is Map) ? resData['users'] as List? : resData as List?;
      if (data == null) {
          throw Exception('RAW_JSON: ${response.data}');
      }
      
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<User> getUser(String userId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/users/$userId');
      final data = response.data['data'];
      return User.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      await apiClient.dio.patch(
        '/api/v1/users/$userId/status',
        data: {'status': 'SUSPENDED'},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> reactivateUser(String userId) async {
    try {
      await apiClient.dio.patch(
        '/api/v1/users/$userId/status',
        data: {'status': 'ACTIVE'},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<User>> fetchInstructors() async {
    try {
      final response = await apiClient.dio.get('/api/v1/users', queryParameters: {'role': 'INSTRUCTOR', 'limit': 50});
      final dynamic resData = response.data['data'];
      final data = (resData is Map) ? resData['users'] as List? : resData as List?;
      if (data == null) return [];
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Admin LMS Management ---

  Future<List<CourseModel>> fetchAllCourses() async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses', queryParameters: {'page': 1, 'limit': 50});
      print('=== ADMIN COURSES RESPONSE ===');
      print(response.data);
      final dynamic resData = response.data['data'];
      final data = (resData is Map) ? resData['courses'] as List? : resData as List?;
      if (data == null) {
          throw Exception('RAW_JSON: ${response.data}');
      }
      return (data as List).map((json) => CourseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> archiveCourseAsAdmin(String courseId) async {
    try {
      await apiClient.dio.patch('/api/v1/courses/$courseId/admin/archive');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/categories',
        queryParameters: {
          'page': 1,
          'limit': 50,
          'activeOnly': false, // Admin needs to see all categories
        },
      );
      
      final data = response.data['data']?['categories'] as List?;
      if (data == null) return [];
      
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CategoryModel> getCategory(String categoryId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/categories/$categoryId');
      final data = response.data['data'];
      return CategoryModel.fromJson(data['category'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CategoryModel> createCategory(String name, String description) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/categories',
        data: {
          'name': name,
          'description': description,
        },
      );
      final data = response.data['data'];
      final categoryData = data['category'] ?? data;
      return CategoryModel.fromJson(categoryData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CategoryModel> updateCategory(String categoryId, String name, String description) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/categories/$categoryId',
        data: {
          'name': name,
          'description': description,
        },
      );
      final data = response.data['data'];
      final categoryData = data['category'] ?? data;
      return CategoryModel.fromJson(categoryData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      await apiClient.dio.patch(
        '/api/v1/categories/$categoryId/status',
        data: {
          'isActive': isActive,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAllEnrollments() async {
    try {
      final response = await apiClient.dio.get('/api/v1/admin/enrollments');
      final data = response.data['data'] as List?;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DashboardStatsModel> fetchDashboardStats() async {
    try {
      // Mock stats because the admin dashboard route does not exist
      return DashboardStatsModel(rawStats: {
        'totalCourses': 0,
        'totalStudents': 0,
        'totalInstructors': 0,
        'pendingApprovals': 0,
        'totalRevenue': 0,
      });
    } catch (e) {
      throw ApiException(message: 'Failed to generate stats');
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
