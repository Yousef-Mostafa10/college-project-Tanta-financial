import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../utils/app_error_handler.dart';

/// خدمة Authentication تستخدم الـ endpoints الجديدة
class AuthService {
  final String baseUrl = AppConfig.baseUrl;

  /// 🔹 تسجيل الدخول باستخدام الـ endpoint الجديد
  /// POST /api/v0/auth/login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
        return {'success': true, 'data': data};
      } else {
        // استخراج الـ key الحقيقية من response لترجمتها في الـ UI
        // مثل: INVALID_CREDENTIALS
        final errorKey = AppErrorHandler.extractKeyOrFallback(
          response.body,
          response.statusCode,
        );
        debugPrint('🔴 Login failed [صـ${response.statusCode}] key=$errorKey');
        return {'success': false, 'errorKey': errorKey};
      }
    } catch (e) {
      debugPrint('🔴 Login connection error: $e');
      return {'success': false, 'errorKey': 'no_internet_error'};
    }
  }

  /// 🔹 تحديث الـ access token باستخدام refresh token
  /// POST /api/v0/auth/refresh
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        return {
          "success": false,
          "error": "No refresh token found",
        };
      }

      final url = Uri.parse("$baseUrl/auth/refresh");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "refreshToken": refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        // Refresh token منتهي الصلاحية
        await logout();
        return {
          'success': false,
          'errorKey': 'INVALID_REFRESH_TOKEN',
          'requiresLogin': true,
        };
      } else {
        final errorKey = AppErrorHandler.extractKeyOrFallback(
          response.body,
          response.statusCode,
        );
        return {'success': false, 'errorKey': errorKey};
      }
    } catch (e) {
      debugPrint('🔴 Refresh token error: $e');
      return {'success': false, 'errorKey': 'no_internet_error'};
    }
  }

  /// 🔹 حفظ بيانات الـ Authentication في SharedPreferences
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ التوكنات (دعم لكلا التنسيقين camelCase و snake_case)
    final accessToken = data['access_token'] ?? data['accessToken'] ?? data['token'];
    final refreshToken = data['refresh_token'] ?? data['refreshToken'];

    if (accessToken != null) {
      await prefs.setString('token', accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    
    // حفظ بيانات المستخدم
    final userData = data['user'] ?? data; // في حالة كانت البيانات في الجذر
    if (userData is Map && (userData.containsKey('id') || userData.containsKey('name'))) {
      await prefs.setString('username', userData['name'] ?? '');
      await prefs.setString('user_role', userData['role'] ?? 'user');
      await prefs.setString('user_group', userData['role'] ?? 'user'); // للتوافق العكسي
      
      if (userData['id'] != null) {
        if (userData['id'] is int) {
          await prefs.setInt('user_id', userData['id']);
        } else {
          await prefs.setInt('user_id', int.tryParse(userData['id'].toString()) ?? 0);
        }
      }
      if (userData['departmentName'] != null) {
        await prefs.setString('department_name', userData['departmentName']);
      }
      if (userData['active'] != null) {
        await prefs.setBool('user_active', userData['active'] == true);
      }
    }
  }

  /// 🔹 تسجيل الخروج
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('username');
    await prefs.remove('user_role');
    await prefs.remove('user_group');
    await prefs.remove('user_id');
    await prefs.remove('department_name');
    await prefs.remove('user_active');
  }

  /// 🔹 التحقق من صلاحية الـ token
  /// يحاول تحديث الـ token إذا كان منتهي الصلاحية
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');

    if (token == null) {
      return false;
    }

    // يمكن إضافة منطق للتحقق من انتهاء صلاحية الـ token هنا
    // للآن نفترض أن الـ token صالح إذا كان موجوداً
    return true;
  }

  /// 🔹 الحصول على الـ access token الحالي
  /// يحاول التحديث تلقائياً إذا فشل
  Future<String?> getAccessToken({bool autoRefresh = true}) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null && autoRefresh) {
      // محاولة تحديث الـ token
      final result = await refreshAccessToken();
      if (result['success'] == true) {
        // نأخذ التوكن المحدث من التخزين لضمان الحصول على القيمة الصحيحة
        token = prefs.getString('token');
      }
    }

    return token;
  }

  /// 🔹 الحصول على بيانات المستخدم المحفوظة
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username'),
      'user_id': prefs.getInt('user_id'),
      'role': prefs.getString('user_role'),
      'department_name': prefs.getString('department_name'),
      'active': prefs.getBool('user_active'),
    };
  }
}
