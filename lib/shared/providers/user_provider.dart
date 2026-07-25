import 'dart:io';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'feature_provider.dart';

class UserProvider extends FeatureProvider {
  final UserService _userService;
  
  User? _currentUserProfile;
  User? get currentUserProfile => _currentUserProfile;

  UserProvider(this._userService);

  Future<void> fetchMyProfile() async {
    final result = await run(() => _userService.getMyProfile());
    if (result != null) {
      _currentUserProfile = result;
      notifyListeners();
    }
  }

  Future<void> fetchMyUserAccount() async {
    final result = await run(() => _userService.getMyUserAccount());
    if (result != null) {
      _currentUserProfile = result;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    final result = await run(() => _userService.updateMyUserAccount(payload));
    if (result != null) {
      _currentUserProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> uploadProfileImage(File image) async {
    final result = await run(() => _userService.uploadMyProfileImage(image));
    if (result != null) {
      _currentUserProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteProfileImage() async {
    final result = await run(() => _userService.deleteMyProfileImage());
    if (result != null) {
      _currentUserProfile = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await run(() => _userService.changeMyPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    ));
    return errorMessage == null;
  }

  Future<bool> deactivateAccount() async {
    await run(() => _userService.deactivateMyAccount());
    return errorMessage == null;
  }
}
