import 'dart:io';
import 'package:flutter_lms/features/instructor/services/instructor_service.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/feature_provider.dart';

class InstructorProvider extends FeatureProvider {
  final InstructorService _instructorService;

  List<CourseModel> _myCourses = [];
  List<CourseModel> get myCourses => _myCourses;

  InstructorProvider(this._instructorService);

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
}
