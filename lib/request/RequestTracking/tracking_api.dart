import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrackingApi {
  final String baseUrl;
  final String? userToken;

  TrackingApi({
    required this.baseUrl,
    required this.userToken,
  });

  // 🔹 جلب معلومات التتبع - صفحة واحدة
  Future<Map<String, dynamic>> fetchTransactionForwards(String transactionId, {int page = 1, int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward?page=$page&perPage=$perPage"),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> forwards = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          forwards = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          forwards = responseData;
        }

        return {
          'success': true,
          'transaction': null,
          'forwards': forwards,
          'pagination': pagination,
        };
      } else {
        return {
          'success': false,
          'error': "Failed to load transaction data (Status: ${response.statusCode})",
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': "Network error: $e",
      };
    }
  }

  // 🔹 جلب توكن المستخدم
  static Future<String?> getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print("❌ Error getting user token: $e");
      return null;
    }
  }
}