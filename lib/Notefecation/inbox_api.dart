// // Notefecation/inbox_api.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class InboxApi {
//   final String baseUrl = "http://192.168.1.3:3000";
//
//   // 🔹 جلب معلومات المستخدم المسجل
//   Future<Map<String, String?>> getUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userName = prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
//       final token = prefs.getString('token');
//
//       return {'userName': userName, 'token': token};
//     } catch (e) {
//       print("❌ Error getting user info: $e");
//       return {'userName': 'admin', 'token': null};
//     }
//   }
//
//   // 🔹 جلب أنواع المعاملات
//   Future<List<String>> fetchTypes(String? token) async {
//     try {
//       if (token == null) return ['All Types'];
//
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/types"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<String> typeNames = ['All Types'];
//         final List<dynamic> transactionTypes = data["transactionTypes"] ?? [];
//         for (var item in transactionTypes) {
//           typeNames.add(item["name"]);
//         }
//         return typeNames;
//       }
//       return ['All Types'];
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//       return ['All Types'];
//     }
//   }
//
//   // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي
//   Future<String> getYourForwardStatusForRequest(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return 'unknown';
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['status'] ?? 'waiting';
//         } else {
//           return 'not-assigned';
//         }
//       }
//       return 'unknown';
//     } catch (e) {
//       print("⚠️ Error fetching forwards for request ${request['id']}: $e");
//       return 'unknown';
//     }
//   }
//
//   // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك
//   Future<String> getLastSenderNameForYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) {
//         return request['creator']?['name'] ?? 'Unknown';
//       }
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['sender']?['name'] ??
//               (request['creator']?['name'] ?? 'Unknown');
//         }
//       }
//       return request['creator']?['name'] ?? 'Unknown';
//     } catch (e) {
//       print("⚠️ Error fetching last sender for request ${request['id']}: $e");
//       return request['creator']?['name'] ?? 'Unknown';
//     }
//   }
//
//   // 🔹 جلب معلومات الforward الأخير الذي أرسلناه
//   Future<Map<String, dynamic>?> getLastForwardSentByYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return null;
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         dynamic myForward;
//         try {
//           myForward = forwards.lastWhere(
//                 (f) => f['sender']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           myForward = null;
//         }
//
//         if (myForward != null) {
//           return {
//             'id': myForward['id'],
//             'receiverName': myForward['receiver']?['name'],
//             'status': myForward['status'],
//           };
//         }
//       }
//       return null;
//     } catch (e) {
//       print("⚠️ Error fetching my forwards for request ${request['id']}: $e");
//       return null;
//     }
//   }
//
//   // 🔹 جلب الطلبات المرسلة إليك فقط
//   Future<List<dynamic>> fetchInboxRequests(
//       String userName, String? token) async {
//     if (token == null) return [];
//
//     try {
//       List<dynamic> allRequests = [];
//       int currentPage = 1;
//       int lastPage = 1;
//
//       do {
//         final Map<String, String> queryParams = {
//           "pageNumber": currentPage.toString(),
//           "pageSize": "10",
//           "receiverName": userName,
//         };
//
//         final uri = Uri.parse("$baseUrl/transactions")
//             .replace(queryParameters: queryParams);
//
//         final response = await http.get(
//           uri,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final List<dynamic> pageRequests = data["transactions"] ?? [];
//           allRequests.addAll(pageRequests);
//
//           lastPage = data["page"]?["last"] ?? 1;
//           currentPage++;
//
//           if (pageRequests.isEmpty) break;
//         } else {
//           break;
//         }
//       } while (currentPage <= lastPage);
//
//       return allRequests;
//     } catch (e) {
//       print("❌ Network error in fetchInboxRequests: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تنفيذ الإجراءات (الموافقة، الرفض)
//   Future<bool> performAction(
//       String transactionId,
//       String action,
//       String? token,
//       String? userName,
//       ) async {
//     if (token == null || userName == null) return false;
//
//     try {
//       // جلب الـ forwards أولاً
//       final forwardsResponse = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (forwardsResponse.statusCode != 200) return false;
//
//       final forwardsData = json.decode(forwardsResponse.body);
//       final List<dynamic> forwards = forwardsData['transaction']?['forwards'] ?? [];
//
//       if (forwards.isEmpty) return false;
//
//       // البحث عن الـ forward الخاص بالمستخدم
//       dynamic yourForward;
//       try {
//         yourForward = forwards.lastWhere(
//               (forward) => forward['receiver']?['name'] == userName,
//           orElse: () => null,
//         );
//       } catch (e) {
//         yourForward = null;
//       }
//
//       if (yourForward == null) return false;
//
//       final String forwardId = yourForward['id'].toString();
//       final Map<String, dynamic> body = {};
//
//       switch (action) {
//         case 'Approve':
//           body['status'] = 'approved';
//           break;
//         case 'Reject':
//           body['status'] = 'rejected';
//           break;
//         default:
//           return false;
//       }
//
//       final response = await http.patch(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(body),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in performAction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
//   Future<bool> forwardTransaction(
//       String transactionId,
//       String receiverName,
//       String? token,
//       ) async {
//     if (token == null) return false;
//
//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({"receiverName": receiverName}),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in forwardTransaction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إلغاء الـ forward
//   Future<bool> cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       String? token,
//       ) async {
//     if (token == null || forwardId == null) return false;
//
//     try {
//       final response = await http.delete(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in cancelForward: $e");
//       return false;
//     }
//   }
//
//   // 🔹 جلب المستخدمين
//   Future<List<dynamic>> fetchUsers(String? token) async {
//     if (token == null) return [];
//
//     List<dynamic> allUsers = [];
//     int currentPage = 1;
//     bool hasMorePages = true;
//
//     try {
//       while (hasMorePages) {
//         final response = await http.get(
//           Uri.parse("$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           List<dynamic> pageUsers = [];
//
//           if (data["users"] != null) {
//             pageUsers = data["users"];
//           } else if (data["data"] != null) {
//             pageUsers = data["data"];
//           } else if (data is List) {
//             pageUsers = data;
//           }
//
//           if (pageUsers.isNotEmpty) {
//             allUsers.addAll(pageUsers);
//             currentPage++;
//             if (pageUsers.length < 100) hasMorePages = false;
//           } else {
//             hasMorePages = false;
//           }
//         } else {
//           hasMorePages = false;
//         }
//       }
//
//       // إزالة التكرارات
//       final uniqueUsers = <dynamic>[];
//       final seenIds = <dynamic>{};
//
//       for (var user in allUsers) {
//         final userId = user["id"] ?? user["_id"] ?? user["name"];
//         if (!seenIds.contains(userId)) {
//           seenIds.add(userId);
//           uniqueUsers.add(user);
//         }
//       }
//
//       return uniqueUsers;
//     } catch (e) {
//       print("❌ Error in fetchUsers: $e");
//       return [];
//     }
//   }
// }

// // Notefecation/inbox_api.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class InboxApi {
//   final String baseUrl = "http://192.168.1.3:3000";
//   Duration requestTimeout = const Duration(seconds: 15);
//
//   // 🔹 جلب معلومات المستخدم المسجل
//   Future<Map<String, String?>> getUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userName = prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
//       final token = prefs.getString('token');
//
//       print('🔑 getUserInfo - User: $userName, Token: ${token != null ? "Exists (${token.length} chars)" : "NULL"}');
//
//       return {'userName': userName, 'token': token};
//     } catch (e) {
//       print("❌ Error getting user info: $e");
//       return {'userName': 'admin', 'token': null};
//     }
//   }
//
//   // 🔹 جلب أنواع المعاملات
//   Future<List<String>> fetchTypes(String? token) async {
//     try {
//       if (token == null) return ['All Types'];
//
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/types"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       print('📡 fetchTypes - Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<String> typeNames = ['All Types'];
//         final List<dynamic> transactionTypes = data["transactionTypes"] ?? [];
//
//         for (var item in transactionTypes) {
//           typeNames.add(item["name"]);
//         }
//
//         print('✅ fetchTypes - Found ${typeNames.length - 1} types');
//         return typeNames;
//       }
//
//       return ['All Types'];
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//       return ['All Types'];
//     }
//   }
//
//   // 🔹 دالة مساعدة للبحث الآمن عن forward
//   dynamic _findUserForward(List<dynamic> forwards, String userName) {
//     if (forwards.isEmpty) return null;
//
//     // البحث من الأحدث للأقدم
//     for (var i = forwards.length - 1; i >= 0; i--) {
//       final forward = forwards[i];
//       final receiverName = forward['receiver']?['name']?.toString();
//       if (receiverName == userName) {
//         return forward;
//       }
//     }
//     return null;
//   }
//
//   // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي
//   Future<String> getYourForwardStatusForRequest(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return 'unknown';
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         final yourForward = _findUserForward(forwards, userName);
//
//         if (yourForward != null) {
//           return yourForward['status']?.toString() ?? 'waiting';
//         } else {
//           return 'not-assigned';
//         }
//       }
//       return 'unknown';
//     } catch (e) {
//       print("⚠️ Error fetching forwards for request ${request['id']}: $e");
//       return 'unknown';
//     }
//   }
//
//   // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك
//   Future<String> getLastSenderNameForYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) {
//         return request['creator']?['name'] ?? 'Unknown';
//       }
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         final yourForward = _findUserForward(forwards, userName);
//
//         if (yourForward != null) {
//           return yourForward['sender']?['name'] ??
//               (request['creator']?['name'] ?? 'Unknown');
//         }
//       }
//       return request['creator']?['name'] ?? 'Unknown';
//     } catch (e) {
//       print("⚠️ Error fetching last sender for request ${request['id']}: $e");
//       return request['creator']?['name'] ?? 'Unknown';
//     }
//   }
//
//   // 🔹 جلب معلومات الforward الأخير الذي أرسلناه
//   Future<Map<String, dynamic>?> getLastForwardSentByYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return null;
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         // البحث عن forward أرسلناه (نحن المرسل)
//         for (var i = forwards.length - 1; i >= 0; i--) {
//           final forward = forwards[i];
//           final senderName = forward['sender']?['name']?.toString();
//           if (senderName == userName) {
//             return {
//               'id': forward['id']?.toString(),
//               'receiverName': forward['receiver']?['name']?.toString(),
//               'status': forward['status']?.toString(),
//             };
//           }
//         }
//       }
//       return null;
//     } catch (e) {
//       print("⚠️ Error fetching my forwards for request ${request['id']}: $e");
//       return null;
//     }
//   }
//
//   // 🔹 جلب الطلبات المرسلة إليك فقط
//   Future<List<dynamic>> fetchInboxRequests(
//       String userName, String? token) async {
//     if (token == null) return [];
//
//     try {
//       List<dynamic> allRequests = [];
//       int currentPage = 1;
//       int lastPage = 1;
//       bool hasMorePages = true;
//
//       print('📡 fetchInboxRequests - Starting for user: $userName');
//
//       while (hasMorePages && currentPage <= 10) { // حد أقصى 10 صفحات
//         final Map<String, String> queryParams = {
//           "pageNumber": currentPage.toString(),
//           "pageSize": "20",
//         };
//
//         final uri = Uri.parse("$baseUrl/transactions")
//             .replace(queryParameters: queryParams);
//
//         print('📄 Fetching page $currentPage...');
//
//         final response = await http.get(
//           uri,
//           headers: _getHeaders(token),
//         ).timeout(requestTimeout);
//
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final List<dynamic> pageRequests = data["transactions"] ?? [];
//
//           print('📊 Page $currentPage: ${pageRequests.length} requests');
//
//           // فلترة الطلبات التي مرت على المستخدم الحالي
//           final filteredRequests = await _filterRequestsForUser(pageRequests, userName, token);
//           allRequests.addAll(filteredRequests);
//
//           lastPage = data["page"]?["last"] ?? 1;
//           currentPage++;
//
//           if (pageRequests.isEmpty || currentPage > lastPage) {
//             hasMorePages = false;
//           }
//         } else {
//           print('❌ Failed to fetch page $currentPage: ${response.statusCode}');
//           hasMorePages = false;
//         }
//       }
//
//       print('✅ fetchInboxRequests - Total: ${allRequests.length} requests');
//       return allRequests;
//     } catch (e) {
//       print("❌ Network error in fetchInboxRequests: $e");
//       return [];
//     }
//   }
//
//   // 🔹 دالة مساعدة لفلترة الطلبات للمستخدم الحالي
//   Future<List<dynamic>> _filterRequestsForUser(
//       List<dynamic> requests, String userName, String token) async {
//     final filtered = <dynamic>[];
//
//     for (var request in requests) {
//       try {
//         // جلب forwards للطلب
//         final res = await http.get(
//           Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//           headers: _getHeaders(token),
//         ).timeout(Duration(seconds: 5));
//
//         if (res.statusCode == 200) {
//           final data = jsonDecode(res.body);
//           final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//           // تحقق إذا كان المستخدم الحالي في سلسلة الـ forwards
//           final userInForwards = forwards.any((f) =>
//           f['receiver']?['name']?.toString() == userName ||
//               f['sender']?['name']?.toString() == userName);
//
//           // تحقق إذا كان هو المنشئ
//           final isCreator = request['creator']?['name']?.toString() == userName;
//
//           if (userInForwards || isCreator) {
//             filtered.add(request);
//           }
//         }
//       } catch (e) {
//         // في حالة الخطأ، أضف الطلب مع ملاحظة
//         filtered.add(request);
//       }
//     }
//
//     return filtered;
//   }
//
//   // 🔹 تنفيذ الإجراءات (الموافقة، الرفض)
//   Future<bool> performAction(
//       String transactionId,
//       String action,
//       String? token,
//       String? userName,
//       ) async {
//     if (token == null || userName == null) {
//       print('❌ performAction: Missing token or userName');
//       return false;
//     }
//
//     try {
//       print('🔧 performAction - $action on transaction $transactionId');
//
//       // جلب الـ forwards أولاً
//       final forwardsResponse = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       if (forwardsResponse.statusCode != 200) {
//         print('❌ Failed to get forwards: ${forwardsResponse.statusCode}');
//         return false;
//       }
//
//       final forwardsData = json.decode(forwardsResponse.body);
//       final List<dynamic> forwards = forwardsData['transaction']?['forwards'] ?? [];
//
//       if (forwards.isEmpty) {
//         print('❌ No forwards found for transaction $transactionId');
//         return false;
//       }
//
//       // البحث عن الـ forward الخاص بالمستخدم
//       final yourForward = _findUserForward(forwards, userName);
//
//       if (yourForward == null) {
//         print('❌ No forward found for user $userName');
//         return false;
//       }
//
//       final String forwardId = yourForward['id'].toString();
//       final Map<String, dynamic> body = {};
//
//       switch (action.toLowerCase()) {
//         case 'approve':
//           body['status'] = 'approved';
//           break;
//         case 'reject':
//           body['status'] = 'rejected';
//           break;
//         default:
//           print('❌ Unknown action: $action');
//           return false;
//       }
//
//       final response = await http.patch(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: _getHeaders(token),
//         body: json.encode(body),
//       ).timeout(requestTimeout);
//
//       print('📡 performAction - Response: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         print('✅ $action successful for transaction $transactionId');
//         return true;
//       } else {
//         print('❌ $action failed: ${response.statusCode} - ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error in performAction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
//   Future<bool> forwardTransaction(
//       String transactionId,
//       String receiverName,
//       String? token,
//       ) async {
//     if (token == null) {
//       print('❌ forwardTransaction: Missing token');
//       return false;
//     }
//
//     try {
//       print('📤 forwardTransaction - $transactionId to $receiverName');
//
//       final response = await http.post(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: _getHeaders(token),
//         body: json.encode({"receiverName": receiverName}),
//       ).timeout(requestTimeout);
//
//       print('📡 forwardTransaction - Response: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         print('✅ Forward successful');
//         return true;
//       } else {
//         print('❌ Forward failed: ${response.statusCode} - ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error in forwardTransaction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إلغاء الـ forward
//   Future<bool> cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       String? token,
//       ) async {
//     if (token == null || forwardId == null) {
//       print('❌ cancelForward: Missing token or forwardId');
//       return false;
//     }
//
//     try {
//       print('🗑️ cancelForward - $forwardId from transaction $transactionId');
//
//       final response = await http.delete(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: _getHeaders(token),
//       ).timeout(requestTimeout);
//
//       print('📡 cancelForward - Response: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         print('✅ Cancel forward successful');
//         return true;
//       } else {
//         print('❌ Cancel forward failed: ${response.statusCode} - ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error in cancelForward: $e");
//       return false;
//     }
//   }
//
//   // 🔹 جلب المستخدمين
//   Future<List<dynamic>> fetchUsers(String? token) async {
//     if (token == null) return [];
//
//     List<dynamic> allUsers = [];
//     int currentPage = 1;
//     bool hasMorePages = true;
//
//     try {
//       while (hasMorePages) {
//         final response = await http.get(
//           Uri.parse("$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
//           headers: _getHeaders(token),
//         ).timeout(requestTimeout);
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           List<dynamic> pageUsers = [];
//
//           if (data["users"] != null) {
//             pageUsers = data["users"];
//           } else if (data["data"] != null) {
//             pageUsers = data["data"];
//           } else if (data is List) {
//             pageUsers = data;
//           }
//
//           if (pageUsers.isNotEmpty) {
//             allUsers.addAll(pageUsers);
//             currentPage++;
//             if (pageUsers.length < 100) hasMorePages = false;
//           } else {
//             hasMorePages = false;
//           }
//         } else {
//           print('❌ Failed to fetch users page $currentPage: ${response.statusCode}');
//           hasMorePages = false;
//         }
//       }
//
//       // إزالة التكرارات
//       final uniqueUsers = <dynamic>[];
//       final seenIds = <dynamic>{};
//
//       for (var user in allUsers) {
//         final userId = user["id"] ?? user["_id"] ?? user["name"];
//         if (!seenIds.contains(userId)) {
//           seenIds.add(userId);
//           uniqueUsers.add(user);
//         }
//       }
//
//       print('✅ fetchUsers - Found ${uniqueUsers.length} unique users');
//       return uniqueUsers;
//     } catch (e) {
//       print("❌ Error in fetchUsers: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تعديل طلب موجود (لزر Edit Request)
//   Future<bool> updateRequest(
//       String requestId,
//       Map<String, dynamic> updatedData,
//       String? token
//       ) async {
//     if (token == null) {
//       print('❌ updateRequest: Missing token');
//       return false;
//     }
//
//     try {
//       print('✏️ updateRequest - Updating $requestId');
//
//       final response = await http.put(
//         Uri.parse("$baseUrl/transactions/$requestId"),
//         headers: _getHeaders(token),
//         body: json.encode(updatedData),
//       ).timeout(requestTimeout);
//
//       print('📡 updateRequest - Response: ${response.statusCode}');
//
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         print("✅ Request $requestId updated successfully");
//         return true;
//       } else {
//         print("⚠️ Failed to update request: ${response.statusCode} - ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error updating request $requestId: $e");
//       return false;
//     }
//   }
//
//   // 🔹 دالة مساعدة لإنشاء headers
//   Map<String, String> _getHeaders(String? token) {
//     final headers = {
//       'Content-Type': 'application/json',
//     };
//
//     if (token != null) {
//       headers['Authorization'] = 'Bearer $token';
//     }
//
//     return headers;
//   }
// }
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class InboxApi {
//   final String baseUrl = "http://192.168.1.3:3000";
//
//   // 🔹 جلب معلومات المستخدم المسجل
//   Future<Map<String, String?>> getUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userName =
//           prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
//       final token = prefs.getString('token');
//
//       return {'userName': userName, 'token': token};
//     } catch (e) {
//       print("❌ Error getting user info: $e");
//       return {'userName': 'admin', 'token': null};
//     }
//   }
//
//   // 🔹 جلب أنواع المعاملات
//   Future<List<String>> fetchTypes(String? token) async {
//     try {
//       if (token == null) return ['All Types'];
//
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/types"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<String> typeNames = ['All Types'];
//         final List<dynamic> transactionTypes =
//             data["transactionTypes"] ?? [];
//         for (var item in transactionTypes) {
//           typeNames.add(item["name"]);
//         }
//         return typeNames;
//       }
//       return ['All Types'];
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//       return ['All Types'];
//     }
//   }
//
//   // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي
//   Future<String> getYourForwardStatusForRequest(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return 'unknown';
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['status'] ?? 'waiting';
//         } else {
//           return 'not-assigned';
//         }
//       }
//       return 'unknown';
//     } catch (e) {
//       print(
//           "⚠️ Error fetching forwards for request ${request['id']}: $e");
//       return 'unknown';
//     }
//   }
//
//   // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك
//   Future<String> getLastSenderNameForYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) {
//         return request['creator']?['name'] ?? 'Unknown';
//       }
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['sender']?['name'] ??
//               (request['creator']?['name'] ?? 'Unknown');
//         }
//       }
//       return request['creator']?['name'] ?? 'Unknown';
//     } catch (e) {
//       print(
//           "⚠️ Error fetching last sender for request ${request['id']}: $e");
//       return request['creator']?['name'] ?? 'Unknown';
//     }
//   }
//
//   // 🔹 جلب معلومات الforward الأخير الذي أرسلناه
//   Future<Map<String, dynamic>?> getLastForwardSentByYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return null;
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic myForward;
//         try {
//           myForward = forwards.lastWhere(
//                 (f) => f['sender']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           myForward = null;
//         }
//
//         if (myForward != null) {
//           return {
//             'id': myForward['id'],
//             'receiverName': myForward['receiver']?['name'],
//             'status': myForward['status'],
//           };
//         }
//       }
//       return null;
//     } catch (e) {
//       print(
//           "⚠️ Error fetching my forwards for request ${request['id']}: $e");
//       return null;
//     }
//   }
//
//   // 🔹 جلب الطلبات المرسلة إليك فقط
//   Future<List<dynamic>> fetchInboxRequests(
//       String userName, String? token) async {
//     if (token == null) return [];
//
//     try {
//       List<dynamic> allRequests = [];
//       int currentPage = 1;
//       int lastPage = 1;
//
//       do {
//         final Map<String, String> queryParams = {
//           "pageNumber": currentPage.toString(),
//           "pageSize": "10",
//           "receiverName": userName,
//         };
//
//         final uri = Uri.parse("$baseUrl/transactions")
//             .replace(queryParameters: queryParams);
//
//         final response = await http.get(
//           uri,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final List<dynamic> pageRequests =
//               data["transactions"] ?? [];
//           allRequests.addAll(pageRequests);
//
//           lastPage = data["page"]?["last"] ?? 1;
//           currentPage++;
//
//           if (pageRequests.isEmpty) break;
//         } else {
//           break;
//         }
//       } while (currentPage <= lastPage);
//
//       return allRequests;
//     } catch (e) {
//       print("❌ Network error in fetchInboxRequests: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تنفيذ الإجراءات (الموافقة، الرفض)
//   Future<bool> performAction(
//       String transactionId,
//       String action,
//       String? token,
//       String? userName,
//       ) async {
//     if (token == null || userName == null) return false;
//
//     try {
//       // جلب الـ forwards أولاً
//       final forwardsResponse = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (forwardsResponse.statusCode != 200) return false;
//
//       final forwardsData = json.decode(forwardsResponse.body);
//       final List<dynamic> forwards =
//           forwardsData['transaction']?['forwards'] ?? [];
//
//       if (forwards.isEmpty) return false;
//
//       // البحث عن الـ forward الخاص بالمستخدم
//       dynamic yourForward;
//       try {
//         yourForward = forwards.lastWhere(
//               (forward) => forward['receiver']?['name'] == userName,
//           orElse: () => null,
//         );
//       } catch (e) {
//         yourForward = null;
//       }
//
//       if (yourForward == null) return false;
//
//       final String forwardId = yourForward['id'].toString();
//       final Map<String, dynamic> body = {};
//
//       switch (action) {
//         case 'Approve':
//           body['status'] = 'approved';
//           break;
//         case 'Reject':
//           body['status'] = 'rejected';
//           break;
//         default:
//           return false;
//       }
//
//       final response = await http.patch(
//         Uri.parse(
//             "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(body),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in performAction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
//   Future<bool> forwardTransaction(
//       String transactionId,
//       String receiverName,
//       String? token,
//       ) async {
//     if (token == null) return false;
//
//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({"receiverName": receiverName}),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in forwardTransaction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إلغاء الـ forward
//   Future<bool> cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       String? token,
//       ) async {
//     if (token == null || forwardId == null) return false;
//
//     try {
//       final response = await http.delete(
//         Uri.parse(
//             "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in cancelForward: $e");
//       return false;
//     }
//   }
//
//   // 🔹 جلب المستخدمين
//   Future<List<dynamic>> fetchUsers(String? token) async {
//     if (token == null) return [];
//
//     List<dynamic> allUsers = [];
//     int currentPage = 1;
//     bool hasMorePages = true;
//
//     try {
//       while (hasMorePages) {
//         final response = await http.get(
//           Uri.parse(
//               "$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           List<dynamic> pageUsers = [];
//
//           if (data["users"] != null) {
//             pageUsers = data["users"];
//           } else if (data["data"] != null) {
//             pageUsers = data["data"];
//           } else if (data is List) {
//             pageUsers = data;
//           }
//
//           if (pageUsers.isNotEmpty) {
//             allUsers.addAll(pageUsers);
//             currentPage++;
//             if (pageUsers.length < 100) hasMorePages = false;
//           } else {
//             hasMorePages = false;
//           }
//         } else {
//           hasMorePages = false;
//         }
//       }
//
//       // إزالة التكرارات
//       final uniqueUsers = <dynamic>[];
//       final seenIds = <dynamic>{};
//
//       for (var user in allUsers) {
//         final userId = user["id"] ?? user["_id"] ?? user["name"];
//         if (!seenIds.contains(userId)) {
//           seenIds.add(userId);
//           uniqueUsers.add(user);
//         }
//       }
//
//       return uniqueUsers;
//     } catch (e) {
//       print("❌ Error in fetchUsers: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تعديل طلب موجود (لزر Edit Request)
//   Future<bool> updateRequest(
//       String requestId,
//       Map<String, dynamic> updatedData,
//       String? token,
//       ) async {
//     if (token == null) return false;
//
//     try {
//       final response = await http.put(
//         Uri.parse("$baseUrl/transactions/$requestId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(updatedData),
//       );
//
//       if (response.statusCode == 200 ||
//           response.statusCode == 204) {
//         print("✅ Request $requestId updated successfully");
//         return true;
//       } else {
//         print(
//             "⚠️ Failed to update request: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error updating request $requestId: $e");
//       return false;
//     }
//   }
// }
// ////////////////////////2222222222
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class InboxApi {
//   final String baseUrl = "http://192.168.1.3:3000";
//
//   // 🔹 جلب معلومات المستخدم المسجل
//   Future<Map<String, String?>> getUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userName =
//           prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
//       final token = prefs.getString('token');
//
//       return {'userName': userName, 'token': token};
//     } catch (e) {
//       print("❌ Error getting user info: $e");
//       return {'userName': 'admin', 'token': null};
//     }
//   }
//
//   // 🔹 جلب أنواع المعاملات
//   Future<List<String>> fetchTypes(String? token) async {
//     try {
//       if (token == null) return ['All Types'];
//
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/types"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<String> typeNames = ['All Types'];
//         final List<dynamic> transactionTypes =
//             data["transactionTypes"] ?? [];
//         for (var item in transactionTypes) {
//           typeNames.add(item["name"]);
//         }
//         return typeNames;
//       }
//       return ['All Types'];
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//       return ['All Types'];
//     }
//   }
//
//   // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي
//   Future<String> getYourForwardStatusForRequest(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return 'unknown';
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['status'] ?? 'waiting';
//         } else {
//           return 'not-assigned';
//         }
//       }
//       return 'unknown';
//     } catch (e) {
//       print(
//           "⚠️ Error fetching forwards for request ${request['id']}: $e");
//       return 'unknown';
//     }
//   }
//
//   // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك
//   Future<String> getLastSenderNameForYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) {
//         return request['creator']?['name'] ?? 'Unknown';
//       }
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['sender']?['name'] ??
//               (request['creator']?['name'] ?? 'Unknown');
//         }
//       }
//       return request['creator']?['name'] ?? 'Unknown';
//     } catch (e) {
//       print(
//           "⚠️ Error fetching last sender for request ${request['id']}: $e");
//       return request['creator']?['name'] ?? 'Unknown';
//     }
//   }
//
//   // 🔹 جلب معلومات الforward الأخير الذي أرسلناه
//   Future<Map<String, dynamic>?> getLastForwardSentByYou(
//       dynamic request, String? token, String? userName) async {
//     try {
//       if (token == null || userName == null) return null;
//
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards =
//             data['transaction']?['forwards'] ?? [];
//
//         dynamic myForward;
//         try {
//           myForward = forwards.lastWhere(
//                 (f) => f['sender']?['name'] == userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           myForward = null;
//         }
//
//         if (myForward != null) {
//           return {
//             'id': myForward['id'],
//             'receiverName': myForward['receiver']?['name'],
//             'status': myForward['status'],
//           };
//         }
//       }
//       return null;
//     } catch (e) {
//       print(
//           "⚠️ Error fetching my forwards for request ${request['id']}: $e");
//       return null;
//     }
//   }
//
//   // 🔹 دالة جديدة: التحقق مما إذا كان يمكن إعادة التوجيه (حسب منطق Angular)
//   Future<bool> checkIfCanForward(
//       String transactionId,
//       String? token,
//       String? userName,
//       ) async {
//     if (token == null || userName == null) return false;
//
//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//
//         if (forwards.isEmpty) {
//           // لا توجد توجيهات - يمكن للمنشئ توجيهها
//           return true;
//         }
//
//         // العثور على جميع التفاعلات التي تتضمن المستخدم الحالي
//         final myInteractions = forwards.where((f) =>
//         f['sender']?['name'] == userName || f['receiver']?['name'] == userName
//         ).toList();
//
//         if (myInteractions.isEmpty) {
//           // لم يشارك المستخدم في أي توجيه - يمكنه التوجيه
//           return true;
//         } else {
//           // ترتيب حسب المعرف (افتراض: معرف أعلى = أحدث)
//           myInteractions.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
//
//           final lastInteraction = myInteractions.last;
//
//           if (lastInteraction['sender']?['name'] == userName) {
//             // هو أرسلها آخر مرة -> لا يمكن إعادة التوجيه حتى تعود إليه
//             return false;
//           } else {
//             // استلمها آخر مرة (عادت إليه) -> يمكن إعادة التوجيه
//             return true;
//           }
//         }
//       }
//       return false;
//     } catch (e) {
//       print("⚠️ Error checking if can forward for request $transactionId: $e");
//       return false;
//     }
//   }
//
//   // 🔹 جلب الطلبات المرسلة إليك فقط
//   Future<List<dynamic>> fetchInboxRequests(
//       String userName, String? token) async {
//     if (token == null) return [];
//
//     try {
//       List<dynamic> allRequests = [];
//       int currentPage = 1;
//       int lastPage = 1;
//
//       do {
//         final Map<String, String> queryParams = {
//           "pageNumber": currentPage.toString(),
//           "pageSize": "10",
//           "receiverName": userName,
//         };
//
//         final uri = Uri.parse("$baseUrl/transactions")
//             .replace(queryParameters: queryParams);
//
//         final response = await http.get(
//           uri,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final List<dynamic> pageRequests =
//               data["transactions"] ?? [];
//           allRequests.addAll(pageRequests);
//
//           lastPage = data["page"]?["last"] ?? 1;
//           currentPage++;
//
//           if (pageRequests.isEmpty) break;
//         } else {
//           break;
//         }
//       } while (currentPage <= lastPage);
//
//       return allRequests;
//     } catch (e) {
//       print("❌ Network error in fetchInboxRequests: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تنفيذ الإجراءات (الموافقة، الرفض)
//   Future<bool> performAction(
//       String transactionId,
//       String action,
//       String? token,
//       String? userName,
//       ) async {
//     if (token == null || userName == null) return false;
//
//     try {
//       // جلب الـ forwards أولاً
//       final forwardsResponse = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (forwardsResponse.statusCode != 200) return false;
//
//       final forwardsData = json.decode(forwardsResponse.body);
//       final List<dynamic> forwards =
//           forwardsData['transaction']?['forwards'] ?? [];
//
//       if (forwards.isEmpty) return false;
//
//       // البحث عن الـ forward الخاص بالمستخدم
//       dynamic yourForward;
//       try {
//         yourForward = forwards.lastWhere(
//               (forward) => forward['receiver']?['name'] == userName,
//           orElse: () => null,
//         );
//       } catch (e) {
//         yourForward = null;
//       }
//
//       if (yourForward == null) return false;
//
//       final String forwardId = yourForward['id'].toString();
//       final Map<String, dynamic> body = {};
//
//       switch (action) {
//         case 'Approve':
//           body['status'] = 'approved';
//           break;
//         case 'Reject':
//           body['status'] = 'rejected';
//           break;
//         default:
//           return false;
//       }
//
//       final response = await http.patch(
//         Uri.parse(
//             "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(body),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in performAction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
//   Future<bool> forwardTransaction(
//       String transactionId,
//       String receiverName,
//       String? token,
//       ) async {
//     if (token == null) return false;
//
//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({"receiverName": receiverName}),
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in forwardTransaction: $e");
//       return false;
//     }
//   }
//
//   // 🔹 إلغاء الـ forward
//   Future<bool> cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       String? token,
//       ) async {
//     if (token == null || forwardId == null) return false;
//
//     try {
//       final response = await http.delete(
//         Uri.parse(
//             "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Error in cancelForward: $e");
//       return false;
//     }
//   }
//
//   // 🔹 جلب المستخدمين
//   Future<List<dynamic>> fetchUsers(String? token) async {
//     if (token == null) return [];
//
//     List<dynamic> allUsers = [];
//     int currentPage = 1;
//     bool hasMorePages = true;
//
//     try {
//       while (hasMorePages) {
//         final response = await http.get(
//           Uri.parse(
//               "$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           List<dynamic> pageUsers = [];
//
//           if (data["users"] != null) {
//             pageUsers = data["users"];
//           } else if (data["data"] != null) {
//             pageUsers = data["data"];
//           } else if (data is List) {
//             pageUsers = data;
//           }
//
//           if (pageUsers.isNotEmpty) {
//             allUsers.addAll(pageUsers);
//             currentPage++;
//             if (pageUsers.length < 100) hasMorePages = false;
//           } else {
//             hasMorePages = false;
//           }
//         } else {
//           hasMorePages = false;
//         }
//       }
//
//       // إزالة التكرارات
//       final uniqueUsers = <dynamic>[];
//       final seenIds = <dynamic>{};
//
//       for (var user in allUsers) {
//         final userId = user["id"] ?? user["_id"] ?? user["name"];
//         if (!seenIds.contains(userId)) {
//           seenIds.add(userId);
//           uniqueUsers.add(user);
//         }
//       }
//
//       return uniqueUsers;
//     } catch (e) {
//       print("❌ Error in fetchUsers: $e");
//       return [];
//     }
//   }
//
//   // 🔹 تعديل طلب موجود (لزر Edit Request)
//   Future<bool> updateRequest(
//       String requestId,
//       Map<String, dynamic> updatedData,
//       String? token,
//       ) async {
//     if (token == null) return false;
//
//     try {
//       final response = await http.put(
//         Uri.parse("$baseUrl/transactions/$requestId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(updatedData),
//       );
//
//       if (response.statusCode == 200 ||
//           response.statusCode == 204) {
//         print("✅ Request $requestId updated successfully");
//         return true;
//       } else {
//         print(
//             "⚠️ Failed to update request: ${response.statusCode}");
//         return false;
//       }
//     } catch (e) {
//       print("❌ Error updating request $requestId: $e");
//       return false;
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InboxApi {
  final String baseUrl = "http://192.168.1.3:3000";

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
        final List<dynamic> transactionTypes =
            data["transactionTypes"] ?? [];
        for (var item in transactionTypes) {
          typeNames.add(item["name"]);
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
        Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards =
            data['transaction']?['forwards'] ?? [];

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
        Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];

        if (forwards.isEmpty) {
          // لا توجد توجيهات - يمكن للمنشئ معالجتها
          return 'not-assigned';
        }

        // العثور على جميع التفاعلات التي تتضمن المستخدم الحالي
        final myInteractions = forwards.where((f) =>
        f['sender']?['name'] == userName || f['receiver']?['name'] == userName
        ).toList();

        if (myInteractions.isEmpty) {
          // لم يشارك المستخدم في أي توجيه
          return 'not-assigned';
        } else {
          // ترتيب حسب المعرف (افتراض: معرف أعلى = أحدث)
          myInteractions.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));

          final lastInteraction = myInteractions.last;

          if (lastInteraction['receiver']?['name'] == userName) {
            // 🔹 أنت المستقبل الأخير
            // إذا كنت المستقبل، فالحالة هي "waiting" (ما لم تكن قد اتخذت إجراء)
            // لكن إذا كانت حالتك السابقة "approved" أو "rejected"، تبقى كما هي
            // لأن المستخدم اتخذ إجراء بالفعل
            return lastInteraction['status'] ?? 'waiting';
          } else {
            // 🔹 أنت المرسل الأخير - الحالة هي آخر إجراء اتخذته
            return lastInteraction['status'] ?? 'waiting';
          }
        }
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
        Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards =
            data['transaction']?['forwards'] ?? [];

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
        Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards =
            data['transaction']?['forwards'] ?? [];

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
        Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];

        if (forwards.isEmpty) {
          // لا توجد توجيهات - يمكن للمنشئ توجيهها
          return true;
        }

        // العثور على جميع التفاعلات التي تتضمن المستخدم الحالي
        final myInteractions = forwards.where((f) =>
        f['sender']?['name'] == userName || f['receiver']?['name'] == userName
        ).toList();

        if (myInteractions.isEmpty) {
          // لم يشارك المستخدم في أي توجيه - يمكنه التوجيه
          return true;
        } else {
          // ترتيب حسب المعرف (افتراض: معرف أعلى = أحدث)
          myInteractions.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));

          final lastInteraction = myInteractions.last;

          if (lastInteraction['sender']?['name'] == userName) {
            // هو أرسلها آخر مرة -> لا يمكن إعادة التوجيه حتى تعود إليه
            return false;
          } else {
            // استلمها آخر مرة (عادت إليه) -> يمكن إعادة التوجيه
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
          final List<dynamic> pageRequests =
              data["transactions"] ?? [];
          allRequests.addAll(pageRequests);

          lastPage = data["page"]?["last"] ?? 1;
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
      // جلب الـ forwards أولاً
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

      // البحث عن الـ forward الخاص بالمستخدم
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
            "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
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

  // 🔹 تنفيذ الإجراءات (الموافقة، الرفض) - الجديدة (تتعامل مع الحالة الجديدة)
  Future<bool> performActionUpdated(
      String transactionId,
      String action,
      String? token,
      String? userName,
      ) async {
    if (token == null || userName == null) return false;

    try {
      // جلب الـ forwards أولاً
      final forwardsResponse = await http.get(
        Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (forwardsResponse.statusCode != 200) return false;

      final forwardsData = json.decode(forwardsResponse.body);
      final List<dynamic> forwards = forwardsData['transaction']?['forwards'] ?? [];

      if (forwards.isEmpty) return false;

      // 🔹 البحث عن آخر forward حيث أنت المستقبل (من الأحدث إلى الأقدم)
      dynamic yourForward;
      try {
        // ترتيب من الأحدث إلى الأقدم
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
          body['status'] = 'approved';
          break;
        case 'Reject':
          body['status'] = 'rejected';
          break;
        default:
          return false;
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
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

  // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
  Future<bool> forwardTransaction(
      String transactionId,
      String receiverName,
      String? token,
      ) async {
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"receiverName": receiverName}),
      );

      return response.statusCode == 200;
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
            "$baseUrl/transactions/$transactionId/forwards/$forwardId"),
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

      // إزالة التكرارات
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
      final response = await http.put(
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