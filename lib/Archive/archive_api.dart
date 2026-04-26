import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_error_handler.dart';
class ArchiveApi {
  final String baseUrl;
  final String? userToken;
  final String userGroup;

  ArchiveApi({
    required this.baseUrl,
    required this.userToken,
    this.userGroup = 'user',
  });

  // 🔹 جلب أنواع المعاملات مع Pagination (صفحة واحدة)
  Future<Map<String, dynamic>> fetchTypesPage({int page = 1, int perPage = 10}) async {
    try {
      if (userToken == null) return {'types': [], 'hasMore': false};

      final response = await http.get(
        Uri.parse("$baseUrl/transactions/types?page=$page&perPage=$perPage"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<String> types = [];
        bool hasMore = false;

        if (responseData is Map) {
          final typesList = responseData['data'] ?? responseData['transactionTypes'] ?? [];
          for (var item in typesList) {
            if (item["name"] != null) {
              types.add(item["name"]);
            }
          }
          final pagination = responseData['pagination'];
          if (pagination != null && pagination['next'] != null) {
            hasMore = true;
          }
        } else if (responseData is List) {
          for (var item in responseData) {
            if (item["name"] != null) {
              types.add(item["name"]);
            }
          }
        }

        return {
          'types': types,
          'hasMore': hasMore,
        };
      }
      return {'types': [], 'hasMore': false};
    } catch (e) {
      print("⚠️ Error fetching types page: $e");
      return {'types': [], 'hasMore': false};
    }
  }

  // 🔹 جلب أنواع المعاملات (للتوافق - يجلب الكل)
  Future<List<String>> fetchTypes() async {
    final result = await fetchTypesPage(page: 1, perPage: 1000);
    List<String> allTypes = ['All Types'];
    allTypes.addAll(result['types'] as List<String>);
    return allTypes.toSet().toList();
  }

  // 🔹 جلب جميع العمليات (الأرشيف) مع دعم الفلترة من السيرفر
  Future<Map<String, dynamic>> fetchArchiveRequests({
    int page = 1,
    int perPage = 10,
    String? priority,
    String? typeName,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      // Admin فقط يستطيع جلب كل المعاملات بـ query=all
      // اليوزر العادي والمحاسب يجلبان معاملاتهم فقط
      if (userGroup.toLowerCase() == 'admin') {
        queryParams['query'] = 'all';
      }

      if (priority != null && priority != 'All') {
        queryParams["priority"] = priority.toUpperCase();
      }
      if (typeName != null && typeName != 'All Types') {
        queryParams["typeName"] = typeName;
      }
      if (search != null && search.isNotEmpty) {
        if (RegExp(r'^\d+$').hasMatch(search)) {
          queryParams["creatorId"] = search;
        } else {
          queryParams["title"] = search;
        }
      }
      if (status != null && status != 'All') {
        if (status == 'Fulfilled') {
          queryParams["fulfilled"] = "true";
        } else {
          String serverStatus = status.toUpperCase();
          if (serverStatus == "NEEDS CHANGE") serverStatus = "NEEDS_EDITING";
          queryParams["lastForwardStatus"] = serverStatus;
        }
      }

      final uri = Uri.parse("$baseUrl/transactions").replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> requests = [];
        Map<String, dynamic>? pagination;
        Map<String, dynamic>? summary;

        if (responseData is Map) {
          requests = responseData['data'] ?? [];
          pagination = responseData['pagination'];
          summary = responseData['summary'];
        } else if (responseData is List) {
          requests = responseData;
        }

        return {
          'success': true,
          'data': requests,
          'pagination': pagination,
          'summary': summary,
        };
      } else {
        return {
          'success': false,
          'error': AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode),
        };
      }
    } catch (e) {
      print("❌ Error fetching archive requests: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 🔹 جلب معلومات المستخدم
  static Future<Map<String, String?>> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userName = prefs.getString('userName') ??
          prefs.getString('username') ??
          'admin';

      final token = prefs.getString('token');
      final userGroup = prefs.getString('user_group') ?? 'user';

      return {
        'userName': userName,
        'token': token,
        'userGroup': userGroup,
      };
    } catch (e) {
      print("❌ Error getting user info: $e");
      return {
        'userName': 'admin',
        'token': null,
        'userGroup': 'user',
      };
    }
  }
}
