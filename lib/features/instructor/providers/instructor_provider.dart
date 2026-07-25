import 'dart:io';
import 'package:flutter_lms/features/instructor/services/instructor_service.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/instructor_profile_model.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/review_model.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';
import 'package:flutter_lms/shared/providers/feature_provider.dart';

class InstructorProvider extends FeatureProvider {
  final InstructorService _instructorService;

  List<CourseModel> _myCourses = [];
  List<CourseModel> get myCourses => _myCourses;

  InstructorProfileModel? _instructorProfile;
  InstructorProfileModel? get instructorProfile => _instructorProfile;

  InstructorProvider(this._instructorService);

  // --- Profile Management ---
  Future<void> fetchMyProfile() async {
    final result = await run(() => _instructorService.getMyProfile());
    if (result != null) {
      _instructorProfile = result;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    final result = await run(() => _instructorService.updateMyProfile(payload));
    if (result != null) {
      _instructorProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> createProfile(Map<String, dynamic> payload) async {
    final result = await run(() => _instructorService.createMyProfile(payload));
    if (result != null) {
      _instructorProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteProfile() async {
    await run(() => _instructorService.deleteMyProfile());
    if (errorMessage == null) {
      _instructorProfile = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Course Management ---
  Future<void> fetchMyCourses() async {
    final result = await run(() => _instructorService.fetchMyCourses());
    if (result != null) {
      _myCourses = result;
      notifyListeners();
    }
  }

  Future<CourseModel?> getCourseDetails(String courseId) async {
    return await run(() => _instructorService.getCourseDetails(courseId));
  }

  Future<bool> createCourse(Map<String, dynamic> payload) async {
    final result = await run(() => _instructorService.createCourse(payload));
    if (result != null) {
      _myCourses.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<CourseModel?> updateCourse(String courseId, Map<String, dynamic> payload) async {
    final result = await run(() => _instructorService.updateCourse(courseId, payload));
    if (result != null) {
      final index = _myCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _myCourses[index] = result;
        notifyListeners();
      }
    }
    return result;
  }

  Future<bool> publishCourse(String courseId) async {
    await run(() => _instructorService.publishCourse(courseId));
    if (errorMessage == null) {
      // Refresh course list to get updated status
      await fetchMyCourses();
      return true;
    }
    return false;
  }

  Future<bool> archiveCourse(String courseId) async {
    await run(() => _instructorService.archiveCourse(courseId));
    if (errorMessage == null) {
      // Refresh course list or update status locally
      await fetchMyCourses();
      return true;
    }
    return false;
  }

  Future<bool> removeThumbnail(String courseId) async {
    await run(() => _instructorService.removeThumbnail(courseId));
    if (errorMessage == null) {
      // We could ideally just null out the thumbnail in the local model, but refreshing is safer
      await fetchMyCourses();
      return true;
    }
    return false;
  }

  Future<bool> uploadThumbnail(String courseId, File thumbnail) async {
    final result = await run(() => _instructorService.uploadThumbnail(courseId, thumbnail));
    if (result != null) {
      final index = _myCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _myCourses[index] = result;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // Section Management
  Future<List<SectionModel>> fetchSections(String courseId) async {
    final result = await run(() => _instructorService.fetchSections(courseId));
    return result ?? [];
  }

  Future<SectionModel?> createSection(String courseId, String title, String description, bool isPublished) async {
    return await run(() => _instructorService.createSection(courseId, title, description, isPublished));
  }

  Future<SectionModel?> updateSection(String sectionId, String title, String description) async {
    return await run(() => _instructorService.updateSection(sectionId, title, description));
  }

  Future<SectionModel?> publishSection(String sectionId) async {
    return await run(() => _instructorService.publishSection(sectionId));
  }

  Future<bool> deleteSection(String sectionId) async {
    await run(() => _instructorService.deleteSection(sectionId));
    return errorMessage == null;
  }

  Future<bool> reorderSection(String sectionId, int newPosition) async {
    await run(() => _instructorService.reorderSection(sectionId, newPosition));
    return errorMessage == null;
  }

  // Lesson Management
  Future<List<LessonModel>> fetchLessons(String sectionId) async {
    final result = await run(() => _instructorService.fetchLessons(sectionId));
    return result ?? [];
  }

  Future<LessonModel?> createLesson(String sectionId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.createLesson(sectionId, payload));
  }

  Future<LessonModel?> uploadLessonVideo(String lessonId, File video) async {
    return await run(() => _instructorService.uploadLessonVideo(lessonId, video));
  }

  Future<LessonModel?> uploadLessonDocument(String lessonId, File document) async {
    return await run(() => _instructorService.uploadLessonDocument(lessonId, document));
  }

  Future<LessonModel?> publishLesson(String lessonId) async {
    return await run(() => _instructorService.publishLesson(lessonId));
  }

  Future<LessonModel?> getLesson(String lessonId) async {
    return await run(() => _instructorService.getLesson(lessonId));
  }

  Future<LessonModel?> updateLesson(String lessonId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.updateLesson(lessonId, payload));
  }

  Future<bool> reorderLesson(String lessonId, int newPosition) async {
    await run(() => _instructorService.reorderLesson(lessonId, newPosition));
    return errorMessage == null;
  }

  Future<bool> deleteLessonVideo(String lessonId) async {
    await run(() => _instructorService.deleteLessonVideo(lessonId));
    return errorMessage == null;
  }

  Future<bool> deleteLessonDocument(String lessonId) async {
    await run(() => _instructorService.deleteLessonDocument(lessonId));
    return errorMessage == null;
  }

  Future<bool> deleteLesson(String lessonId) async {
    await run(() => _instructorService.deleteLesson(lessonId));
    return errorMessage == null;
  }

  // --- Quiz Management ---

  Future<QuizModel?> createQuiz(String courseId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.createQuiz(courseId, payload));
  }

  Future<List<QuizModel>> fetchInstructorQuizzes(String courseId) async {
    final result = await run(() => _instructorService.fetchInstructorQuizzes(courseId));
    return result ?? [];
  }

  Future<QuizModel?> getInstructorQuiz(String quizId) async {
    return await run(() async {
      try {
        return await _instructorService.getInstructorQuiz(quizId);
      } catch (e) {
        print('Error in getInstructorQuiz: \$e');
        rethrow;
      }
    });
  }

  Future<QuizModel?> updateQuiz(String quizId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.updateQuiz(quizId, payload));
  }

  Future<bool> deleteQuiz(String quizId) async {
    await run(() => _instructorService.deleteQuiz(quizId));
    return errorMessage == null;
  }

  Future<bool> publishQuiz(String quizId) async {
    await run(() => _instructorService.publishQuiz(quizId));
    return errorMessage == null;
  }

  Future<QuestionModel?> createQuestion(String quizId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.createQuestion(quizId, payload));
  }

  Future<QuestionModel?> updateQuestion(String questionId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.updateQuestion(questionId, payload));
  }

  Future<bool> deleteQuestion(String questionId) async {
    await run(() => _instructorService.deleteQuestion(questionId));
    return errorMessage == null;
  }

  Future<List<QuizAttemptModel>> fetchInstructorAttempts(String quizId) async {
    final result = await run(() => _instructorService.fetchInstructorAttempts(quizId));
    return result ?? [];
  }

  // --- Assignment Management ---

  Future<AssignmentModel?> createAssignment(String courseId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.createAssignment(courseId, payload));
  }

  Future<List<AssignmentModel>> fetchInstructorAssignments(String courseId) async {
    final result = await run(() => _instructorService.fetchInstructorAssignments(courseId));
    return result ?? [];
  }

  Future<AssignmentModel?> updateAssignment(String assignmentId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.updateAssignment(assignmentId, payload));
  }

  Future<AssignmentModel?> uploadAssignmentAttachment(String assignmentId, File file) async {
    return await run(() => _instructorService.uploadAssignmentAttachment(assignmentId, file));
  }

  Future<bool> deleteAttachment(String assignmentId) async {
    await run(() => _instructorService.deleteAttachment(assignmentId));
    return errorMessage == null;
  }

  Future<bool> publishAssignment(String assignmentId) async {
    await run(() => _instructorService.publishAssignment(assignmentId));
    return errorMessage == null;
  }
  
  Future<bool> deleteAssignment(String assignmentId) async {
    await run(() => _instructorService.deleteAssignment(assignmentId));
    return errorMessage == null;
  }

  Future<List<AssignmentSubmissionModel>> fetchInstructorSubmissions(String assignmentId) async {
    final result = await run(() => _instructorService.fetchInstructorSubmissions(assignmentId));
    return result ?? [];
  }

  Future<AssignmentSubmissionModel?> gradeSubmission(String submissionId, Map<String, dynamic> payload) async {
    return await run(() => _instructorService.gradeSubmission(submissionId, payload));
  }

  // --- Reviews ---

  Future<bool> toggleReviewVisibility(String reviewId, bool isHidden) async {
    await run(() => _instructorService.toggleReviewVisibility(reviewId, isHidden));
    return errorMessage == null;
  }

  Future<DashboardStatsModel?> fetchDashboardStats() async {
    return await run(() => _instructorService.fetchDashboardStats());
  }

  // --- Enrollment Management ---

  Future<List<Map<String, dynamic>>> getCourseEnrollments(String courseId) async {
    final result = await run(() => _instructorService.getCourseEnrollments(courseId));
    return result ?? [];
  }

  Future<bool> approveEnrollment(String enrollmentId) async {
    await run(() => _instructorService.approveEnrollment(enrollmentId));
    return errorMessage == null;
  }

  Future<bool> rejectEnrollment(String enrollmentId) async {
    await run(() => _instructorService.rejectEnrollment(enrollmentId));
    return errorMessage == null;
  }
}
