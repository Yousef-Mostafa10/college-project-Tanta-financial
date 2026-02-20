import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

class InboxApi {
  final String baseUrl = AppConfig.baseUrl;

  // 🔹 جلب معلومات المستخدم المسجل
  Future<Map<String, String?>> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
      final token = prefs.getString('token');

      return {'userName': userName, 'token': token};
    } catch (e) {
      print("❌ Error getting user info: $e");
      return {'userName': 'admin', 'token': null};
    }
  }

  // ✅ NEW: جلب الـ User ID من الـ API
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedUserId = prefs.getString('userId');

    if (cachedUserId != null && cachedUserId.isNotEmpty) {
      print("✅ Using cached userId: $cachedUserId");
      return cachedUserId;
    }

    final token = prefs.getString('token');
    final username = prefs.getString('userName') ?? prefs.getString('username');

    if (token == null || username == null) {
      print("❌ No token or username found");
      return null;
    }

    try {
      // الـ API الجديد يستخدم /users لجلب كل المستخدمين ثم البحث عن المستخدم بالاسم
      final response = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> users = data is List ? data : (data["users"] ?? []);

        final user = users.firstWhere(
          (u) => u["name"] == username,
          orElse: () => null,
        );

        if (user != null) {
          final userId = user["id"]?.toString();
          if (userId != null && userId.isNotEmpty) {
            await prefs.setString('userId', userId);
            print("✅ Fetched and cached userId: $userId");
            return userId;
          }
        }
      } else {
        print("❌ Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching userId: $e");
    }

    return null;
  }

  // ✅ NEW: جلب آخر حالة قام بها المستخدم الحالي فقط (لحل المشكلة الأساسية)
  Future<String?> getMyLastForwardStatus(String transactionId, String myUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
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

        // 🔹 فلترة: جلب فقط الـ forwards التي قام بها المستخدم الحالي كـ sender
        final myForwards = forwards.where((forward) {
          // جرب كلا الحقلين (sender و forwardedBy) للتوافق
          final senderId = forward["sender"]?["id"]?.toString() ??
              forward["forwardedBy"]?["id"]?.toString();
          return senderId == myUserId;
        }).toList();

        if (myForwards.isNotEmpty) {
          // ترتيب حسب التاريخ (الأحدث أولاً)
          myForwards.sort((a, b) {
            final timeA = DateTime.parse(a["updatedAt"] ?? a["forwardedAt"] ?? a["createdAt"] ?? "2000-01-01");
            final timeB = DateTime.parse(b["updatedAt"] ?? b["forwardedAt"] ?? b["createdAt"] ?? "2000-01-01");
            return timeB.compareTo(timeA);
          });

          // إرجاع آخر حالة قمت بها
          return myForwards.first["status"];
        }
      }
      return null;
    } catch (e) {
      print("❌ Error getting my forward status: $e");
      return null;
    }
  }

  // 🔹 جلب أنواع المعاملات
  Future<List<String>> fetchTypes(String? token) async {
    try {
      if (token == null) return ['All Types'];

      final response = await http.get(
        Uri.parse("$baseUrl/transactions/types"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي (القديمة - محفوظة للتوافق)
  Future<String> getYourForwardStatusForRequest(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return 'unknown';

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

        dynamic yourForward;
        try {
          yourForward = forwards.lastWhere(
                (f) => f['receiver']?['name'] == userName,
            orElse: () => null,
          );
        } catch (e) {
          yourForward = null;
        }

        if (yourForward != null) {
          return yourForward['status'] ?? 'waiting';
        } else {
          return 'not-assigned';
        }
      }
      return 'unknown';
    } catch (e) {
      print(
          "⚠️ Error fetching forwards for request ${request['id']}: $e");
      return 'unknown';
    }
  }

  // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي (الجديدة - تحل المشكلة)
  Future<String> getYourForwardStatusForRequestUpdated(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return 'unknown';

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

        if (forwards.isEmpty) {
          return 'not-assigned';
        }

        // 🔹 Fix: Always look for the last time I was a RECEIVER.
        // This ensures that if I approved and forwarded, I still see "Approved" (my action),
        // not "Waiting" (the status of the forward I sent).
        final myReceipts = forwards.where((f) =>
          f['receiver']?['name'] == userName
        ).toList();

        if (myReceipts.isEmpty) {
          return 'not-assigned';
        }

        // Sort by ID to find the latest receipt
        myReceipts.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
        
        return myReceipts.last['status'] ?? 'waiting';
      }
      return 'unknown';
    } catch (e) {
      print("⚠️ Error fetching forwards for request ${request['id']}: $e");
      return 'unknown';
    }
  }

  // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك
  Future<String> getLastSenderNameForYou(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) {
        return request['creator']?['name'] ?? 'Unknown';
      }

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

        dynamic yourForward;
        try {
          yourForward = forwards.lastWhere(
                (f) => f['receiver']?['name'] == userName,
            orElse: () => null,
          );
        } catch (e) {
          yourForward = null;
        }

        if (yourForward != null) {
          return yourForward['sender']?['name'] ??
              (request['creator']?['name'] ?? 'Unknown');
        }
      }
      return request['creator']?['name'] ?? 'Unknown';
    } catch (e) {
      print(
          "⚠️ Error fetching last sender for request ${request['id']}: $e");
      return request['creator']?['name'] ?? 'Unknown';
    }
  }

  // 🔹 جلب معلومات الforward الأخير الذي أرسلناه
  Future<Map<String, dynamic>?> getLastForwardSentByYou(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return null;

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

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
      print(
          "⚠️ Error fetching my forwards for request ${request['id']}: $e");
      return null;
    }
  }

  // 🔹 دالة جديدة: التحقق مما إذا كان يمكن إعادة التوجيه (حسب منطق Angular)
  Future<bool> checkIfCanForward(
      String transactionId,
      String? token,
      String? userName,
      ) async {
    if (token == null || userName == null) return false;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data is List 
            ? data 
            : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

        if (forwards.isEmpty) {
          return true;
        }

        final myInteractions = forwards.where((f) =>
        f['sender']?['name'] == userName || f['receiver']?['name'] == userName
        ).toList();

        if (myInteractions.isEmpty) {
          return true;
        } else {
          myInteractions.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
          final lastInteraction = myInteractions.last;

          if (lastInteraction['sender']?['name'] == userName) {
            return false;
          } else {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("⚠️ Error checking if can forward for request $transactionId: $e");
      return false;
    }
  }

  // 🔹 جلب الطلبات المرسلة إليك فقط
  Future<List<dynamic>> fetchInboxRequests(
      String userName, String? token) async {
    if (token == null) return [];

    try {
      List<dynamic> allRequests = [];
      int currentPage = 1;
      int lastPage = 1;

      do {
        final Map<String, String> queryParams = {
          "pageNumber": currentPage.toString(),
          "pageSize": "10",
          "receiverName": userName,
        };

        final uri = Uri.parse("$baseUrl/transactions")
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

          if (pageRequests.isEmpty) break;
        } else {
          break;
        }
      } while (currentPage <= lastPage);

      return allRequests;
    } catch (e) {
      print("❌ Network error in fetchInboxRequests: $e");
      return [];
    }
  }

  // 🔹 تنفيذ الإجراءات (الموافقة، الرفض) - القديمة (محفوظة للتوافق)
  Future<bool> performAction(
      String transactionId,
      String action,
      String? token,
      String? userName,
      ) async {
    if (token == null || userName == null) return false;

    try {
      final forwardsResponse = await http.get(
        Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (forwardsResponse.statusCode != 200) return false;

      final forwardsData = json.decode(forwardsResponse.body);
      final List<dynamic> forwards =
          forwardsData['transaction']?['forwards'] ?? [];

      if (forwards.isEmpty) return false;

      dynamic yourForward;
      try {
        yourForward = forwards.lastWhere(
              (forward) => forward['receiver']?['name'] == userName,
          orElse: () => null,
        );
      } catch (e) {
        yourForward = null;
      }

      if (yourForward == null) return false;

      final String forwardId = yourForward['id'].toString();
      final Map<String, dynamic> body = {};

      switch (action) {
        case 'Approve':
          body['status'] = 'approved';
          break;
        case 'Reject':
          body['status'] = 'rejected';
          break;
        default:
          return false;
      }

      final response = await http.patch(
        Uri.parse(
            "$baseUrl/transaction/$transactionId/forward/$forwardId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in performAction: $e");
      return false;
    }
  }

  // 🔹 تنفيذ الإجراءات (الموافقة، الرفض، طلب التعديل) - الجديدة
  Future<bool> performActionUpdated(
      String transactionId,
      String action,
      String? token,
      String? userName, {
        String? comment,
      }) async {
    if (token == null || userName == null) return false;

    try {
      final forwardsResponse = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (forwardsResponse.statusCode != 200) return false;

      final data = json.decode(forwardsResponse.body);
      final List<dynamic> forwards = data is List 
          ? data 
          : (data['transaction']?['forwards'] ?? data['forwards'] ?? []);

      if (forwards.isEmpty) return false;

      dynamic yourForward;
      try {
        final sortedForwards = List<dynamic>.from(forwards);
        sortedForwards.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

        yourForward = sortedForwards.firstWhere(
              (forward) => forward['receiver']?['name'] == userName,
          orElse: () => null,
        );
      } catch (e) {
        yourForward = null;
      }

      if (yourForward == null) {
        print("❌ No forward found where user is receiver");
        return false;
      }

      final String forwardId = yourForward['id'].toString();
      final Map<String, dynamic> body = {};

      switch (action) {
        case 'Approve':
          body['status'] = 'APPROVED';
          break;
        case 'Reject':
          body['status'] = 'REJECTED';
          break;
        case 'Needs Change':
          body['status'] = 'NEEDS_EDITING';
          break;
        default:
          return false;
      }

      if (comment != null && comment.isNotEmpty) {
        body['comment'] = comment;
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/transaction/$transactionId/forward/$forwardId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in performActionUpdated: $e");
      return false;
    }
  }

  // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
  // ✅ الـ API الجديد يستخدم receiverId (رقم) بدلاً من receiverName (نص)
  Future<bool> forwardTransaction(
      String transactionId,
      String receiverName,
      String? token, {
      int? receiverId,
      String? comment,
      }) async {
    if (token == null) return false;

    try {
      // إذا لم يتم تمرير receiverId، حاول حله من الاسم
      int? resolvedReceiverId = receiverId;
      if (resolvedReceiverId == null) {
        final usersResponse = await http.get(
          Uri.parse("$baseUrl/users"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (usersResponse.statusCode == 200) {
          final usersData = jsonDecode(usersResponse.body);
          final List<dynamic> users = usersData is List ? usersData : (usersData["users"] ?? []);
          final user = users.firstWhere(
            (u) => u['name'] == receiverName,
            orElse: () => null,
          );
          if (user != null) {
            resolvedReceiverId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
          }
        }
      }

      if (resolvedReceiverId == null) {
        print("❌ Could not resolve receiverId for: $receiverName");
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/transaction/$transactionId/forward"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "receiverId": resolvedReceiverId,
          "comment": comment ?? "Forwarded via Mobile App"
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error in forwardTransaction: $e");
      return false;
    }
  }

  // 🔹 إلغاء الـ forward
  Future<bool> cancelForward(
      String transactionId,
      dynamic forwardId,
      String? token,
      ) async {
    if (token == null || forwardId == null) return false;

    try {
      final response = await http.delete(
        Uri.parse(
            "$baseUrl/transaction/$transactionId/forward/$forwardId"),
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

  // 🔹 جلب المستخدمين
  Future<List<dynamic>> fetchUsers(String? token) async {
    if (token == null) return [];

    List<dynamic> allUsers = [];
    int currentPage = 1;
    bool hasMorePages = true;

    try {
      while (hasMorePages) {
        final response = await http.get(
          Uri.parse(
              "$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> pageUsers = [];

          if (data["users"] != null) {
            pageUsers = data["users"];
          } else if (data["data"] != null) {
            pageUsers = data["data"];
          } else if (data is List) {
            pageUsers = data;
          }

          if (pageUsers.isNotEmpty) {
            allUsers.addAll(pageUsers);
            currentPage++;
            if (pageUsers.length < 100) hasMorePages = false;
          } else {
            hasMorePages = false;
          }
        } else {
          hasMorePages = false;
        }
      }

      final uniqueUsers = <dynamic>[];
      final seenIds = <dynamic>{};

      for (var user in allUsers) {
        final userId = user["id"] ?? user["_id"] ?? user["name"];
        if (!seenIds.contains(userId)) {
          seenIds.add(userId);
          uniqueUsers.add(user);
        }
      }

      return uniqueUsers;
    } catch (e) {
      print("❌ Error in fetchUsers: $e");
      return [];
    }
  }

  // 🔹 تعديل طلب موجود (لزر Edit Request)
  Future<bool> updateRequest(
      String requestId,
      Map<String, dynamic> updatedData,
      String? token,
      ) async {
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/transactions/$requestId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        print("✅ Request $requestId updated successfully");
        return true;
      } else {
        print(
            "⚠️ Failed to update request: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error updating request $requestId: $e");
      return false;
    }
  }
}