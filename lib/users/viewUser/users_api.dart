import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';

class UsersApiService {
  final String baseUrl = "http://192.168.1.3:3000";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> fetchUsers(int pageNumber, int pageSize) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users?pageNumber=$pageNumber&pageSize=$pageSize");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userName) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userName");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else if (response.statusCode == 404) {
      throw Exception('user_not_found');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }

  Future<void> changePassword(String userName, String newPassword) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('no_token_error');
    }

    final url = Uri.parse("$baseUrl/users/$userName");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"password": newPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] != "success") {
        throw Exception(data["message"] ?? 'failed_to_change_password');
      }
    } else if (response.statusCode == 403) {
      throw Exception('permission_error');
    } else if (response.statusCode == 404) {
      throw Exception('user_not_found');
    } else if (response.statusCode == 401) {
      throw Exception('unauthorized_error');
    } else {
      throw Exception('error_code: ${response.statusCode}');
    }
  }
}