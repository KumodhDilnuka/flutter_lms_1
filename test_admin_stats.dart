import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'));
  
  // login as admin
  try {
    final login = await dio.post('/api/v1/auth/login', data: {
      'email': 'admin@lms.com',
      'password': 'password123',
    });
    final token = login.data['token'];
    
    dio.options.headers['Authorization'] = 'Bearer $token';
    
    final res = await dio.get('/api/v1/courses?page=1&limit=50');
    final courses = res.data['data']['courses'] as List;
    for (var course in courses) {
      print('Course: ${course['title']}');
      print('Instructor field: ${course['instructor']}');
      print('AllocatedInstructorEmail field: ${course['allocatedInstructorEmail']}');
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
}
