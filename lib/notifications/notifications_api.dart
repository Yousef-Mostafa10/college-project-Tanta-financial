import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';

class NotificationsApiService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> fetchNotifications({int page = 1, int perPage = 20}) async {
    final token = await _getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.get(
      Uri.parse("$_baseUrl/notifications?page=$page&perPage=$perPage"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markAsSeen(int notificationId) async {
    final token = await _getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.patch(
      Uri.parse("$_baseUrl/notifications/$notificationId/seen"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"seen": true}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark notification as seen');
    }
  }
}
