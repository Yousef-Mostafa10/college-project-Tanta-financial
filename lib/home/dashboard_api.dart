import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../app_config.dart';

class DashboardAPI {
  final String _baseUrl = AppConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // جلب أنواع المعاملات مع Pagination
  Future<List<String>> fetchTypes() async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    try {
      List<String> allTypes = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await http.get(
          Uri.parse("$_baseUrl/transactions/types?page=$page&perPage=10"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
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

          allTypes.addAll(
            typesList
                .where((item) => item["name"] != null)
                .map<String>((item) => item["name"] as String),
          );

          if (pagination != null && pagination['next'] != null) {
            page = pagination['next'];
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }

      return allTypes.toSet().toList(); // إزالة المكررات
    } catch (e) {
      debugPrint("⚠️ Error fetching types: $e");
      return [];
    }
  }

  // ✅ جلب آخر حالة Forward
  Future<String?> _getLastForwardStatus(String transactionId) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forwards = data is List
            ? data
            : (data["transaction"]?["forwards"] ?? data["forwards"] ?? []);

        if (forwards.isNotEmpty) {
          forwards.sort((a, b) {
            final timeA = DateTime.parse(a["updatedAt"] ?? a["forwardedAt"]);
            final timeB = DateTime.parse(b["updatedAt"] ?? b["forwardedAt"]);
            return timeB.compareTo(timeA);
          });

          return forwards.first["status"];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ جلب الطلبات مع Pagination وفلترة من السيرفر
  Future<Map<String, dynamic>> fetchAllRequests({
    int page = 1,
    int perPage = 10,
    String? priority,
    String? typeName,
    String? search,
    String? status,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    final queryParams = {
      'page': page.toString(),
      'perPage': perPage.toString(),
      'query': 'all',
    };

    // فلترة الأولوية
    if (priority != null && priority != 'All') {
      queryParams["priority"] = priority.toUpperCase();
    }

    // فلترة النوع
    if (typeName != null && typeName != 'All Types') {
      queryParams["typeName"] = typeName;
    }

    // البحث بالـ Title أو الـ CreatorId
    if (search != null && search.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(search)) {
        queryParams["creatorId"] = search;
      } else {
        queryParams["title"] = search;
      }
    }

    // فلترة الحالة (Waiting, Approved, Rejected, Fulfilled, Needs Change)
    if (status != null && status != 'All') {
      if (status == 'Fulfilled') {
        queryParams["fulfilled"] = "true";
      } else {
        // تحويل الحالة للشكل المتوقع في السيرفر (بالحروف الكبيرة)
        String serverStatus = status.toUpperCase();
        if (serverStatus == "NEEDS CHANGE") {
          serverStatus = "NEEDS_EDITING";
        }
        queryParams["lastForwardStatus"] = serverStatus;
      }
    }

    final uri = Uri.parse("$_baseUrl/transactions")
        .replace(queryParameters: queryParams);

    debugPrint("📡 Fetching transactions: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<dynamic> transactions = [];
      Map<String, dynamic>? pagination;
      Map<String, dynamic>? summary;

      if (responseData is Map) {
        transactions = responseData['data'] ?? [];
        pagination = responseData['pagination'];
        summary = responseData['summary'];
      } else if (responseData is List) {
        transactions = responseData;
      }

      // استخدام الحالة الموجودة في بيانات المعاملة مباشرة (أسرع وأدق)
      for (var transaction in transactions) {
        String status = (transaction["lastForwardStatus"] ?? "waiting").toString().toLowerCase();

        // إذا كانت المعاملة مكتملة، تظهر حالة Fulfilled للأهمية
        if (transaction["fulfilled"] == true) {
          status = "fulfilled";
        }

        transaction["lastForwardStatus"] = status;

        // تحويل البيانات للشكل المطلوب للتوافق
        transaction["type"] = {
          "name": transaction["typeName"] ?? "N/A"
        };

        transaction["creator"] = {
          "name": transaction["creatorName"] ?? "Unknown"
        };

        // إضافة عدد المستندات
        transaction["documentsCount"] =
            transaction["documents"]?.length ?? 0;

        // إضافة تاريخ الإنشاء
        transaction["createdDate"] =
            transaction["createdAt"] ?? DateTime.now().toIso8601String();
      }

      return {
        'data': transactions,
        'pagination': pagination,
        'summary': summary,
      };
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token may be expired");
    } else {
      throw Exception("Failed to load requests: ${response.statusCode}");
    }
  }

  // ✅ حذف طلب
  Future<bool> deleteRequest(String requestId) async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    final response = await http.delete(
      Uri.parse("$_baseUrl/transactions/$requestId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData["status"] == "success";
    }

    return false;
  }

  // ✅ تعديل طلب (مكان للإضافة - اختياري)
  Future<bool> updateRequest(String requestId, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    // هذه دالة اختيارية - إذا كان هناك API للتعديل
    // final response = await http.put(
    //   Uri.parse("$_baseUrl/transactions/$requestId"),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode(data),
    // );

    // return response.statusCode == 200;

    // حالياً نوجه لصفحة التعديل
    return true;
  }
}