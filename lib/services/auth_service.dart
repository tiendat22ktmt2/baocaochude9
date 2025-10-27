import 'package:dio/dio.dart';
import 'dio_client.dart';

class AuthService {
  final DioClient _dioClient = DioClient();

  /// Đăng nhập -> lấy token (có retry)
  Future<String> login(String username, String password) async {
    int retryCount = 0;
    const int maxRetry = 3;

    while (retryCount < maxRetry) {
      try {
        final response = await _dioClient.dio.post(
          '/auth/login',
          data: {
            "username": username,
            "password": password,
          },
          options: Options(headers: {"Content-Type": "application/json"}),
        );

        final token = response.data['token'];
        if (token != null) {
          _dioClient.setToken(token);
          print('✅ Token lưu: $token');
          return token;
        } else {
          throw Exception('Không nhận được token từ server');
        }
      } on DioException catch (e) {
        final message = _handleError(e);
        print('⚠️ Lỗi đăng nhập: $message');

        // 👉 Retry khi là lỗi mạng hoặc timeout
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          retryCount++;
          print('🔁 Thử lại lần $retryCount/$maxRetry sau 2s...');
          await Future.delayed(const Duration(seconds: 2));
          continue; // thử lại
        } else {
          throw Exception(message); // dừng khi lỗi không retry được
        }
      } catch (e) {
        throw Exception('❌ Lỗi không xác định: $e');
      }
    }

    throw Exception('🚫 Đăng nhập thất bại sau $maxRetry lần thử.');
  }

  /// Lấy danh sách sản phẩm (có retry)
  Future<List<dynamic>> getProducts() async {
    int retryCount = 0;
    const int maxRetry = 3;

    while (retryCount < maxRetry) {
      try {
        final response = await _dioClient.dio.get('/products');
        return response.data;
      } on DioException catch (e) {
        final message = _handleError(e);
        print('⚠️ Lỗi tải sản phẩm: $message');

        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          retryCount++;
          print('🔁 Thử lại lần $retryCount/$maxRetry sau 2s...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          throw Exception(message);
        }
      }
    }

    throw Exception('🚫 Lấy sản phẩm thất bại sau $maxRetry lần thử.');
  }

  /// Xử lý lỗi trả về
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối quá thời gian.';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu quá thời gian.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu quá thời gian.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'Sai username hoặc password.';
        }
        return 'Lỗi server: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối tới server.';
      default:
        return 'Lỗi không xác định: ${e.message}';
    }
  }
}
