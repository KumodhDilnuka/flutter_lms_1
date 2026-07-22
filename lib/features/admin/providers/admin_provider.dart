import 'package:flutter_lms/features/admin/services/admin_service.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/models/category_model.dart';
import 'package:flutter_lms/shared/providers/feature_provider.dart';

class AdminProvider extends FeatureProvider {
  final AdminService _adminService;
  
  List<User> _instructors = [];
  List<User> get instructors => _instructors;

  AdminProvider(this._adminService);

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
}
