import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ArchiveApi {
  final String baseUrl;
  final String? userToken;

  ArchiveApi({
    required this.baseUrl,
    required this.userToken,
  });

  // 🔹 جلب أنواع المعاملات مع Pagination
  Future<List<String>> fetchTypes() async {
    try {
      if (userToken == null) return ['All Types'];

      List<String> allTypes = ['All Types'];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await http.get(
          Uri.parse("$baseUrl/transactions/types?page=$page&perPage=10"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userToken',
          },
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          List<dynamic> typesList = [];
          Map<String, dynamic>? pagination;

          if (responseData is Map) {
            typesList = responseData['data'] ?? responseData['transactionTypes'] ?? [];
            pagination = responseData['pagination'];
          } else if (responseData is List) {
            typesList = responseData;
          }

          for (var item in typesList) {
            if (item["name"] != null) {
              allTypes.add(item["name"]);
            }
          }

          if (pagination != null && pagination['next'] != null) {
            page = pagination['next'];
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }

      return allTypes.toSet().toList();
    } catch (e) {
      print("⚠️ Error fetching types: $e");
      return ['All Types'];
    }
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
        'query': 'all',
      };

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
          'error': "Failed to load requests (Status: ${response.statusCode})",
        };
      }
    } catch (e) {
      print("❌ Error fetching archive requests: $e");
      return {
        'success': false,
        'error': "Network error: $e",
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

      return {
        'userName': userName,
        'token': token,
      };
    } catch (e) {
      print("❌ Error getting user info: $e");
      return {
        'userName': 'admin',
        'token': null,
      };
    }
  }
}
