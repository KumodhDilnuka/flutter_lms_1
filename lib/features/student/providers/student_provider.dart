import 'package:flutter_lms/shared/providers/feature_provider.dart';
import '../services/student_service.dart';
import '../../../shared/models/student_profile_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';

class StudentProvider extends FeatureProvider {
  final StudentService _studentService;
  
  StudentProfileModel? _studentProfile;
  StudentProfileModel? get studentProfile => _studentProfile;

  StudentProvider(this._studentService);

  Future<void> fetchMyProfile() async {
    final result = await run(() => _studentService.getMyProfile());
    if (result != null) {
      _studentProfile = result;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    final result = await run(() => _studentService.updateMyProfile(payload));
    if (result != null) {
      _studentProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> createProfile(Map<String, dynamic> payload) async {
    final result = await run(() => _studentService.createMyProfile(payload));
    if (result != null) {
      _studentProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteProfile() async {
    await run(() => _studentService.deleteMyProfile());
    if (errorMessage == null) {
      _studentProfile = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<DashboardStatsModel?> fetchDashboardStats() async {
    return await run(() => _studentService.fetchDashboardStats());
  }
}
