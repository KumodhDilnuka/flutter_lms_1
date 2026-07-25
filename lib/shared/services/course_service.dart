import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/review_model.dart';

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
      final data = response.data['data'];
      return CourseModel.fromJson(data['course'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Curriculum Fetching
  Future<List<Map<String, dynamic>>> fetchSections(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/sections');
      final data = response.data['data']?['sections'] as List?;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchLessons(String sectionId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/sections/$sectionId/lessons');
      final data = response.data['data']?['lessons'] as List?;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
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
      final response = await apiClient.dio.get(
        '/api/v1/enrollments/me',
        queryParameters: {'page': 1, 'limit': 50},
      );
      dynamic data = response.data['data'];
      
      if (data is Map && data.containsKey('enrollments')) {
        data = data['enrollments'];
      }
      
      if (data is! List) return [];
      
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getEnrollment(String enrollmentId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/enrollments/$enrollmentId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> cancelEnrollment(String enrollmentId) async {
    try {
      await apiClient.dio.patch('/api/v1/enrollments/$enrollmentId/cancel');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Progress Tracking Endpoints ---

  Future<void> startLesson(String lessonId) async {
    try {
      await apiClient.dio.patch('/api/v1/lessons/$lessonId/start');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> completeLesson(String lessonId) async {
    try {
      await apiClient.dio.patch('/api/v1/lessons/$lessonId/complete');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/progress');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getEnrollmentProgress(String enrollmentId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/enrollments/$enrollmentId/progress');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Quiz Consumption Endpoints ---

  Future<List<QuizModel>> fetchCourseQuizzes(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/quizzes');
      final data = response.data['data']?['quizzes'] as List?;
      if (data == null) return [];
      return data.map((json) => QuizModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuizModel> getStudentQuiz(String quizId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/quizzes/$quizId');
      final data = response.data['data'];
      final quizJson = Map<String, dynamic>.from(data['quiz'] ?? data);
      if (data['questions'] != null) {
        quizJson['questions'] = data['questions'];
      }
      return QuizModel.fromJson(quizJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuizAttemptModel> startQuizAttempt(String quizId) async {
    try {
      final response = await apiClient.dio.post('/api/v1/quizzes/$quizId/start');
      final data = response.data['data'];
      return QuizAttemptModel.fromJson(data['attempt'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuizAttemptModel> submitQuizAttempt(String attemptId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/quiz-attempts/$attemptId/submit', data: payload);
      final data = response.data['data'];
      return QuizAttemptModel.fromJson(data['attempt'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<QuizAttemptModel>> fetchMyAttempts(String quizId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/quizzes/$quizId/attempts/me');
      final data = response.data['data']?['attempts'] as List?;
      if (data == null) return [];
      return data.map((json) => QuizAttemptModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Assignment Consumption Endpoints ---

  Future<List<AssignmentModel>> fetchStudentAssignments(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/assignments');
      final data = response.data['data']?['assignments'] as List?;
      if (data == null) return [];
      return data.map((json) => AssignmentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentModel> getStudentAssignment(String assignmentId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/assignments/$assignmentId');
      final data = response.data['data'];
      return AssignmentModel.fromJson(data['assignment'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentSubmissionModel> submitAssignment(String assignmentId, File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await apiClient.dio.post('/api/v1/assignments/$assignmentId/submissions', data: formData);
      final data = response.data['data'];
      return AssignmentSubmissionModel.fromJson(data['submission'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentSubmissionModel> replaceSubmissionFile(String submissionId, File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await apiClient.dio.post('/api/v1/submissions/$submissionId/replace-file', data: formData);
      final data = response.data['data'];
      return AssignmentSubmissionModel.fromJson(data['submission'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentSubmissionModel> getMySubmission(String assignmentId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/assignments/$assignmentId/submissions/my-submission');
      final data = response.data['data'];
      return AssignmentSubmissionModel.fromJson(data['submission'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Reviews ---

  Future<List<ReviewModel>> fetchCourseReviews(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/reviews');
      final data = response.data['data']?['reviews'] as List?;
      if (data == null) return [];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReviewModel> createReview(String courseId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/courses/$courseId/reviews', data: payload);
      final data = response.data['data'];
      return ReviewModel.fromJson(data['review'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReviewModel> updateReview(String reviewId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/reviews/$reviewId', data: payload);
      final data = response.data['data'];
      return ReviewModel.fromJson(data['review'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await apiClient.dio.delete('/api/v1/reviews/$reviewId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      String msg = data['message'] ?? 'An error occurred';
      
      // Dump the entire data map for debugging if it's a validation error
      if (e.response?.statusCode == 400 || msg.toLowerCase().contains('validation')) {
        msg += '\n\nDEBUG_DUMP: ' + data.toString();
      } else if (data['errors'] != null) {
        msg += ' - ${data['errors']}';
      }
      
      return ApiException(
        statusCode: e.response?.statusCode,
        message: msg,
        errorCode: data['errorCode'],
      );
    }
    return ApiException(message: e.message ?? e.type.toString());
  }
}
