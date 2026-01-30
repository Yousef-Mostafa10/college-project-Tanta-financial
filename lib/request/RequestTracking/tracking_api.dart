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

  // 🔹 جلب معلومات التتبع
  Future<Map<String, dynamic>> fetchTransactionForwards(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': data['transaction'],
          'forwards': data['transaction']?['forwards'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': "Failed to load transaction data",
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