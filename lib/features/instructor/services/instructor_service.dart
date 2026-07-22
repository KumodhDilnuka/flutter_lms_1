import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class InstructorService {
  final ApiClient apiClient;

  InstructorService(this.apiClient);

  Future<List<CourseModel>> fetchMyCourses() async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/courses/instructor/me',
        queryParameters: {'page': 1, 'limit': 50},
      );
      final data = response.data['data']?['courses'] as List?;
      if (data == null) return [];
      return data.map((json) => CourseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> getCourseDetails(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/instructor/me/$courseId');
      final data = response.data['data'];
      final courseData = data['course'] ?? data;
      return CourseModel.fromJson(courseData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> createCourse(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/courses', data: payload);
      final data = response.data['data'];
      final courseData = data['course'] ?? data;
      return CourseModel.fromJson(courseData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> updateCourse(String courseId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.put('/api/v1/courses/instructor/me/$courseId', data: payload);
      final data = response.data['data'];
      final courseData = data['course'] ?? data;
      return CourseModel.fromJson(courseData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> publishCourse(String courseId) async {
    try {
      await apiClient.dio.patch('/api/v1/courses/$courseId/publish');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CourseModel> uploadThumbnail(String courseId, File thumbnail) async {
    try {
      final formData = FormData.fromMap({
        'thumbnail': await MultipartFile.fromFile(thumbnail.path, filename: thumbnail.path.split('/').last),
      });
      final response = await apiClient.dio.post('/api/v1/courses/$courseId/thumbnail', data: formData);
      final data = response.data['data'];
      final courseData = data['course'] ?? data;
      return CourseModel.fromJson(courseData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Section Management
  Future<List<SectionModel>> fetchSections(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/sections');
      final data = response.data['data']?['sections'] as List?;
      if (data == null) return [];
      return data.map((e) => SectionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<SectionModel> createSection(String courseId, String title, String description, bool isPublished) async {
    try {
      final response = await apiClient.dio.post('/api/v1/courses/$courseId/sections', data: {
        'title': title,
        'description': description,
      });
      final data = response.data['data'];
      return SectionModel.fromJson(data['section'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<SectionModel> updateSection(String sectionId, String title, String description) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/sections/$sectionId', data: {
        'title': title,
        'description': description,
      });
      final data = response.data['data'];
      return SectionModel.fromJson(data['section'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<SectionModel> publishSection(String sectionId) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/sections/$sectionId', data: {
        'isPublished': true,
      });
      final data = response.data['data'];
      return SectionModel.fromJson(data['section'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteSection(String sectionId) async {
    try {
      await apiClient.dio.delete('/api/v1/sections/$sectionId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Lesson Management
  Future<List<LessonModel>> fetchLessons(String sectionId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/sections/$sectionId/lessons');
      final data = response.data['data']?['lessons'] as List?;
      if (data == null) return [];
      return data.map((e) => LessonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonModel> createLesson(String sectionId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/sections/$sectionId/lessons', data: payload);
      final data = response.data['data'];
      return LessonModel.fromJson(data['lesson'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonModel> uploadLessonVideo(String lessonId, File video) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path, filename: video.path.split('/').last),
      });
      final response = await apiClient.dio.post('/api/v1/lessons/$lessonId/video', data: formData);
      return LessonModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonModel> uploadLessonDocument(String lessonId, File document) async {
    try {
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(document.path, filename: document.path.split('/').last),
      });
      final response = await apiClient.dio.post('/api/v1/lessons/$lessonId/document', data: formData);
      return LessonModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonModel> publishLesson(String lessonId) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/lessons/$lessonId', data: {'isPublished': true});
      return LessonModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      String msg = data['message'] ?? 'Unknown Error';
      
      debugPrint('DIO ERROR DATA: $data');

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
