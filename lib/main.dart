import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'login_and_signup_pagers/login_page.dart';
import 'pages/profile/student_profile_page.dart';
import 'pages/profile/instructor_profile_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          if (role.toUpperCase() != 'ADMIN')
            IconButton(
              onPressed: () {
                if (role.toUpperCase() == 'INSTRUCTOR') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstructorProfilePage(email: email),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfilePage(email: email),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.account_circle_rounded),
              tooltip: 'My Profile',
            ),
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'You are logged in as: $role',
              style: const TextStyle(fontSize: 18),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Email: $email',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

