import 'package:dio/dio.dart';

class DioClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://fakestoreapi.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static String? _token;

  DioClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('➡️ [REQUEST] ${options.method} ${options.uri}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        print('⚠️ [ERROR] ${e.message}');
        // 🔁 Retry nếu lỗi mạng hoặc timeout
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          print('🔁 Thử lại request sau 2 giây...');
          await Future.delayed(const Duration(seconds: 2));
          try {
            final response = await _dio.request(
              e.requestOptions.path,
              options: Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              ),
              data: e.requestOptions.data,
              queryParameters: e.requestOptions.queryParameters,
            );
            return handler.resolve(response);
          } catch (err) {
            return handler.next(err as DioException);
          }
        }
        return handler.next(e);
      },
    ));
  }

  void setToken(String? token) => _token = token;

  Dio get dio => _dio;
}
