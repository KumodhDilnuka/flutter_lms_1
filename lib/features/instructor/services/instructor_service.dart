import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/instructor_profile_model.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/review_model.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';

class InstructorService {
  final ApiClient apiClient;

  InstructorService(this.apiClient);

  // --- Profile Management ---
  Future<InstructorProfileModel> getMyProfile() async {
    try {
      final response = await apiClient.dio.get('/api/v1/instructors/me');
      final data = response.data['data'];
      return InstructorProfileModel.fromJson(data['instructor'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return InstructorProfileModel(); // empty profile
      }
      throw _handleDioError(e);
    }
  }

  Future<InstructorProfileModel> updateMyProfile(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/instructors/me', data: payload);
      final data = response.data['data'];
      return InstructorProfileModel.fromJson(data['instructor'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<InstructorProfileModel> createMyProfile(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/instructors/me', data: payload);
      final data = response.data['data'];
      return InstructorProfileModel.fromJson(data['instructor'] ?? data['profile'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMyProfile() async {
    try {
      await apiClient.dio.delete('/api/v1/instructors/me');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Course Management ---
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
      final response = await apiClient.dio.patch('/api/v1/courses/$courseId', data: payload);
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

  Future<void> archiveCourse(String courseId) async {
    try {
      await apiClient.dio.patch('/api/v1/courses/$courseId/archive');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> removeThumbnail(String courseId) async {
    try {
      await apiClient.dio.delete('/api/v1/courses/$courseId/thumbnail');
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

  Future<void> reorderSection(String sectionId, int newPosition) async {
    try {
      await apiClient.dio.patch('/api/v1/sections/$sectionId/reorder', data: {
        'newPosition': newPosition,
      });
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

  Future<LessonModel> getLesson(String lessonId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/lessons/$lessonId');
      final data = response.data['data'];
      return LessonModel.fromJson(data['lesson'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonModel> updateLesson(String lessonId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/lessons/$lessonId', data: payload);
      final data = response.data['data'];
      return LessonModel.fromJson(data['lesson'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> reorderLesson(String lessonId, int newPosition) async {
    try {
      await apiClient.dio.patch('/api/v1/lessons/$lessonId/reorder', data: {
        'newPosition': newPosition,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteLessonVideo(String lessonId) async {
    try {
      await apiClient.dio.delete('/api/v1/lessons/$lessonId/video');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteLessonDocument(String lessonId) async {
    try {
      await apiClient.dio.delete('/api/v1/lessons/$lessonId/document');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await apiClient.dio.delete('/api/v1/lessons/$lessonId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCourseEnrollments(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/enrollments');
      final data = response.data['data']?['enrollments'] ?? response.data['data'] as List?;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> approveEnrollment(String enrollmentId) async {
    try {
      await apiClient.dio.patch('/api/v1/enrollments/$enrollmentId/approve');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> rejectEnrollment(String enrollmentId) async {
    try {
      await apiClient.dio.patch('/api/v1/enrollments/$enrollmentId/reject');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Quiz Management ---

  Future<QuizModel> createQuiz(String courseId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/courses/$courseId/quizzes', data: payload);
      final data = response.data['data'];
      return QuizModel.fromJson(data['quiz'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<QuizModel>> fetchInstructorQuizzes(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/quizzes/instructor');
      final data = response.data['data']?['quizzes'] as List?;
      if (data == null) return [];
      return data.map((json) => QuizModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuizModel> getInstructorQuiz(String quizId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/quizzes/$quizId/instructor');
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

  Future<QuizModel> updateQuiz(String quizId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/quizzes/$quizId', data: payload);
      final data = response.data['data'];
      return QuizModel.fromJson(data['quiz'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await apiClient.dio.delete('/api/v1/quizzes/$quizId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> publishQuiz(String quizId) async {
    try {
      await apiClient.dio.patch('/api/v1/quizzes/$quizId/publish');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuestionModel> createQuestion(String quizId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/quizzes/$quizId/questions', data: payload);
      final data = response.data['data'];
      return QuestionModel.fromJson(data['question'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<QuestionModel> updateQuestion(String questionId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/questions/$questionId', data: payload);
      final data = response.data['data'];
      return QuestionModel.fromJson(data['question'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await apiClient.dio.delete('/api/v1/questions/$questionId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<QuizAttemptModel>> fetchInstructorAttempts(String quizId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/quizzes/$quizId/attempts');
      final data = response.data['data']?['attempts'] as List?;
      if (data == null) return [];
      return data.map((json) => QuizAttemptModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Assignment Management ---

  Future<AssignmentModel> createAssignment(String courseId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.post('/api/v1/courses/$courseId/assignments', data: payload);
      final data = response.data['data'];
      return AssignmentModel.fromJson(data['assignment'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<AssignmentModel>> fetchInstructorAssignments(String courseId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/courses/$courseId/assignments/instructor');
      final data = response.data['data']?['assignments'] as List?;
      if (data == null) return [];
      return data.map((json) => AssignmentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentModel> updateAssignment(String assignmentId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/assignments/$assignmentId', data: payload);
      final data = response.data['data'];
      return AssignmentModel.fromJson(data['assignment'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentModel> uploadAssignmentAttachment(String assignmentId, File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await apiClient.dio.post('/api/v1/assignments/$assignmentId/attachment', data: formData);
      final data = response.data['data'];
      return AssignmentModel.fromJson(data['assignment'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteAttachment(String assignmentId) async {
    try {
      await apiClient.dio.delete('/api/v1/assignments/$assignmentId/attachment');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> publishAssignment(String assignmentId) async {
    try {
      await apiClient.dio.patch('/api/v1/assignments/$assignmentId/publish');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await apiClient.dio.delete('/api/v1/assignments/$assignmentId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<AssignmentSubmissionModel>> fetchInstructorSubmissions(String assignmentId) async {
    try {
      final response = await apiClient.dio.get('/api/v1/assignments/$assignmentId/submissions');
      final data = response.data['data']?['submissions'] as List?;
      if (data == null) return [];
      return data.map((json) => AssignmentSubmissionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AssignmentSubmissionModel> gradeSubmission(String submissionId, Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/submissions/$submissionId/grade', data: payload);
      final data = response.data['data'];
      return AssignmentSubmissionModel.fromJson(data['submission'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Reviews ---

  Future<ReviewModel> toggleReviewVisibility(String reviewId, bool isHidden) async {
    try {
      final response = await apiClient.dio.patch('/api/v1/reviews/$reviewId/visibility', data: {'isHidden': isHidden});
      final data = response.data['data'];
      return ReviewModel.fromJson(data['review'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Dashboard ---

  Future<DashboardStatsModel> fetchDashboardStats() async {
    try {
      final response = await apiClient.dio.get('/api/v1/dashboards/instructor');
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
      if (data['errors'] != null) {
        msg += '\nDetails: ' + jsonEncode(data['errors']);
      } else if (data['error'] != null && data['error'] is String) {
        msg += '\nError: ${data['error']}';
      }
      
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
