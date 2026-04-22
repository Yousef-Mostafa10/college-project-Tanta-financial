import 'dart:convert';
import '../../utils/app_error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_config.dart';
import '../../utils/app_error_handler.dart';
import 'user_model.dart';
import '../../Auth/authenticated_http_client.dart';

class UsersApiService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  // Helper method for legacy compatibility if needed
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ جلب المستخدمين مع Pagination والبحث والفلاتر
  Future<Map<String, dynamic>> fetchUsersPaginated({
    int page = 1,
    int perPage = 10,
    String? name,
    String? role,
    String? department,
    bool? active,
  }) async {
    String urlString = "$baseUrl/users?page=$page&perPage=$perPage";
    if (name != null && name.isNotEmpty) {
      urlString += "&name=${Uri.encodeComponent(name)}";
    }
    if (role != null && role != 'all') {
      urlString += "&role=${role.toUpperCase()}";
    }
    if (department != null && department != 'all') {
      urlString += "&department=${Uri.encodeComponent(department)}";
    }
    if (active != null) {
      urlString += "&active=$active";
    }

    final url = Uri.parse(urlString);

    final response = await _httpClient.get(
      url,
      headers: {
        "Accept": "application/json",
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
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
    }
  }

  // ✅ جلب جميع المستخدمين (للتوافق مع الكود القديم)
  Future<List<User>> fetchUsers() async {
    List<User> allUsers = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await fetchUsersPaginated(page: page, perPage: 50);
      final List<User> fetchedUsers = result['users'] as List<User>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      allUsers.addAll(fetchedUsers);

      if (pagination != null && pagination['next'] != null) {
        page = pagination['next'];
      } else {
        hasMore = false;
      }
    }
    return allUsers;
  }

  // ✅ حل User ID من الاسم
  Future<int?> _resolveUserId(String userName) async {
    final users = await fetchUsers();
    final user = users.where((u) => u.name == userName).firstOrNull;
    return user?.id;
  }

  // ✅ جلب تفاصيل مستخدم معين بالـ ID
  Future<User> getUserDetailsById(int userId) async {
    final url = Uri.parse("$baseUrl/users/$userId");

    final response = await _httpClient.get(
      url,
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else if (response.statusCode == 404) {
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, 404));
    } else {
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
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

    final response = await _httpClient.patch(
      url,
      headers: {
        "Accept": "application/json",
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      // استخراج الـ key الحقيقية من الباك أند وإرماؤها
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
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
  Future<Map<String, dynamic>> fetchDepartmentsPaginated({int page = 1, int perPage = 10}) async {
    final url = Uri.parse("$baseUrl/departments?page=$page&perPage=$perPage");

    final response = await _httpClient.get(
      url,
      headers: {
        "Accept": "application/json",
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

      final List<String> departments = data.map((dept) => dept['name'].toString()).toList();
      
      return {
        'departments': departments,
        'pagination': pagination,
      };
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  // ✅ جلب كل الأقسام (للتوافق)
  Future<List<String>> fetchDepartments() async {
    List<String> allDepartments = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await fetchDepartmentsPaginated(page: page, perPage: 50);
      final List<String> depts = result['departments'] as List<String>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      allDepartments.addAll(depts);

      if (pagination != null && pagination['next'] != null) {
        page = pagination['next'];
      } else {
        hasMore = false;
      }
    }
    return allDepartments;
  }

  // ✅ حذف مستخدم بالـ ID مباشرة
  Future<void> deleteUserById(int userId) async {
    final url = Uri.parse("$baseUrl/users/$userId");

    final response = await _httpClient.delete(
      url,
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      // استخراج الـ key الحقيقية من الباك أند (USER_ENGAGED_IN_SYSTEM, MISSING_ROLE, etc.)
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
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
    final url = Uri.parse("$baseUrl/users");

    final userData = {
      "name": name,
      "password": password,
      "role": role,
      "active": active,
      if (departmentName != null) "departmentName": departmentName,
    };

    final response = await _httpClient.post(
      url,
      headers: {
        "Accept": "application/json",
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      // استخراج الـ key الحقيقية من الباك أند
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
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
    final url = Uri.parse("$baseUrl/documents/uploaded");

    final response = await _httpClient.get(
      url,
      headers: {
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> documents = [];
      
      if (responseData is Map) {
        documents = responseData['data'] ?? [];
      } else if (responseData is List) {
        documents = responseData;
      }

      final userId = await _resolveUserId(userName);
      
      return documents
          .where((doc) {
            if (doc is! Map) return false;
            return doc['uploaderName'] == userName || 
                   (userId != null && doc['uploaderId'] == userId);
          })
          .map((doc) => doc as Map<String, dynamic>)
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
    }
  }
}
