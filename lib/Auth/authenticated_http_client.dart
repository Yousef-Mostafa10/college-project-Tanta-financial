import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../utils/session_manager.dart';

/// HTTP Client Helper مع دعم تحديث Token تلقائي
/// يمكن استخدامه بدلاً من http package مباشرة
class AuthenticatedHttpClient {
  final AuthService _authService = AuthService();

  /// GET request مع authentication تلقائي وتحديث token
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () async {
        final token = await _authService.getAccessToken();
        final finalHeaders = {
          ...?headers,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        return await http.get(url, headers: finalHeaders);
      },
      retryOn401: retryOn401,
    );
  }

  /// POST request مع authentication تلقائي وتحديث token
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () async {
        final token = await _authService.getAccessToken();
        final finalHeaders = {
          ...?headers,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        return await http.post(url, headers: finalHeaders, body: body);
      },
      retryOn401: retryOn401,
    );
  }

  /// PUT request مع authentication تلقائي وتحديث token
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () async {
        final token = await _authService.getAccessToken();
        final finalHeaders = {
          ...?headers,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        return await http.put(url, headers: finalHeaders, body: body);
      },
      retryOn401: retryOn401,
    );
  }

  /// PATCH request مع authentication تلقائي وتحديث token
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () async {
        final token = await _authService.getAccessToken();
        final finalHeaders = {
          ...?headers,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        return await http.patch(url, headers: finalHeaders, body: body);
      },
      retryOn401: retryOn401,
    );
  }

  /// DELETE request مع authentication تلقائي وتحديث token
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () async {
        final token = await _authService.getAccessToken();
        final finalHeaders = {
          ...?headers,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        return await http.delete(url, headers: finalHeaders);
      },
      retryOn401: retryOn401,
    );
  }

  /// دالة داخلية لتنفيذ الـ request مع معالجة 401
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn, {
    required bool retryOn401,
  }) async {
    var response = await requestFn();

    // إذا حصلنا على 401 وكان retryOn401 مفعّل
    if (response.statusCode == 401 && retryOn401) {
      print('🔄 Got 401, attempting to refresh token...');

      // محاولة تحديث الـ token
      final refreshResult = await _authService.refreshAccessToken();

      if (refreshResult['success'] == true) {
        debugPrint('✅ Token refreshed, retrying request...');
        // إعادة المحاولة مع الـ token الجديد
        response = await requestFn();
      } else {
        debugPrint('❌ Token refresh failed: ${refreshResult['error']}');
        
        if (refreshResult['requiresLogin'] == true) {
          // الـ refresh token منتهي - تسجيل خروج تلقائي وتوجيه للـ login
          debugPrint('⚠️ Session expired - redirecting to login...');
          SessionManager.handleSessionExpired();
          throw SessionExpiredException('Session expired. Please login again.');
        }
      }
    }

    return response;
  }
}

/// Exception لحالة انتهاء الجلسة
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}
