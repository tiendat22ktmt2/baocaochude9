import 'package:dio/dio.dart';
import 'dio_client.dart';

class AuthService {
  final DioClient _dioClient = DioClient();

  Future<String> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: {"username": username, "password": password},
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      final token = response.data['token'];
      if (token == null) throw Exception('Không nhận được token từ server');

      _dioClient.setToken(token);
      print('✅ Token lưu: $token');
      return token;

    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('❌ Lỗi không xác định: $e');
    }
  }

  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _dioClient.dio.get('/products');
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

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
