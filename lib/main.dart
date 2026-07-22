import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme/app_theme.dart';
import 'package:flutter_lms/features/auth/screens/splash_page.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/services/auth_service.dart';
import 'shared/providers/auth_provider.dart';
import 'package:flutter_lms/shared/services/course_service.dart';
import 'shared/providers/course_provider.dart';
import 'package:flutter_lms/features/admin/services/admin_service.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/features/instructor/services/instructor_service.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';

import 'package:flutter_lms/features/admin/dashboard/screens/admin_dashboard.dart';
import 'package:flutter_lms/features/instructor/dashboard/screens/instructor_dashboard.dart';
import 'package:flutter_lms/features/student/student_main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  const secureStorage = FlutterSecureStorage();
  final tokenStorage = TokenStorage(secureStorage);
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient);
  final courseService = CourseService(apiClient);
  final adminService = AdminService(apiClient);
  final instructorService = InstructorService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService, tokenStorage)),
        ChangeNotifierProvider(create: (_) => CourseProvider(courseService)),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminService)),
        ChangeNotifierProvider(create: (_) => InstructorProvider(instructorService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter LMS',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final String role;
  final String email;

  const HomePage({super.key, required this.role, this.email = ''});

  @override
  Widget build(BuildContext context) {
    final userRole = role.toUpperCase();
    
    if (userRole == 'ADMIN') {
      return const AdminDashboard();
    } else if (userRole == 'INSTRUCTOR') {
      return InstructorDashboard(email: email);
    } else {
      return StudentMainScreen(email: email);
    }
  }
}

