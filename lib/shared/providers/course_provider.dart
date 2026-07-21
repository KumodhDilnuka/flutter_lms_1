
import 'package:flutter_lms/shared/services/course_service.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'feature_provider.dart';

class CourseProvider extends FeatureProvider {
  final CourseService _courseService;

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  CourseProvider(this._courseService);

  Future<void> fetchCourses() async {
    final result = await run(() => _courseService.fetchCourses());
    if (result != null) {
      _courses = result;
      notifyListeners();
    }
  }

  Future<bool> createCourse(CourseModel course) async {
    final result = await run(() => _courseService.createCourse(course));
    if (result != null) {
      _courses.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateCourse(CourseModel course) async {
    final result = await run(() => _courseService.updateCourse(course));
    if (result != null) {
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = result;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> enrollStudent(String courseId) async {
    await run(() => _courseService.enrollStudent(courseId));
    // Since it returns void, result being null could mean error or success.
    // wait, run() returns T?. if it returns null on success for a void method, we need to check if there is an errorMessage.
    if (errorMessage == null) {
      // Re-fetch courses to get updated state
      await fetchCourses();
      return true;
    }
    return false;
  }

  Future<bool> approveStudent(String courseId, String studentEmail) async {
    await run(() => _courseService.approveStudent(courseId, studentEmail));
    if (errorMessage == null) {
      await fetchCourses();
      return true;
    }
    return false;
  }
}
