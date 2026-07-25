import 'package:flutter_lms/features/admin/services/admin_service.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/models/category_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';
import 'package:flutter_lms/shared/providers/feature_provider.dart';

class AdminProvider extends FeatureProvider {
  final AdminService _adminService;
  
  List<User> _instructors = [];
  List<User> get instructors => _instructors;

  List<User> _users = [];
  List<User> get users => _users;

  List<CourseModel> _adminCourses = [];
  List<CourseModel> get adminCourses => _adminCourses;

  AdminProvider(this._adminService);

  Future<void> fetchUsers({String? role, String? status, String? search}) async {
    final result = await run(() => _adminService.fetchUsers(role: role, status: status, search: search));
    if (result != null) {
      _users = result;
      notifyListeners();
    }
  }

  Future<bool> suspendUser(String userId) async {
    await run(() => _adminService.suspendUser(userId));
    if (errorMessage == null) {
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(status: 'SUSPENDED');
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> reactivateUser(String userId) async {
    await run(() => _adminService.reactivateUser(userId));
    if (errorMessage == null) {
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(status: 'ACTIVE');
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // Legacy fetchInstructors that only returns instructors
  Future<void> fetchInstructors() async {
    final result = await run(() => _adminService.fetchInstructors());
    if (result != null) {
      _instructors = result;
      notifyListeners();
    }
  }

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  Future<void> fetchCategories() async {
    final result = await run(() => _adminService.fetchCategories());
    if (result != null) {
      _categories = result;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name, String description) async {
    final result = await run(() => _adminService.createCategory(name, description));
    if (result != null) {
      _categories.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateCategory(String id, String name, String description) async {
    final result = await run(() => _adminService.updateCategory(id, name, description));
    if (result != null) {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = result;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    await run(() => _adminService.toggleCategoryStatus(id, isActive));
    if (errorMessage == null) {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final current = _categories[index];
        _categories[index] = CategoryModel(
          id: current.id,
          name: current.name,
          slug: current.slug,
          description: current.description,
          isActive: isActive,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<DashboardStatsModel?> fetchDashboardStats() async {
    return await run(() => _adminService.fetchDashboardStats());
  }

  // --- Admin LMS Management ---

  Future<void> fetchAllCourses() async {
    final result = await run(() => _adminService.fetchAllCourses());
    if (result != null) {
      _adminCourses = result;
      notifyListeners();
    }
  }

  Future<bool> archiveCourseAsAdmin(String courseId) async {
    await run(() => _adminService.archiveCourseAsAdmin(courseId));
    if (errorMessage == null) {
      final index = _adminCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _adminCourses.removeAt(index);
        notifyListeners();
      }
      return true;
    }
    return false;
  }
}
