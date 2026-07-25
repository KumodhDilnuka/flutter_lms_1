import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio();
  // We need a login token to test the API.
  // We can login as the instructor.
  try {
    final loginRes = await dio.post(
      'http://localhost:5000/api/v1/auth/login',
      data: {'email': 'instructor@example.com', 'password': 'password123'},
    );
    final token = loginRes.data['data']['accessToken'];
    print('Logged in, token: \$token');

    dio.options.headers['Authorization'] = 'Bearer \$token';

    // Fetch instructor courses
    final coursesRes = await dio.get('http://localhost:5000/api/v1/courses/instructor');
    final courses = coursesRes.data['data']['courses'] as List;
    if (courses.isEmpty) {
      print('No courses');
      return;
    }
    final courseId = courses.first['id'] ?? courses.first['_id'];
    
    // Fetch quizzes for course
    final quizzesRes = await dio.get('http://localhost:5000/api/v1/courses/\$courseId/quizzes/instructor');
    final quizzes = quizzesRes.data['data']['quizzes'] as List;
    if (quizzes.isEmpty) {
      print('No quizzes');
      return;
    }
    final quizId = quizzes.first['id'] ?? quizzes.first['_id'];
    
    // Get detailed quiz
    final detailRes = await dio.get('http://localhost:5000/api/v1/quizzes/\$quizId/instructor');
    print(jsonEncode(detailRes.data));

  } catch (e) {
    if (e is DioException) {
      print('DioError: \${e.response?.data}');
    } else {
      print('Error: \$e');
    }
  }
}
