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

  // ✅ جلب المستخدمين مع Pagination
  Future<Map<String, dynamic>> fetchUsersPaginated({int page = 1, int perPage = 10}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users?page=$page&perPage=$perPage");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<dynamic> usersData = [];
      Map<String, dynamic>? pagination;

      if (responseData is Map) {
        usersData = responseData['data'] ?? [];
        pagination = responseData['pagination'];
      } else if (responseData is List) {
        usersData = responseData;
      }

      final users = usersData.map((userJson) => User.fromJson(userJson)).toList();

      return {
        'users': users,
        'pagination': pagination,
      };
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  // ✅ جلب جميع المستخدمين (للتوافق مع الكود القديم)
  Future<List<User>> fetchUsers() async {
    final result = await fetchUsersPaginated(page: 1, perPage: 10);
    return result['users'] as List<User>;
  }

  // ✅ حل User ID من الاسم
  Future<int?> _resolveUserId(String userName) async {
    final users = await fetchUsers();
    final user = users.where((u) => u.name == userName).firstOrNull;
    return user?.id;
  }

  // ✅ جلب تفاصيل مستخدم معين بالـ ID
  Future<User> getUserDetailsById(int userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userId");

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

  // ✅ جلب تفاصيل مستخدم معين بالاسم (يحل الـ ID تلقائياً)
  Future<User> getUserDetails(String userName) async {
    final userId = await _resolveUserId(userName);
    if (userId == null) {
      throw Exception('user_not_found');
    }
    return getUserDetailsById(userId);
  }

  // ✅ تحديث بيانات المستخدم بالـ ID مباشرة
  Future<User> updateUserById(int userId, {
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

    final url = Uri.parse("$baseUrl/users/$userId");

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

  // ✅ تحديث بيانات المستخدم (باستخدام الاسم - للتوافق مع الكود القديم)
  Future<User> updateUser(String userName, {
    String? newPassword,
    String? newRole,
    bool? active,
    String? newName,
    String? departmentName,
  }) async {
    final userId = await _resolveUserId(userName);
    if (userId == null) {
      throw Exception('user_not_found');
    }
    return updateUserById(userId,
      newPassword: newPassword,
      newRole: newRole,
      active: active,
      newName: newName,
      departmentName: departmentName,
    );
  }

  // ✅ جلب قائمة الأقسام مع Pagination
  Future<List<String>> fetchDepartments() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    // جلب كل الأقسام (بعدد كبير للدروب داون)
    List<String> allDepartments = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final url = Uri.parse("$baseUrl/departments?page=$page&perPage=50");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> data = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          data = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          data = responseData;
        }

        allDepartments.addAll(data.map((dept) => dept['name'].toString()));

        if (pagination != null && pagination['next'] != null) {
          page = pagination['next'];
        } else {
          hasMore = false;
        }
      } else {
        throw Exception('error_code: ${response.statusCode}');
      }
    }

    return allDepartments;
  }

  // ✅ حذف مستخدم بالـ ID مباشرة
  Future<void> deleteUserById(int userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userId");

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

  // ✅ حذف مستخدم بالاسم (للتوافق مع الكود القديم)
  Future<void> deleteUser(String userName) async {
    final userId = await _resolveUserId(userName);
    if (userId == null) {
      throw Exception('user_not_found');
    }
    return deleteUserById(userId);
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

  // ✅ تغيير كلمة المرور بالـ ID
  Future<User> changePasswordById(int userId, String newPassword) async {
    return await updateUserById(userId, newPassword: newPassword);
  }

  // ✅ تغيير كلمة المرور بالاسم (للتوافق)
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

  // ✅ جلب ملفات المستخدم (الـ API الجديد يستخدم uploaderId بدلاً من uploaderName)
  Future<List<Map<String, dynamic>>> getUserUploadedDocuments(String userName) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/documents/uploaded");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // حل الـ userId من الاسم
      final userId = await _resolveUserId(userName);
      // تصفية النتائج: دعم كلا الحقلين uploaderName (قديم) و uploaderId (جديد)
      return data
          .where((doc) => doc['uploaderName'] == userName || (userId != null && doc['uploaderId'] == userId))
          .map((doc) => doc as Map<String, dynamic>)
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }
}