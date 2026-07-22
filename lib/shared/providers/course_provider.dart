import 'package:flutter_lms/shared/services/course_service.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'feature_provider.dart';

class CourseProvider extends FeatureProvider {
  final CourseService _courseService;

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  List<Map<String, dynamic>> _myEnrollments = [];
  List<Map<String, dynamic>> get myEnrollments => _myEnrollments;

  CourseProvider(this._courseService);

  Future<void> fetchCourses({String? categoryId, String? search}) async {
    final result = await run(() => _courseService.fetchCourses(categoryId: categoryId, search: search));
    if (result != null) {
      _courses = result;
      notifyListeners();
    }
  }

  Future<CourseModel?> getCourseDetails(String courseId) async {
    return await run(() => _courseService.getCourseDetails(courseId));
  }

  Future<bool> enrollStudent(String courseId) async {
    await run(() => _courseService.enrollStudent(courseId));
    if (errorMessage == null) {
      await fetchMyEnrollments(); // Refresh enrollments
      return true;
    }
    return false;
  }

  Future<void> fetchMyEnrollments() async {
    final result = await run(() => _courseService.fetchMyEnrollments());
    if (result != null) {
      _myEnrollments = result;
      notifyListeners();
    }
  }
}
