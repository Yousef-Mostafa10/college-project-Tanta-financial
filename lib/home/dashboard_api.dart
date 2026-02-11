// home/dashboard_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token may be expired");
    } else {
      throw Exception("Failed to load types: ${response.statusCode}");
    }
  }

  // جلب آخر حالة Forward
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

  // جلب كل الطلبات
  Future<List<dynamic>> fetchAllRequests({
    String? priority,
    String? typeName,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("No token found");

    List<dynamic> allRequests = [];
    int currentPage = 1;
    int lastPage = 1;

    do {
      final queryParams = {
        "pageNumber": currentPage.toString(),
        if (priority != null) "priority": priority.toLowerCase(),
        if (typeName != null) "typeName": typeName,
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
        final data = jsonDecode(response.body);
        final List<dynamic> pageRequests = data is List 
            ? data 
            : (data["transactions"] ?? []);
        allRequests.addAll(pageRequests);

        lastPage = data is Map ? (data["page"]?["last"] ?? 1) : 1;
        currentPage++;
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Token may be expired");
      } else {
        break;
      }
    } while (currentPage <= lastPage);

    // جلب آخر حالة forward لكل طلب
    for (var request in allRequests) {
      final lastStatus = await _getLastForwardStatus(request["id"].toString());
      request["lastForwardStatus"] = lastStatus;
    }

    return allRequests;
  }

  // حذف طلب
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
}