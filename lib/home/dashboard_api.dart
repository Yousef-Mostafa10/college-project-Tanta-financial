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

  /// استخراج رسالة خطأ قابلة للقراءة من أي شكل يرجعه الباك أند
  String _extractErrorMessage(dynamic raw, String fallback) {
    if (raw == null) return fallback;
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      // لو فيه "ar" أو "en" يرجع النص
      final ar = raw['ar'];
      final en = raw['en'];
      if (ar is String && ar.isNotEmpty) return ar;
      if (en is String && en.isNotEmpty) return en;
      // بعض الـ APIs بترجع {key: "ERROR_KEY"}
      final key = raw['key'];
      if (key is String && key.isNotEmpty) return key;
      // أول قيمة String موجودة
      for (final v in raw.values) {
        if (v is String && v.isNotEmpty) return v;
      }
    }
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).join(', ');
    }
    return fallback;
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
            transaction["documentsCount"] ?? (transaction["documents"] as List?)?.length ?? 0;

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

    // ✅ أي كود 2xx = نجاح
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      try {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey("status")) {
          return responseData["status"] == "success";
        }
        return true;
      } catch (_) {
        return true;
      }
    }

    // ❌ فشل - استخراج رسالة الخطأ من الباك أند
    String errorMsg = "فشل الحذف (كود: ${response.statusCode})";
    try {
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body);
        if (errorData is Map) {
          // جرب المفاتيح الشائعة وادعم nested objects
          final rawMsg = errorData["message"] ??
              errorData["error"] ??
              errorData["msg"];
          errorMsg = _extractErrorMessage(rawMsg, errorMsg);
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty && response.body.length < 300) {
        errorMsg = response.body;
      }
    }

    throw Exception(errorMsg);
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