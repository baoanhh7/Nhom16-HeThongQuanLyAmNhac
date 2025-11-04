// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$ip$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      throw ApiException('Có lỗi kết nối. Vui lòng thử lại!');
    }
  }

  static Future<Map<String, dynamic>> get({
    required String endpoint,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$ip$endpoint');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ).timeout(_timeout);

      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      throw ApiException('Có lỗi kết nối. Vui lòng thử lại!');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

// Auth specific API calls
class AuthApiService {
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await ApiService.post(
      endpoint: 'Users/register',
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone ?? '',
        'role': 'member',
      },
    );
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required int userId,
    required String verificationCode,
  }) async {
    return await ApiService.post(
      endpoint: 'Users/verify-email',
      body: {
        'userId': userId,
        'verificationCode': verificationCode,
      },
    );
  }

  static Future<Map<String, dynamic>> resendVerification({
    required int userId,
  }) async {
    return await ApiService.post(
      endpoint: 'Users/resend-verification',
      body: {
        'userId': userId,
      },
    );
  }

    static Future<Map<String, dynamic>> login({
    required String email, // Có thể là email hoặc username
    required String password,
  }) async {
    return await ApiService.post(
      endpoint: 'Users/login',
      body: {
        'username': email.trim(), // Backend expect 'username' field
        'password': password,
      },
    );
  }
}