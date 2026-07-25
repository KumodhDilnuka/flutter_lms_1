import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  
  // login as admin
  try {
    final login = await dio.post('/api/v1/auth/login', data: {
      'email': 'admin@lms.com',
      'password': 'password123'
    });
    final token = login.data['data']['token'];
    
    dio.options.headers['Authorization'] = 'Bearer \$token';
    
    final res = await dio.get('/api/v1/users');
    print(res.data);
  } catch (e) {
    if (e is DioException) {
      print(e.response?.data ?? e.message);
    } else {
      print(e);
    }
  }
}
