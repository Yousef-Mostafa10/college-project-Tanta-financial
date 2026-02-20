import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';

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
        
        // حفظ التوكنات وبيانات المستخدم
        await _saveAuthData(data);
        
        return {
          "success": true,
          "data": data,
          "message": "Login successful"
        };
      } else if (response.statusCode == 401) {
        return {
          "success": false,
          "error": "Invalid credentials",
        };
      } else {
        return {
          "success": false,
          "error": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "error": "Connection error: $e",
      };
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
        
        // تحديث التوكنات المحفوظة
        await _saveAuthData(data);
        
        return {
          "success": true,
          "data": data,
          "message": "Token refreshed successfully"
        };
      } else if (response.statusCode == 401) {
        // Refresh token منتهي الصلاحية - يجب تسجيل الدخول مرة أخرى
        await logout();
        return {
          "success": false,
          "error": "Session expired. Please login again.",
          "requiresLogin": true,
        };
      } else {
        return {
          "success": false,
          "error": "Failed to refresh token: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "error": "Connection error: $e",
      };
    }
  }

  /// 🔹 حفظ بيانات الـ Authentication في SharedPreferences
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ التوكنات
    if (data.containsKey('access_token')) {
      await prefs.setString('token', data['access_token']);
    }
    if (data.containsKey('refresh_token')) {
      await prefs.setString('refresh_token', data['refresh_token']);
    }
    
    // حفظ بيانات المستخدم
    if (data.containsKey('user')) {
      final user = data['user'];
      await prefs.setString('username', user['name'] ?? '');
      await prefs.setString('user_role', user['role'] ?? 'user');
      await prefs.setString('user_group', user['role'] ?? 'user'); // للتوافق العكسي
      
      if (user['id'] != null) {
        await prefs.setInt('user_id', user['id']);
      }
      if (user['departmentName'] != null) {
        await prefs.setString('department_name', user['departmentName']);
      }
      if (user['active'] != null) {
        await prefs.setBool('user_active', user['active']);
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
        token = result['data']['access_token'];
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
