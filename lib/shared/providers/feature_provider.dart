import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';

class FeatureProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<T?> run<T>(Future<T> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (error) {
      errorMessage = "An unexpected error occurred.";
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
