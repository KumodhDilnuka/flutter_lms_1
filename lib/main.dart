import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';

import 'pages/admin/admin_dashboard.dart';
import 'pages/instructor/instructor_dashboard.dart';
import 'pages/student/student_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
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
      return StudentDashboard(email: email);
    }
  }
}

