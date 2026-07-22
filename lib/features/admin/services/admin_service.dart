import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/models/category_model.dart';

class AdminService {
  final ApiClient apiClient;

  AdminService(this.apiClient);

  Future<List<User>> fetchInstructors() async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/users',
        queryParameters: {
          'page': 1,
          'limit': 50,
          'role': 'INSTRUCTOR',
          'status': 'ACTIVE',
        },
      );
      
      final data = response.data['data']?['users'] as List?;
      if (data == null) return [];
      
      return data.map((json) => User.fromJson(json)).toList();
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
