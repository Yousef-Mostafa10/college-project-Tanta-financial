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

  // 🔹 جلب أنواع المعاملات
  Future<List<String>> fetchTypes() async {
    try {
      if (userToken == null) return ['All Types'];

      final response = await http.get(
        Uri.parse("$baseUrl/transactions/types"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> typeNames = ['All Types'];
        
        List<dynamic> typesList = [];
        if (data is List) {
          typesList = data;
        } else if (data is Map && data["transactionTypes"] != null) {
          typesList = data["transactionTypes"];
        }

        for (var item in typesList) {
          if (item["name"] != null) {
            typeNames.add(item["name"]);
          }
        }
        return typeNames;
      }
      return ['All Types'];
    } catch (e) {
      print("⚠️ Error fetching types: $e");
      return ['All Types'];
    }
  }

  // 🔹 جلب حالة الـ Forward للمستخدم الحالي فقط
  Future<String?> getUserForwardStatus(String transactionId) async {
    if (userToken == null || userName == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data["transaction"]?["forwards"] ?? data["forwards"] ?? []);

        // البحث من الأحدث إلى الأقدم
        for (var i = forwards.length - 1; i >= 0; i--) {
          final forward = forwards[i];
          final sender = forward["sender"];
          final receiver = forward["receiver"];

          // إذا كان المستخدم هو sender
          if (sender != null && sender["name"] == userName) {
            return forward["status"];
          }
        }

        // إذا كان المستخدم هو receiver
        for (var i = forwards.length - 1; i >= 0; i--) {
          final forward = forwards[i];
          final receiver = forward["receiver"];

          if (receiver != null && receiver["name"] == userName) {
            return forward["status"];
          }
        }
      }
      return null;
    } catch (e) {
      print("❌ Error fetching forward status for transaction $transactionId: $e");
      return null;
    }
  }

  // 🔹 جلب كل الطلبات بدون فلترة أولية
  Future<List<dynamic>> fetchMyRequests() async {
    try {
      List<dynamic> combinedRequests = [];

      // دالة لجلب الطلبات حسب المعامل (معدلة لدعم قيمة مخصصة)
      Future<List<dynamic>> fetchByParam(String key, {String? value}) async {
        List<dynamic> allRequests = [];
        int currentPage = 1;
        int lastPage = 1;

        do {
          final Map<String, String> queryParams = {
            "pageNumber": currentPage.toString(),
            "pageSize": "10",
            key: value ?? userName!,
          };

          final uri = Uri.parse("$baseUrl/transactions")
              .replace(queryParameters: queryParams);

          final response = await http.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
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
          } else {
            break;
          }
        } while (currentPage <= lastPage);

        return allRequests;
      }

      // ✅ تحديث: استخدام creatorId و userId بدلاً من creatorName و senderName
      // الـ API الجديد يتطلب IDs بدلاً من Names
      // نحاول أولاً استخدام الـ IDs، وإذا لم تكن متاحة نستخدم fallback إلى Names
      
      // جلب userId من userName
      int? userId;
      if (userToken != null) {
        try {
          final usersResponse = await http.get(
            Uri.parse("$baseUrl/users"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
            },
          );
          if (usersResponse.statusCode == 200) {
            final usersData = jsonDecode(usersResponse.body);
            final List<dynamic> users = usersData is List ? usersData : (usersData["users"] ?? []);
            final user = users.firstWhere(
              (u) => u['name'] == userName,
              orElse: () => null,
            );
            if (user != null) {
              userId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
            }
          }
        } catch (e) {
          print("⚠️ Could not resolve userId, falling back to userName: $e");
        }
      }

      // جلب الطلبات باستخدام userId إن أمكن أو userName كـ fallback
      final creatorRequests = userId != null 
        ? await fetchByParam("creatorId", value: userId.toString())
        : await fetchByParam("creatorName");
      final senderRequests = userId != null
        ? await fetchByParam("userId", value: userId.toString())
        : await fetchByParam("senderName");

      // دمج بدون تكرار
      final ids = <dynamic>{};
      combinedRequests = [...creatorRequests, ...senderRequests]
          .where((req) => ids.add(req["id"]))
          .toList();

      // جلب حالة الـ Forward لكل طلب
      for (var request in combinedRequests) {
        final forwardStatus = await getUserForwardStatus(request["id"].toString());
        request["userForwardStatus"] = forwardStatus;
      }

      return combinedRequests;
    } catch (e) {
      print("❌ Error fetching requests: $e");
      throw Exception("Failed to load requests");
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