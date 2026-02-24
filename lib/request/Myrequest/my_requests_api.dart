import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyRequestsApi {
  final String baseUrl;
  final String? userToken;
  final String? userName;

  MyRequestsApi({
    required this.baseUrl,
    required this.userToken,
    required this.userName,
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

      return allTypes.toSet().toList(); // إزالة المكررات
    } catch (e) {
      print("⚠️ Error fetching types: $e");
      return ['All Types'];
    }
  }

  // 🔹 جلب الطلبات الخاصة بالمستخدم - صفحة واحدة
  Future<Map<String, dynamic>> fetchMyRequests({int page = 1, int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/transactions?page=$page&perPage=$perPage&query=outgoing"),
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
      print("❌ Error fetching requests: $e");
      return {
        'success': false,
        'error': "Network error: $e",
      };
    }
  }

  // 🔹 حذف طلب
  Future<bool> deleteRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/transactions/$requestId"),
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData["status"] == "success";
      }
      return false;
    } catch (e) {
      print("❌ Error deleting request: $e");
      return false;
    }
  }

  // 🔹 جلب معلومات الforward الأخير الذي أرسلته (لمعرفة من استلم المعاملة)
  Future<Map<String, dynamic>?> getLastForwardSentByYou(String transactionId) async {
    try {
      if (userToken == null || userName == null) return null;

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward?page=1&perPage=10"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> forwards = [];

        if (data is Map) {
          forwards = data['data'] ?? [];
        } else if (data is List) {
          forwards = data;
        }

        if (forwards.isEmpty) return null;

        // البحث عن آخر توجيه قمنا به
        dynamic myForward;
        try {
          myForward = forwards.lastWhere(
            (f) => f['sender']?['name'] == userName,
            orElse: () => null,
          );
        } catch (e) {
          myForward = null;
        }

        if (myForward != null) {
          return {
            'id': myForward['id'],
            'receiverName': myForward['receiver']?['name'],
            'status': myForward['status'],
          };
        }
      }
      return null;
    } catch (e) {
      print("⚠️ Error fetching my forwards for request $transactionId: $e");
      return null;
    }
  }

  // 🔹 إلغاء الـ forward
  Future<bool> cancelForward(String transactionId, dynamic forwardId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || forwardId == null) return false;

      final response = await http.delete(
        Uri.parse("$baseUrl/transaction/$transactionId/forward/$forwardId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in cancelForward: $e");
      return false;
    }
  }

  // 🔹 جلب المستخدمين (paginated)
  Future<Map<String, dynamic>> fetchUsers({int page = 1, int perPage = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'users': [], 'hasMore': false};

      final response = await http.get(
        Uri.parse("$baseUrl/users?page=$page&perPage=$perPage"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> pageUsers = [];
        bool hasMore = false;

        if (data is Map) {
          pageUsers = data['data'] ?? data['users'] ?? [];
          final pagination = data['pagination'];
          if (pagination != null && pagination['next'] != null) {
            hasMore = true;
          }
        } else if (data is List) {
          pageUsers = data;
        }

        return {'users': pageUsers, 'hasMore': hasMore};
      }
      return {'users': [], 'hasMore': false};
    } catch (e) {
      print("❌ Error in fetchUsers: $e");
      return {'users': [], 'hasMore': false};
    }
  }

  // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
  Future<bool> forwardTransaction(String transactionId, int receiverId, {String? comment}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "receiverId": receiverId,
          "comment": comment ?? "Forwarded via My Requests"
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error in forwardTransaction: $e");
      return false;
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