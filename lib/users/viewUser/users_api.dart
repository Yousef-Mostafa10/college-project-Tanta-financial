import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_config.dart';
import 'user_model.dart';

class UsersApiService {
  final String baseUrl = AppConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ جلب جميع المستخدمين
  Future<List<User>> fetchUsers() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((userJson) => User.fromJson(userJson)).toList();
      } else {
        throw Exception('Invalid API response format');
      }
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  // ✅ جلب تفاصيل مستخدم معين
  Future<User> getUserDetails(String userName) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userName");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else if (response.statusCode == 404) {
      throw Exception('user_not_found');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  // ✅ تحديث بيانات المستخدم
  Future<User> updateUser(String userName, {
    String? newPassword,
    String? newRole,
    bool? active,
    String? newName,
    String? departmentName,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userName");

    Map<String, dynamic> updateData = {};

    if (newPassword != null && newPassword.isNotEmpty) {
      updateData['password'] = newPassword;
    }
    if (newRole != null) {
      updateData['role'] = newRole;
    }
    if (active != null) {
      updateData['active'] = active;
    }
    if (newName != null && newName.isNotEmpty) {
      updateData['name'] = newName;
    }
    if (departmentName != null) {
      updateData['departmentName'] = departmentName;
    }

    if (updateData.isEmpty) {
      throw Exception('no_changes_provided');
    }

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('permission_error');
    } else if (response.statusCode == 404) {
      throw Exception('user_not_found');
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else if (response.statusCode == 409) {
      throw Exception('user_already_exists');
    } else {
      throw Exception('error_code: ${response.statusCode}: ${response.body}');
    }
  }

  // ✅ جلب قائمة الأقسام
  Future<List<String>> fetchDepartments() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/departments");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((dept) => dept['name'].toString()).toList();
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  // ✅ حذف مستخدم
  Future<void> deleteUser(String userName) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userName");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      throw Exception('permission_error');
    } else if (response.statusCode == 404) {
      throw Exception('user_not_found');
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}: ${response.body}');
    }
  }

  // ✅ إنشاء مستخدم جديد
  Future<User> createUser({
    required String name,
    required String password,
    required String role,
    String? departmentName,
    bool active = true,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users");

    final userData = {
      "name": name,
      "password": password,
      "role": role,
      "active": active,
      if (departmentName != null) "departmentName": departmentName,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 409) {
      throw Exception('user_already_exists');
    } else if (response.statusCode == 403) {
      throw Exception('permission_error');
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}: ${response.body}');
    }
  }

  // ✅ تغيير كلمة المرور فقط
  Future<User> changePassword(String userName, String newPassword) async {
    return await updateUser(userName, newPassword: newPassword);
  }

  // ✅ تغيير حالة المستخدم
  Future<User> toggleUserStatus(String userName, bool active) async {
    return await updateUser(userName, active: active);
  }

  // ✅ تغيير دور المستخدم
  Future<User> changeUserRole(String userName, String newRole) async {
    return await updateUser(userName, newRole: newRole);
  }

  // ✅ تغيير قسم المستخدم
  Future<User> changeUserDepartment(String userName, String departmentName) async {
    return await updateUser(userName, departmentName: departmentName);
  }
}