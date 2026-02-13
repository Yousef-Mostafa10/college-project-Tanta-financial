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

  // جلب أنواع المعاملات
  Future<List<String>> fetchTypes() async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/transactions/types"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> typesList = [];
        if (data is List) {
          typesList = data;
        } else if (data is Map && data["transactionTypes"] != null) {
          typesList = data["transactionTypes"];
        }

        return typesList
            .where((item) => item["name"] != null)
            .map<String>((item) => item["name"] as String)
            .toList();
      } else {
        // Fallback: جلب الأنواع من المعاملات
        final transactions = await fetchAllRequests();
        final types = transactions
            .map((t) => t["typeName"]?.toString() ?? t["type"]?["name"] ?? "")
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>(); // ✅ تحويل إلى List<String>
        return types;
      }
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

  // ✅ جلب كل الطلبات
  Future<List<dynamic>> fetchAllRequests({
    String? priority,
    String? typeName,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    // API يعيد مصفوفة مباشرة - لا Pagination من السيرفر
    final queryParams = {
      if (priority != null && priority != 'All')
        "priority": priority.toLowerCase(),
      if (typeName != null && typeName != 'All Types')
        "typeName": typeName,
    };

    final uri = Uri.parse("$_baseUrl/transactions")
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> transactions = jsonDecode(response.body);

      // جلب آخر حالة لكل معاملة
      for (var transaction in transactions) {
        final lastStatus = await _getLastForwardStatus(transaction["id"].toString());
        transaction["lastForwardStatus"] = lastStatus ?? "waiting";

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

      return transactions;
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