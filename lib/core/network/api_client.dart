import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';


class ApiClient {
  final TokenStorage tokenStorage;
  late final Dio dio;

  ApiClient(this.tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isRefreshCall = error.requestOptions.path == '/api/v1/auth/refresh-token';

        if (!isUnauthorized || isRefreshCall) {
          return handler.next(error);
        }

        final refreshToken = await tokenStorage.readRefreshToken();
        if (refreshToken == null) {
          await tokenStorage.clear();
          return handler.next(error);
        }

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
          final refreshResponse = await refreshDio.post(
            '/api/v1/auth/refresh-token',
            data: {'refreshToken': refreshToken},
          );

          final tokens = refreshResponse.data['data']['tokens'];
          final role = await tokenStorage.readRole() ?? '';
          
          await tokenStorage.saveSession(
            accessToken: tokens['accessToken'],
            refreshToken: tokens['refreshToken'],
            role: role,
          );

          final request = error.requestOptions;
          request.headers['Authorization'] = 'Bearer ${tokens['accessToken']}';
          final retried = await dio.fetch(request);
          return handler.resolve(retried);
        } catch (_) {
          await tokenStorage.clear();
          return handler.next(error);
        }
      },
    ));
  }
}
