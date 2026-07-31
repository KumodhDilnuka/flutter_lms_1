import 'dart:io' as dart_io;
import 'package:flutter_lms/shared/services/course_service.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/review_model.dart';
import 'feature_provider.dart';

class CourseProvider extends FeatureProvider {
  final CourseService courseService;

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  List<Map<String, dynamic>> _myEnrollments = [];
  List<Map<String, dynamic>> get myEnrollments => _myEnrollments;

  CourseProvider(this.courseService);

  Future<void> fetchCourses({String? categoryId, String? search}) async {
    final result = await run(() => courseService.fetchCourses(categoryId: categoryId, search: search));
    if (result != null) {
      _courses = result;
      notifyListeners();
    }
  }

  Future<CourseModel?> getCourseDetails(String courseId) async {
    return await run(() => courseService.getCourseDetails(courseId));
  }

  Future<bool> enrollStudent(String courseId) async {
    await run(() => courseService.enrollStudent(courseId));
    if (errorMessage == null) {
      await fetchMyEnrollments(); // Refresh enrollments
      return true;
    }
    return false;
  }

  Future<void> fetchMyEnrollments() async {
    final result = await run(() => courseService.fetchMyEnrollments());
    if (result != null) {
      _myEnrollments = result;
      notifyListeners();
    }
  }

  Future<List<SectionModel>> fetchSections(String courseId) async {
    final result = await run(() => courseService.fetchSections(courseId));
    if (result == null) return [];
    return result.map((e) => SectionModel.fromJson(e)).toList();
  }

  Future<List<LessonModel>> fetchLessons(String sectionId) async {
    final result = await run(() => courseService.fetchLessons(sectionId));
    if (result == null) return [];
    return result.map((e) => LessonModel.fromJson(e)).toList();
  }

  // --- Progress State ---
  Map<String, String> _lessonProgressStatus = {};
  int _courseProgressPercentage = 0;

  Map<String, String> get lessonProgressStatus => _lessonProgressStatus;
  int get courseProgressPercentage => _courseProgressPercentage;

  Future<bool> startLesson(String lessonId) async {
    await run(() => courseService.startLesson(lessonId));
    if (errorMessage == null) {
      if (_lessonProgressStatus[lessonId] != 'COMPLETED') {
        _lessonProgressStatus[lessonId] = 'IN_PROGRESS';
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> completeLesson(String lessonId) async {
    final result = await run(() => courseService.completeLesson(lessonId));
    if (result != null) {
      _lessonProgressStatus[lessonId] = 'COMPLETED';
      _courseProgressPercentage = result.progressPercentage;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loadCourseProgress(String courseId) async {
    final result = await run(() => courseService.getCourseProgress(courseId));
    if (result != null) {
      _courseProgressPercentage = result.progressPercentage;
      for (var lesson in result.lessons) {
        _lessonProgressStatus[lesson.lessonId] = lesson.status;
      }
      notifyListeners();
    }
  }

  Future<void> loadEnrollmentProgress(String enrollmentId) async {
    final result = await run(() => courseService.getEnrollmentProgress(enrollmentId));
    if (result != null) {
      _courseProgressPercentage = result.progressPercentage;
      for (var lesson in result.lessons) {
        _lessonProgressStatus[lesson.lessonId] = lesson.status;
      }
      notifyListeners();
    }
  }

  // --- Quiz Consumption ---

  Future<List<QuizModel>> fetchCourseQuizzes(String courseId) async {
    final result = await run(() => courseService.fetchCourseQuizzes(courseId));
    return result ?? [];
  }

  Future<QuizModel?> getStudentQuiz(String quizId) async {
    return await run(() => courseService.getStudentQuiz(quizId));
  }

  Future<QuizAttemptModel?> startQuizAttempt(String quizId) async {
    return await run(() => courseService.startQuizAttempt(quizId));
  }

  Future<QuizAttemptModel?> submitQuizAttempt(String attemptId, Map<String, dynamic> payload) async {
    return await run(() => courseService.submitQuizAttempt(attemptId, payload));
  }

  Future<List<QuizAttemptModel>> fetchMyAttempts(String quizId) async {
    final result = await run(() => courseService.fetchMyAttempts(quizId));
    return result ?? [];
  }

  // --- Assignment Consumption ---

  Future<List<AssignmentModel>> fetchStudentAssignments(String courseId) async {
    final result = await run(() => courseService.fetchStudentAssignments(courseId));
    return result ?? [];
  }

  Future<AssignmentModel?> getStudentAssignment(String assignmentId) async {
    return await run(() => courseService.getStudentAssignment(assignmentId));
  }

  Future<AssignmentSubmissionModel?> submitAssignment(String assignmentId, dart_io.File file) async {
    return await run(() => courseService.submitAssignment(assignmentId, file));
  }

  Future<AssignmentSubmissionModel?> replaceSubmissionFile(String submissionId, dart_io.File file) async {
    return await run(() => courseService.replaceSubmissionFile(submissionId, file));
  }

  Future<AssignmentSubmissionModel?> getMySubmission(String assignmentId) async {
    try {
      return await courseService.getMySubmission(assignmentId);
    } catch (_) {
      // 404 means not submitted yet, which is a valid state. Do not set global errorMessage.
      return null;
    }
  }

  // --- Reviews ---
  Future<List<ReviewModel>> fetchCourseReviews(String courseId) async {
    final result = await run(() => courseService.fetchCourseReviews(courseId));
    return result ?? [];
  }

  Future<ReviewModel?> createReview(String courseId, Map<String, dynamic> payload) async {
    return await run(() => courseService.createReview(courseId, payload));
  }

  Future<ReviewModel?> getReview(String reviewId) async {
    return await run(() => courseService.getReview(reviewId));
  }

  Future<ReviewModel?> updateReview(String reviewId, Map<String, dynamic> payload) async {
    return await run(() => courseService.updateReview(reviewId, payload));
  }

  Future<bool> deleteReview(String reviewId) async {
    await run(() => courseService.deleteReview(reviewId));
    return errorMessage == null;
  }
}
