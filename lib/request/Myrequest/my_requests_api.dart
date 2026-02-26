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

  // 🔹 جلب الطلبات الخاصة بالمستخدم - صفحة واحدة مع دعم الفلترة من السيرفر
  Future<Map<String, dynamic>> fetchMyRequests({
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
        'query': 'outgoing',
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
      print("❌ Error fetching requests: $e");
      return {
        'success': false,
        'error': "Network error: $e",
      };
    }
  }

  // 🔹 جلب معلومات آخر مستقبل تم تحويل المعاملة إليه
  Future<Map<String, dynamic>?> fetchLastForwardData(String transactionId) async {
    try {
      if (userToken == null) return null;

      // جمع كل forwards من كل الصفحات
      List<dynamic> allForwards = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await http.get(
          Uri.parse("$baseUrl/transaction/$transactionId/forward?page=$page&perPage=100"),
          headers: {
            'Content-Type': 'application/json',
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

          allForwards.addAll(forwards);

          if (pagination != null && pagination['next'] != null) {
            page = pagination['next'];
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }

      // فلترة: فقط الـ forwards اللي أنا كنت فيها sender
      final myForwardsAsSender = allForwards.where((forward) {
        final sender = forward['sender'];
        String? senderName;
        if (sender is Map) {
          senderName = sender['name'];
        } else if (sender is String) {
          senderName = sender;
        }
        return senderName != null && senderName == userName;
      }).toList();

      if (myForwardsAsSender.isEmpty) return null;

      // ترتيب تنازلي بالـ id عشان نأخذ الأحدث
      myForwardsAsSender.sort((a, b) {
        final idA = (a['id'] ?? 0) is int ? (a['id'] ?? 0) : int.tryParse(a['id'].toString()) ?? 0;
        final idB = (b['id'] ?? 0) is int ? (b['id'] ?? 0) : int.tryParse(b['id'].toString()) ?? 0;
        return idB.compareTo(idA);
      });

      final latestForward = myForwardsAsSender.first;
      final receiver = latestForward['receiver'];
      String? receiverName;
      if (receiver is Map) {
        receiverName = receiver['name'];
      } else if (receiver is String) {
        receiverName = receiver;
      }

      if (receiverName != null) {
        return {
          'receiverName': receiverName,
          'forwardId': latestForward['id'].toString(),
        };
      }
    } catch (e) {
      print("⚠️ Error fetching last receiver: $e");
    }
    return null;
  }

  // 🔹 إلغاء تحويل
  Future<bool> cancelForward(String transactionId, String forwardId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/transaction/$transactionId/forward/$forwardId"),
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error canceling forward: $e");
      return false;
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

  // 🔹 جلب المستخدمين (paginated)
  Future<Map<String, dynamic>> fetchUsers({int page = 1, int perPage = 10}) async {
    if (userToken == null) return {'users': [], 'hasMore': false};

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users?page=$page&perPage=$perPage"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> pageUsers = [];

        if (data is Map) {
          pageUsers = data['data'] ?? data['users'] ?? [];
        } else if (data is List) {
          pageUsers = data;
        }

        bool hasMore = false;
        if (data is Map && data['pagination'] != null) {
          hasMore = data['pagination']['next'] != null;
        }

        return {
          'users': pageUsers,
          'hasMore': hasMore,
        };
      }
      return {'users': [], 'hasMore': false};
    } catch (e) {
      print("❌ Error in fetchUsers: $e");
      return {'users': [], 'hasMore': false};
    }
  }

  // Helper method to resolve name to ID
  Future<int?> resolveUserNameToId(String name) async {
    if (userToken == null) return null;
    int currentPage = 1;
    bool hasMore = true;
    try {
      while (hasMore) {
        final result = await fetchUsers(page: currentPage, perPage: 50);
        final users = result['users'] as List;
        final user = users.firstWhere((u) => u['name'] == name, orElse: () => null);
        if (user != null) {
          return user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
        }
        hasMore = result['hasMore'];
        currentPage++;
      }
    } catch (e) {
      print("❌ Error resolving user: $e");
    }
    return null;
  }

  // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
  Future<bool> forwardTransaction(String transactionId, String receiverName, {String? comment}) async {
    if (userToken == null) return false;

    try {
      final receiverId = await resolveUserNameToId(receiverName);

      if (receiverId == null) {
        print("❌ Could not resolve receiver for: $receiverName");
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          "receiverId": receiverId,
          "comment": comment ?? "Forwarded via Mobile App"
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