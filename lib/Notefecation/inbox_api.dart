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
      final userId = prefs.getInt('user_id')?.toString();

      return {'userName': userName, 'token': token, 'userId': userId};
    } catch (e) {
      print("❌ Error getting user info: $e");
      return {'userName': 'admin', 'token': null, 'userId': null};
    }
  }

  // ✅ جلب الـ User ID من الـ API
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedUserId = prefs.getString('userId');

    if (cachedUserId != null && cachedUserId.isNotEmpty) {
      return cachedUserId;
    }

    final token = prefs.getString('token');
    final username = prefs.getString('userName') ?? prefs.getString('username');

    if (token == null || username == null) return null;

    try {
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await http.get(
          Uri.parse("$baseUrl/users?page=$page&perPage=50"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List<dynamic> users = [];

          if (data is Map) {
            users = data['data'] ?? data['users'] ?? [];
          } else if (data is List) {
            users = data;
          }

          final user = users.firstWhere(
            (u) => u["name"] == username,
            orElse: () => null,
          );

          if (user != null) {
            final userId = user["id"]?.toString();
            if (userId != null && userId.isNotEmpty) {
              await prefs.setString('userId', userId);
              return userId;
            }
          }

          // Check pagination
          final pagination = data is Map ? data['pagination'] : null;
          if (pagination != null && pagination['next'] != null) {
            page = pagination['next'];
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }
    } catch (e) {
      print("❌ Error fetching userId: $e");
    }

    return null;
  }

  // ✅ جلب آخر حالة قام بها المستخدم الحالي
  Future<String?> getMyLastForwardStatus(String transactionId, String myUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> forwards = [];

        if (data is Map) {
          forwards = data['data'] ?? [];
        } else if (data is List) {
          forwards = data;
        }

        final myForwards = forwards.where((forward) {
          final senderId = forward["sender"]?["id"]?.toString() ??
              forward["forwardedBy"]?["id"]?.toString();
          return senderId == myUserId;
        }).toList();

        if (myForwards.isNotEmpty) {
          myForwards.sort((a, b) {
            final timeA = DateTime.parse(a["updatedAt"] ?? a["forwardedAt"] ?? "2000-01-01");
            final timeB = DateTime.parse(b["updatedAt"] ?? b["forwardedAt"] ?? "2000-01-01");
            return timeB.compareTo(timeA);
          });

          return myForwards.first["status"];
        }
      }
      return null;
    } catch (e) {
      print("❌ Error getting my forward status: $e");
      return null;
    }
  }

  // 🔹 جلب أنواع المعاملات (paginated)
  Future<List<String>> fetchTypes(String? token) async {
    try {
      if (token == null) return ['All Types'];

      final List<String> typeNames = ['All Types'];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await http.get(
          Uri.parse("$baseUrl/transactions/types?page=$page&perPage=10"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          List<dynamic> typesList = [];
          Map<String, dynamic>? pagination;

          if (data is Map) {
            typesList = data['data'] ?? data['transactionTypes'] ?? [];
            pagination = data['pagination'];
          } else if (data is List) {
            typesList = data;
          }

          for (var item in typesList) {
            if (item["name"] != null && !typeNames.contains(item["name"])) {
              typeNames.add(item["name"]);
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

      return typeNames;
    } catch (e) {
      print("⚠️ Error fetching types: $e");
      return ['All Types'];
    }
  }

  // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي
  Future<String> getYourForwardStatusForRequest(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return 'unknown';

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
      print("⚠️ Error fetching forwards for request ${request['id']}: $e");
      return 'unknown';
    }
  }

  // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي (محدثة)
  Future<String> getYourForwardStatusForRequestUpdated(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return 'unknown';

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

        if (forwards.isEmpty) {
          return 'not-assigned';
        }

        final myReceipts = forwards.where((f) =>
          f['receiver']?['name'] == userName
        ).toList();

        if (myReceipts.isEmpty) {
          return 'not-assigned';
        }

        myReceipts.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));

        final rawStatus = (myReceipts.last['status'] ?? 'waiting').toString().toLowerCase();
        // تحويل needs_editing إلى needs_change لتتوافق مع الـ UI
        if (rawStatus == 'needs_editing') return 'needs_change';
        return rawStatus;
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
        Uri.parse("$baseUrl/transaction/${request['id']}/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
      print("⚠️ Error fetching last sender for request ${request['id']}: $e");
      return request['creator']?['name'] ?? 'Unknown';
    }
  }

  // 🔹 جلب معلومات الforward الأخير الذي أرسلناه + الـ forwardId الخاص بنا كـ receiver
  Future<Map<String, dynamic>?> getLastForwardSentByYou(
      dynamic request, String? token, String? userName) async {
    try {
      if (token == null || userName == null) return null;

      final res = await http.get(
        Uri.parse("$baseUrl/transaction/${request['id']}/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
      print("⚠️ Error fetching my forwards for request ${request['id']}: $e");
      return null;
    }
  }

  // 🔹 جلب الـ forwardId الخاص بالمستخدم كـ receiver (لاستخدامه في response)
  Future<int?> getMyForwardIdAsReceiver(
      String transactionId, String? token, String? userName) async {
    if (token == null || userName == null) return null;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("🔍 getMyForwardIdAsReceiver - Status: ${res.statusCode}");
      print("🔍 getMyForwardIdAsReceiver - Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> forwards = [];

        if (data is Map) {
          forwards = data['data'] ?? [];
        } else if (data is List) {
          forwards = data;
        }

        print("🔍 Found ${forwards.length} forwards, looking for receiver: $userName");

        for (var f in forwards) {
          print("🔍 Forward id=${f['id']}, receiver=${f['receiver']?['name']}, receiverId=${f['receiver']?['id']}, status=${f['status']}");
        }

        final myReceipts = forwards.where((f) =>
          f['receiver']?['name'] == userName
        ).toList();

        if (myReceipts.isEmpty) {
          print("❌ No forwards found where $userName is receiver");
          return null;
        }

        // أحدث forward أنا receiver فيه
        myReceipts.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
        final forwardId = myReceipts.last['id'];
        print("✅ Found my forward ID: $forwardId");
        return forwardId;
      }
    } catch (e) {
      print("❌ Error getting my forward ID: $e");
    }
    return null;
  }

  // 🔹 التحقق مما إذا كان يمكن إعادة التوجيه
  Future<bool> checkIfCanForward(
      String transactionId,
      String? token,
      String? userName,
      ) async {
    if (token == null || userName == null) return false;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/transaction/$transactionId/forward?page=1&perPage=100"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  // ✅ جلب طلبات الوارد (paginated) - مع دعم الفلترة من السيرفر
  Future<Map<String, dynamic>> fetchInboxRequestsPage(
    String? token, {
    int page = 1,
    int perPage = 10,
    String? priority,
    String? typeName,
    String? search,
    String? status,
  }) async {
    if (token == null) {
      return {'data': [], 'pagination': null, 'summary': null};
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'perPage': perPage.toString(),
        'query': 'inbox',
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
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> requests = [];
        Map<String, dynamic>? pagination;
        Map<String, dynamic>? summary;

        if (data is Map) {
          requests = data['data'] ?? [];
          pagination = data['pagination'];
          summary = data['summary'] != null
              ? Map<String, dynamic>.from(data['summary'])
              : null;
        } else if (data is List) {
          requests = data;
        }

        return {
          'data': requests,
          'pagination': pagination,
          'summary': summary,
        };
      }

      return {'data': [], 'pagination': null, 'summary': null};
    } catch (e) {
      print("❌ Network error in fetchInboxRequestsPage: $e");
      return {'data': [], 'pagination': null, 'summary': null};
    }
  }

  // ✅ (محفوظة للتوافق) جلب كل الطلبات
  Future<List<dynamic>> fetchInboxRequests(
      String userName, String? token) async {
    if (token == null) return [];

    try {
      List<dynamic> allRequests = [];
      int currentPage = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await fetchInboxRequestsPage(token, page: currentPage, perPage: 10);
        final pageRequests = result['data'] as List<dynamic>;
        final pagination = result['pagination'] as Map<String, dynamic>?;

        allRequests.addAll(pageRequests);

        if (pagination != null && pagination['next'] != null) {
          currentPage = pagination['next'];
        } else {
          hasMore = false;
        }

        if (pageRequests.isEmpty) break;
      }

      return allRequests;
    } catch (e) {
      print("❌ Network error in fetchInboxRequests: $e");
      return [];
    }
  }

  // ✅ الرد على forward (موافقة/رفض/طلب تعديل) - POST /transaction/{id}/forward/{forwardId}/response
  Future<bool> respondToForward(
      String transactionId,
      int forwardId,
      String status,
      String? token, {
        String? comment,
      }) async {
    if (token == null) return false;

    try {
      final Map<String, dynamic> body = {
        'status': status,
      };

      if (comment != null && comment.isNotEmpty) {
        body['comment'] = comment;
      }

      final url = "$baseUrl/transaction/$transactionId/forward/$forwardId/response";
      final encodedBody = jsonEncode(body);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print("📤 respondToForward URL: $url");
      print("📤 respondToForward Body: $encodedBody");

      // أولاً نجرب POST
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: encodedBody,
      );

      print("📤 respondToForward POST Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      // لو رجع 403 FORWARD_ALREADY_SEEN نجرب PATCH
      if (response.statusCode == 403) {
        print("🔄 POST returned 403, trying PATCH...");
        final patchResponse = await http.patch(
          Uri.parse(url),
          headers: headers,
          body: encodedBody,
        );

        print("📤 respondToForward PATCH Response: ${patchResponse.statusCode} - ${patchResponse.body}");
        return patchResponse.statusCode >= 200 && patchResponse.statusCode < 300;
      }

      return false;
    } catch (e) {
      print("❌ Error in respondToForward: $e");
      return false;
    }
  }

  // ✅ تعديل الرد على forward - PATCH /transaction/{id}/forward/{forwardId}/response
  Future<bool> updateForwardResponse(
      String transactionId,
      int forwardId,
      String status,
      String? token, {
        String? comment,
      }) async {
    if (token == null) return false;

    try {
      final Map<String, dynamic> body = {
        'status': status,
      };

      if (comment != null && comment.isNotEmpty) {
        body['comment'] = comment;
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/transaction/$transactionId/forward/$forwardId/response"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print("📝 Update forward response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in updateForwardResponse: $e");
      return false;
    }
  }

  // ✅ تنفيذ الإجراءات (يجد الـ forwardId تلقائياً ثم يستخدم POST /response)
  Future<bool> performActionUpdated(
      String transactionId,
      String action,
      String? token,
      String? userName, {
        String? comment,
      }) async {
    if (token == null || userName == null) return false;

    print("🎯 performActionUpdated - transactionId: $transactionId, action: $action, userName: $userName");

    try {
      // جلب الـ forwardId الخاص بي كـ receiver
      final forwardId = await getMyForwardIdAsReceiver(transactionId, token, userName);

      if (forwardId == null) {
        print("❌ No forward found where user is receiver");
        return false;
      }

      // تحديد الحالة
      String status;
      switch (action) {
        case 'Approve':
          status = 'APPROVED';
          break;
        case 'Reject':
          status = 'REJECTED';
          break;
        case 'Needs Change':
          status = 'NEEDS_EDITING';
          break;
        default:
          print("❌ Unknown action: $action");
          return false;
      }

      print("📤 Calling respondToForward - transactionId: $transactionId, forwardId: $forwardId, status: $status, comment: $comment");

      return await respondToForward(
        transactionId,
        forwardId,
        status,
        token,
        comment: comment,
      );
    } catch (e) {
      print("❌ Error in performActionUpdated: $e");
      return false;
    }
  }

  // ✅ تعديل الرد (يجد الـ forwardId تلقائياً ثم يستخدم PATCH /response)
  Future<bool> editMyResponse(
      String transactionId,
      String action,
      String? token,
      String? userName, {
        String? comment,
      }) async {
    if (token == null || userName == null) return false;

    try {
      final forwardId = await getMyForwardIdAsReceiver(transactionId, token, userName);

      if (forwardId == null) {
        print("❌ No forward found where user is receiver for editing");
        return false;
      }

      String status;
      switch (action) {
        case 'Approve':
          status = 'APPROVED';
          break;
        case 'Reject':
          status = 'REJECTED';
          break;
        case 'Needs Change':
          status = 'NEEDS_EDITING';
          break;
        default:
          return false;
      }

      return await updateForwardResponse(
        transactionId,
        forwardId,
        status,
        token,
        comment: comment,
      );
    } catch (e) {
      print("❌ Error in editMyResponse: $e");
      return false;
    }
  }

  // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
  // POST /transaction/{id}/forward with body: {receiverId, comment}
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
        final users = await fetchUsers(token);
        final user = users.firstWhere(
          (u) => u['name'] == receiverName,
          orElse: () => null,
        );
        if (user != null) {
          resolvedReceiverId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
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

      // ✅ قبول أي كود 2xx كنجاح
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("❌ Error in cancelForward: $e");
      return false;
    }
  }

  // 🔹 جلب المستخدمين (paginated) - GET /users?page=X&perPage=10
  Future<List<dynamic>> fetchUsers(String? token) async {
    if (token == null) return [];

    List<dynamic> allUsers = [];
    int currentPage = 1;
    bool hasMore = true;

    try {
      while (hasMore) {
        final response = await http.get(
          Uri.parse("$baseUrl/users?page=$currentPage&perPage=50"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
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

          allUsers.addAll(pageUsers);

          // Check pagination
          final pagination = data is Map ? data['pagination'] : null;
          if (pagination != null && pagination['next'] != null) {
            currentPage = pagination['next'];
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }

      // إزالة المكررات
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
      print("❌ Error fetching users: $e");
      return [];
    }
  }

  // 🔹 جلب المستخدمين بصفحة محددة مع البحث
  Future<Map<String, dynamic>> fetchUsersPaginated(String? token, {int page = 1, int perPage = 10, String name = ''}) async {
    if (token == null) return {'users': [], 'next': null};

    try {
      String url = "$baseUrl/users?page=$page&perPage=$perPage";
      if (name.isNotEmpty) {
        url += "&name=${Uri.encodeComponent(name)}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> users = [];

        if (data is Map) {
          users = data['data'] ?? data['users'] ?? [];
        } else if (data is List) {
          users = data;
        }

        final pagination = data is Map ? data['pagination'] : null;
        int? next = pagination != null ? pagination['next'] : null;

        return {
          'users': users,
          'next': next,
        };
      } else {
        return {'users': [], 'next': null};
      }
    } catch (e) {
      print("❌ Error fetching users paginated: $e");
      return {'users': [], 'next': null};
    }
  }

  // 🔹 تعديل طلب موجود
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
        print("⚠️ Failed to update request: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error updating request $requestId: $e");
      return false;
    }
  }
}