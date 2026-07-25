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
      debugPrint('⚠️ API Error: ${error.message} (status: ${error.statusCode})');
      return null;
    } catch (error) {
      final errStr = error.toString();
      if (errStr.contains('RAW_JSON:')) {
        errorMessage = errStr.replaceAll('Exception: RAW_JSON: ', 'RAW: ');
      } else {
        errorMessage = "An unexpected error occurred.";
      }
      debugPrint('❌ Unexpected Error: $error');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
