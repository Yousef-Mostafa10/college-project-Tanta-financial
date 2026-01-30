// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
//
// import '../request/ditalis_request.dart';
//
// // 🎨 COLOR PALETTE - Consistent with Administrative Dashboard
// class InboxColors {
//   // Primary Colors (same as AppColors)
//   static const Color primary = Color(0xFF00695C);
//   static const Color primaryLight = Color(0xFF00796B);
//
//   // Sidebar Colors
//   static const Color sidebarBg = Color(0xFF0E6C62);
//   static const Color sidebarText = Color(0xFFFFFFFF);
//   static const Color sidebarHover = Color(0xFF07584F);
//
//   // Background Colors
//   static const Color bodyBg = Color(0xFFF5F6FA);
//   static const Color cardBg = Color(0xFFFFFFFF);
//
//   // Text Colors
//   static const Color textPrimary = Color(0xFF2C3E50);
//   static const Color textSecondary = Color(0xFF7F8C8D);
//   static const Color textMuted = Color(0xFFB0B0B0);
//
//   // Accent Colors (same as AppColors)
//   static const Color accentYellow = Color(0xFFFFB74D);
//   static const Color accentRed = Color(0xFFE74C3C);
//   static const Color accentGreen = Color(0xFF27AE60);
//   static const Color accentBlue = Color(0xFF1E88E5);
//
//   // Status Colors with unique icons (same as AppColors)
//   static const Color statusApproved = Color(0xFF27AE60);
//   static const Color statusRejected = Color(0xFFE74C3C);
//   static const Color statusWaiting = Color(0xFF1E88E5);
//   static const Color statusPending = Color(0xFFFFB74D);
//   static const Color statusFulfilled = Color(0xFF009688);
//
//   // Additional Colors for Statistics
//   static const Color statBgLight = Color(0xFFF0F8F7); // ⬅️ درجة فاتحة من اللون الأساسي
//   static const Color statBorder = Color(0xFFB2DFDB);
//   static const Color statShadow = Color(0x1A00695C);
// }
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final String baseUrl = "http://192.168.1.3:3000";
//   final TextEditingController _searchController = TextEditingController();
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   // 🔹 تهيئة البيانات
//   Future<void> _initializeData() async {
//     await _getUserInfo();
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//     }
//   }
//
//   // 🔹 جلب معلومات المستخدم المسجل
//   Future<void> _getUserInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       final userName =
//           prefs.getString('userName') ?? prefs.getString('username') ?? 'admin';
//
//       final token = prefs.getString('token');
//
//       setState(() {
//         _userName = userName;
//         _userToken = token;
//       });
//     } catch (e) {
//       debugPrint("❌ Error getting user info: $e");
//       setState(() {
//         _userName = 'admin';
//         _isLoading = false;
//       });
//     }
//   }
//
//   // 🔹 جلب أنواع المعاملات
//   Future<void> _fetchTypes() async {
//     try {
//       if (_userToken == null) return;
//
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/types"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           typeNames = ['All Types'];
//           final List<dynamic> transactionTypes = data["transactionTypes"] ?? [];
//           for (var item in transactionTypes) {
//             typeNames.add(item["name"]);
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error fetching types: $e");
//     }
//   }
//
//   // 🔹 جلب الطلبات المرسلة إليك فقط + جلب الforwards لكل طلب لتحديد yourForwardStatus و lastSenderName
//   Future<void> _fetchInboxRequests() async {
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
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
//           "receiverName": _userName!,
//         };
//
//         final uri = Uri.parse(
//           "$baseUrl/transactions",
//         ).replace(queryParameters: queryParams);
//
//         final response = await http.get(
//           uri,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $_userToken',
//           },
//         );
//
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final List<dynamic> pageRequests = data["transactions"] ?? [];
//
//           // Process requests in parallel for better performance
//           await Future.wait(
//             pageRequests.map((req) async {
//               req['yourForwardStatus'] = await _getYourForwardStatusForRequest(
//                 req,
//               );
//               req['lastSenderName'] = await _getLastSenderNameForYou(req);
//               req['lastForwardSentTo'] = await _getLastForwardSentByYou(req);
//             }),
//           );
//
//           allRequests.addAll(pageRequests);
//
//           lastPage = data["page"]?["last"] ?? 1;
//           currentPage++;
//
//           if (pageRequests.isEmpty) break;
//         } else if (response.statusCode == 401) {
//           _handleTokenExpired();
//           break;
//         } else {
//           break;
//         }
//       } while (currentPage <= lastPage);
//
//       setState(() {
//         _requests = allRequests;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests: $e";
//       });
//     }
//   }
//
//   // ⭐ دالة تطبيق الفلاتر محلياً
//   void _applyFilters() {
//     List<dynamic> filtered = _requests;
//
//     // فلترة النوع
//     if (_selectedType != "All Types") {
//       filtered = filtered.where((request) {
//         final type = request["type"]?["name"] ?? "";
//         return type == _selectedType;
//       }).toList();
//     }
//
//     // فلترة الأولوية
//     if (_selectedPriority != "All") {
//       filtered = filtered.where((request) {
//         final priority = request["priority"] ?? "";
//         return priority.toLowerCase() == _selectedPriority.toLowerCase();
//       }).toList();
//     }
//
//     // فلترة الحالة
//     if (_selectedStatus != "All") {
//       filtered = filtered.where((request) {
//         final userForwardStatus = request["yourForwardStatus"];
//         final fulfilled = request["fulfilled"] == true;
//
//         switch (_selectedStatus) {
//           case "Approved":
//             return userForwardStatus == "approved";
//           case "Rejected":
//             return userForwardStatus == "rejected";
//           case "Fulfilled":
//             return fulfilled == true;
//           case "Waiting":
//             return (userForwardStatus != "approved" &&
//                 userForwardStatus != "rejected" &&
//                 !fulfilled) ||
//                 (userForwardStatus == null && !fulfilled);
//           default:
//             return true;
//         }
//       }).toList();
//     }
//
//     // فلترة البحث
//     final searchTerm = _searchController.text.toLowerCase();
//     if (searchTerm.isNotEmpty) {
//       filtered = filtered.where((request) {
//         final title = (request["title"] ?? "").toLowerCase();
//         final senderName =
//         (request["lastSenderName"] ?? request["creator"]?["name"] ?? "")
//             .toLowerCase();
//         return title.contains(searchTerm) || senderName.contains(searchTerm);
//       }).toList();
//     }
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   // 🔹 جلب الforwards للمعاملة وتحديد حالة المستخدم الحالي (yourForwardStatus)
//   Future<String> _getYourForwardStatusForRequest(dynamic request) async {
//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> forwards = data['transaction']?['forwards'] ?? [];
//         dynamic yourForward;
//         try {
//           yourForward = forwards.lastWhere(
//                 (f) => f['receiver']?['name'] == _userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//         if (yourForward != null) {
//           return yourForward['status'] ?? 'waiting';
//         } else {
//           return 'not-assigned';
//         }
//       } else {
//         return 'unknown';
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error fetching forwards for request ${request['id']}: $e");
//       return 'unknown';
//     }
//   }
//
//   // 🔹 جلب اسم الشخص الذي أرسل المعاملة إليك (الـ forward الذي receiver == current user)
//   Future<String> _getLastSenderNameForYou(dynamic request) async {
//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
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
//                 (f) => f['receiver']?['name'] == _userName,
//             orElse: () => null,
//           );
//         } catch (e) {
//           yourForward = null;
//         }
//
//         if (yourForward != null) {
//           return yourForward['sender']?['name'] ??
//               (request['creator']?['name'] ?? 'Unknown');
//         } else {
//           return request['creator']?['name'] ?? 'Unknown';
//         }
//       }
//     } catch (e) {
//       debugPrint(
//         "⚠️ Error fetching last sender for request ${request['id']}: $e",
//       );
//     }
//     return request['creator']?['name'] ?? 'Unknown';
//   }
//
//   // 🔹 جلب معلومات الforward الأخير الذي أرسلناه (إن وجد)
//   Future<Map<String, dynamic>?> _getLastForwardSentByYou(
//       dynamic request,
//       ) async {
//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
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
//                 (f) => f['sender']?['name'] == _userName,
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
//     } catch (e) {
//       debugPrint(
//         "⚠️ Error fetching my forwards for request ${request['id']}: $e",
//       );
//     }
//     return null;
//   }
//
//   // 🔹 دالة تنفيذ الإجراءات (الموافقة، الرفض)
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor, [
//         String? bodyPayload,
//       ]) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final forwardsResponse = await http.get(
//         Uri.parse("$baseUrl/transactions/${request['id']}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (forwardsResponse.statusCode != 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to fetch forwards: ${forwardsResponse.statusCode}',
//               ),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//         return;
//       }
//
//       final forwardsData = json.decode(forwardsResponse.body);
//       final List<dynamic> forwards =
//           forwardsData['transaction']?['forwards'] ?? [];
//
//       if (forwards.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('No forwards found for this transaction'),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//         return;
//       }
//
//       dynamic yourForward;
//       try {
//         yourForward = forwards.lastWhere(
//               (forward) => forward['receiver']?['name'] == _userName,
//           orElse: () => null,
//         );
//       } catch (e) {
//         yourForward = null;
//       }
//
//       if (yourForward == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('You are not a receiver in this transaction'),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//         return;
//       }
//
//       final String forwardId = yourForward['id'].toString();
//       final String transactionId = request['id'].toString();
//
//       final String endpoint =
//           "$baseUrl/transactions/$transactionId/forwards/$forwardId";
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
//           return;
//       }
//
//       final response = await http.patch(
//         Uri.parse(endpoint),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//         body: json.encode(body),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData["status"] == "success") {
//           setState(() {
//             request['yourForwardStatus'] = body['status'];
//             if (body['status'] == 'approved') {
//               request['fulfilled'] = true;
//             }
//           });
//
//           _applyFilters();
//
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'Transaction has been ${body['status']} successfully',
//                 ),
//                 backgroundColor: snackBarColor,
//                 behavior: SnackBarBehavior.floating,
//               ),
//             );
//           }
//         } else {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Action failed: ${responseData["message"]}'),
//                 backgroundColor: InboxColors.accentRed,
//               ),
//             );
//           }
//         }
//       } else {
//         final errorData = json.decode(response.body);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to perform action: ${errorData["message"] ?? "Status: ${response.statusCode}"}',
//               ),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Network error during action: $e'),
//             backgroundColor: InboxColors.accentRed,
//           ),
//         );
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // 🔹 جلب المستخدمين
//   Future<List<dynamic>> _fetchUsers() async {
//     if (_userToken == null) return [];
//
//     List<dynamic> allUsers = [];
//     int currentPage = 1;
//     bool hasMorePages = true;
//
//     debugPrint('🔄 Starting to fetch users for inbox...');
//
//     try {
//       while (hasMorePages) {
//         try {
//           final response = await http.get(
//             Uri.parse("$baseUrl/users?pageNumber=$currentPage&pageSize=100"),
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $_userToken',
//             },
//           );
//
//           if (response.statusCode == 200) {
//             final data = json.decode(response.body);
//             debugPrint('📥 Inbox - Page $currentPage response: ${data.keys}');
//
//             List<dynamic> pageUsers = [];
//
//             if (data["users"] != null) {
//               pageUsers = data["users"];
//             } else if (data["data"] != null) {
//               pageUsers = data["data"];
//             } else if (data is List) {
//               pageUsers = data;
//             }
//
//             debugPrint(
//               '📋 Inbox - Found ${pageUsers.length} users in page $currentPage',
//             );
//
//             if (pageUsers.isNotEmpty) {
//               allUsers.addAll(pageUsers);
//
//               final lastPage =
//                   data["page"]?["last"] ??
//                       data["lastPage"] ??
//                       data["totalPages"];
//               final totalPages = data["totalPages"] ?? data["total_pages"];
//
//               if (lastPage != null && currentPage >= lastPage) {
//                 hasMorePages = false;
//                 debugPrint('🛑 Inbox - Reached last page: $lastPage');
//               } else if (totalPages != null && currentPage >= totalPages) {
//                 hasMorePages = false;
//                 debugPrint('🛑 Inbox - Reached total pages: $totalPages');
//               } else if (pageUsers.length < 100) {
//                 hasMorePages = false;
//                 debugPrint(
//                   '🛑 Inbox - Fewer users than page size, assuming last page',
//                 );
//               } else {
//                 currentPage++;
//                 debugPrint('➡️ Inbox - Moving to page $currentPage');
//               }
//             } else {
//               hasMorePages = false;
//               debugPrint('🛑 Inbox - Empty page - stopping');
//             }
//           } else {
//             debugPrint(
//               '❌ Inbox - HTTP error on page $currentPage: ${response.statusCode}',
//             );
//             hasMorePages = false;
//           }
//         } catch (e) {
//           debugPrint('❌ Inbox - Error fetching page $currentPage: $e');
//           hasMorePages = false;
//         }
//       }
//
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
//       debugPrint(
//         '🎉 Inbox - Total unique users fetched: ${uniqueUsers.length}',
//       );
//       return uniqueUsers;
//     } catch (e) {
//       debugPrint('❌ Inbox - General error in _fetchUsers: $e');
//       return [];
//     }
//   }
//
//   // 🔹 إرسال المعاملة لمستخدم آخر (Forward)
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     if (_userToken == null) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final users = await _fetchUsers();
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     if (users.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No users available to forward.')),
//         );
//       }
//       return;
//     }
//
//     String? selectedUser;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "Select user to forward to (${users.length} users available)",
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) =>
//                           setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedUser == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Please select a user.')),
//                       );
//                       return;
//                     }
//
//                     Navigator.pop(context);
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     try {
//                       final response = await http.post(
//                         Uri.parse(
//                           "$baseUrl/transactions/$transactionId/forwards",
//                         ),
//                         headers: {
//                           'Content-Type': 'application/json',
//                           'Authorization': 'Bearer $_userToken',
//                         },
//                         body: json.encode({"receiverName": selectedUser}),
//                       );
//
//                       if (response.statusCode == 200) {
//                         if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Transaction forwarded successfully!',
//                               ),
//                               backgroundColor: InboxColors.accentGreen,
//                             ),
//                           );
//                         }
//
//                         setState(() {
//                           request['lastForwardSentTo'] = {
//                             'id': json.decode(
//                               response.body,
//                             )['transactionForward']?['id'],
//                             'receiverName': selectedUser,
//                             'status': 'waiting',
//                           };
//                         });
//
//                         _applyFilters();
//                       } else {
//                         if (mounted) {
//                           final err = response.body.isNotEmpty
//                               ? json.decode(response.body)
//                               : null;
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'Failed to forward: ${err?['message'] ?? response.statusCode}',
//                               ),
//                               backgroundColor: InboxColors.accentRed,
//                             ),
//                           );
//                         }
//                       }
//                     } catch (e) {
//                       if (mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('Error: $e'),
//                             backgroundColor: InboxColors.accentRed,
//                           ),
//                         );
//                       }
//                     } finally {
//                       setState(() {
//                         _isLoading = false;
//                       });
//                     }
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 إلغاء الـ forward (DELETE) مع تأكيد
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (_userToken == null) return;
//     if (forwardId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No forward id available to cancel.')),
//       );
//       return;
//     }
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final response = await http.delete(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards/$forwardId"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final resp = json.decode(response.body);
//         if (resp['status'] == 'success') {
//           setState(() {
//             request['lastForwardSentTo'] = null;
//           });
//
//           _applyFilters();
//
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Forward cancelled successfully'),
//                 backgroundColor: InboxColors.accentGreen,
//               ),
//             );
//           }
//         } else {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'Failed to cancel forward: ${resp['message'] ?? 'Unknown'}',
//                 ),
//                 backgroundColor: InboxColors.accentRed,
//               ),
//             );
//           }
//         }
//       } else {
//         if (mounted) {
//           final err = response.body.isNotEmpty
//               ? json.decode(response.body)
//               : null;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to cancel forward: ${err?['message'] ?? response.statusCode}',
//               ),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Network error: $e'),
//             backgroundColor: InboxColors.accentRed,
//           ),
//         );
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // 🔹 دالة لتحويل التاريخ
//   String _formatDate(dynamic dateValue) {
//     try {
//       if (dateValue == null ||
//           dateValue == "N/A" ||
//           dateValue.toString().isEmpty) {
//         return "N/A";
//       }
//
//       String dateString = dateValue.toString();
//       if (dateString.contains('T')) {
//         final date = DateTime.parse(dateString);
//         return DateFormat('MMM dd, yyyy - HH:mm').format(date);
//       }
//       return dateString;
//     } catch (e) {
//       debugPrint("❌ Error formatting date: $dateValue - $e");
//       return "N/A";
//     }
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody() // ⬅️ تصميم جديد للجوال مع Sticky Header
//           : _buildDesktopBody(),
//     );
//   }
//
//   // ⭐ تصميم الجوال مع Sticky Header
//   Widget _buildMobileOptimizedBody() {
//     // حساب الإحصائيات
//     final total = _requests.length;
//     final waiting = _requests
//         .where(
//           (req) =>
//       (req['yourForwardStatus'] != "approved" &&
//           req['yourForwardStatus'] != "rejected" &&
//           req['fulfilled'] != true) ||
//           (req['yourForwardStatus'] == null && req['fulfilled'] != true),
//     )
//         .length;
//     final approved = _requests
//         .where((req) => req['yourForwardStatus'] == "approved")
//         .length;
//     final rejected = _requests
//         .where((req) => req['yourForwardStatus'] == "rejected")
//         .length;
//     final fulfilled = _requests
//         .where((req) => req['fulfilled'] == true)
//         .length;
//
//     return Column(
//       children: [
//         // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات
//         if (_requests.isNotEmpty)
//           _buildMobileStatsSection(
//             total: total,
//             waiting: waiting,
//             approved: approved,
//             rejected: rejected,
//             fulfilled: fulfilled,
//           ),
//
//         // 2️⃣ الجزء الثابت عند الأعلى - البحث والفلترة
//         _buildMobileFilterSection(),
//
//         // 3️⃣ قائمة الطلبات فقط هي التي تسكرول
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   // ⭐ تصميم محسن لشريط الإحصائيات للجوال (مطابق للداشبورد)
//   Widget _buildMobileStatsSection({
//     required int total,
//     required int waiting,
//     required int approved,
//     required int rejected,
//     required int fulfilled,
//   }) {
//     final statItems = [
//       {"label": "Total", "value": total, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Waiting", "value": waiting, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//       {"label": "Approved", "value": approved, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejected, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
//       if (fulfilled > 0) {"label": "Fulfilled", "value": fulfilled, "color": InboxColors.statusFulfilled, "icon": Icons.check_rounded},
//     ];
//
//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: InboxColors.statBgLight, // ⬅️ استخدام درجة فاتحة من اللون الأساسي
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: InboxColors.statShadow,
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: InboxColors.statBorder),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: statItems.map((stat) => _buildMobileStatItem(
//           label: stat["label"] as String,
//           value: stat["value"] as int,
//           color: stat["color"] as Color,
//           icon: stat["icon"] as IconData,
//         )).toList(),
//       ),
//     );
//   }
//
//   Widget _buildMobileStatItem({required String label, required int value, required Color color, required IconData icon}) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: 18),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//             color: InboxColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileFilterSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: InboxColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: InboxColors.statShadow,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // شريط البحث
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search requests...',
//               hintStyle: TextStyle(color: InboxColors.textMuted),
//               prefixIcon: const Icon(Icons.search_rounded, color: InboxColors.primary),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide.none,
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: InboxColors.primary, width: 1.5),
//               ),
//               filled: true,
//               fillColor: InboxColors.bodyBg,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               isDense: true,
//             ),
//             onChanged: (value) => _applyFilters(),
//           ),
//           const SizedBox(height: 12),
//
//           // الفلاتر في صف واحد
//           Row(
//             children: [
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Priority",
//                   value: _selectedPriority,
//                   icon: Icons.flag_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Priority",
//                     priorities,
//                     _selectedPriority,
//                         (value) {
//                       setState(() => _selectedPriority = value);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Type",
//                   value: _selectedType,
//                   icon: Icons.category_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Type",
//                     typeNames,
//                     _selectedType,
//                         (value) {
//                       setState(() => _selectedType = value);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Status",
//                   value: _selectedStatus,
//                   icon: Icons.hourglass_top_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Status",
//                     statuses,
//                     _selectedStatus,
//                         (value) {
//                       setState(() => _selectedStatus = value);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMobileFilterChip({
//     required String label,
//     required String value,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//         decoration: BoxDecoration(
//           color: InboxColors.primary.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: InboxColors.primary.withOpacity(0.2)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 14, color: InboxColors.primary),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 9,
//                 color: InboxColors.primary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             if (value != 'All' && value != 'All Types')
//               Text(
//                 value.length > 8 ? value.substring(0, 8) + '...' : value,
//                 style: TextStyle(
//                   fontSize: 8,
//                   color: InboxColors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(20),
//               topRight: const Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () => onSelected(option),
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: _filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = _filteredRequests[index];
//         final id = req["id"].toString();
//         final title = req["title"] ?? "No Title";
//         final type = req["type"]?["name"] ?? "N/A";
//         final priority = req["priority"] ?? "N/A";
//         final senderName =
//             req["lastSenderName"] ?? req["creator"]?["name"] ?? "Unknown";
//         final createdAt = req["createdAt"];
//         final formattedDate = _formatDate(createdAt);
//
//         final forwardStatus = (req['yourForwardStatus'] ?? 'not-assigned')
//             .toString();
//         final isPending =
//             forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//         final isApproved = forwardStatus == 'approved';
//         final isRejected = forwardStatus == 'rejected';
//         final fulfilled = req["fulfilled"] == true;
//
//         final statusLabel = fulfilled
//             ? "Fulfilled"
//             : (isApproved ? "Approved" : (isPending ? "Waiting" : "Rejected"));
//         final statusColor = fulfilled
//             ? InboxColors.statusFulfilled
//             : (isApproved
//             ? InboxColors.statusApproved
//             : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected));
//
//         return _buildMobileRequestCard(
//           request: req,
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           senderName: senderName,
//           date: formattedDate,
//           statusText: statusLabel,
//           statusColor: statusColor,
//           isPending: isPending,
//           isApproved: isApproved,
//           isRejected: isRejected,
//           fulfilled: fulfilled,
//         );
//       },
//     );
//   }
//
//   Widget _buildMobileRequestCard({
//     required Map<String, dynamic> request,
//     required String id,
//     required String title,
//     required String type,
//     required String priority,
//     required String senderName,
//     required String date,
//     required String statusText,
//     required Color statusColor,
//     required bool isPending,
//     required bool isApproved,
//     required bool isRejected,
//     required bool fulfilled,
//   }) {
//     final lastForwardSentTo = request['lastForwardSentTo'];
//     final hasForwarded = lastForwardSentTo != null;
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Icon(getStatusIcon(), color: statusColor, size: 16),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: InboxColors.textPrimary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       statusText,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "From: $senderName",
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       date.length > 16 ? date.substring(0, 16) : date,
//                       style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//
//               // النوع والأولوية
//               Row(
//                 children: [
//                   _buildMobileChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, Icons.flag_outlined, _getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               // أزرار الإجراءات
//               if (isPending) ...[
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   CourseApprovalRequestPage(requestId: id),
//                             ),
//                           );
//                         },
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text(
//                           'View',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () =>
//                             _performAction(request, 'Approve', InboxColors.accentGreen),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentGreen,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text(
//                           'Approve',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () =>
//                             _performAction(request, 'Reject', InboxColors.accentRed),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                         ),
//                         child: const Text(
//                           'Reject',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isApproved && !hasForwarded) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => _forwardTransaction(id, request),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: InboxColors.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                     ),
//                     child: const Text('Forward'),
//                   ),
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.send_rounded,
//                             size: 14,
//                             color: InboxColors.primary,
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(
//                               Icons.more_vert_rounded,
//                               size: 16,
//                               color: InboxColors.textSecondary,
//                             ),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Text('Cancel Forward'),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') {
//                                 _cancelForward(
//                                   id,
//                                   lastForwardSentTo['id'],
//                                   request,
//                                 );
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   CourseApprovalRequestPage(requestId: id),
//                             ),
//                           );
//                         },
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isRejected || fulfilled) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => CourseApprovalRequestPage(requestId: id),
//                         ),
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: InboxColors.primary,
//                       side: BorderSide(color: InboxColors.primary),
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                     ),
//                     child: const Text('View Details'),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 2),
//           Text(
//             text.length > 8 ? text.substring(0, 8) + '...' : text,
//             style: TextStyle(
//               fontSize: 9,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ⭐ تصميم الديسكتوب
//   Widget _buildDesktopBody() {
//     // حساب الإحصائيات
//     final total = _requests.length;
//     final waiting = _requests
//         .where(
//           (req) =>
//       (req['yourForwardStatus'] != "approved" &&
//           req['yourForwardStatus'] != "rejected" &&
//           req['fulfilled'] != true) ||
//           (req['yourForwardStatus'] == null && req['fulfilled'] != true),
//     )
//         .length;
//     final approved = _requests
//         .where((req) => req['yourForwardStatus'] == "approved")
//         .length;
//     final rejected = _requests
//         .where((req) => req['yourForwardStatus'] == "rejected")
//         .length;
//     final fulfilled = _requests
//         .where((req) => req['fulfilled'] == true)
//         .length;
//
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // شريط الإحصائيات
//             _buildDesktopStatsRow(
//               total: total,
//               waiting: waiting,
//               approved: approved,
//               rejected: rejected,
//               fulfilled: fulfilled,
//             ),
//             const SizedBox(height: 16),
//             _buildDesktopSearchBar(),
//             const SizedBox(height: 16),
//             _buildDesktopFilters(),
//             const SizedBox(height: 20),
//             _buildDesktopHeader(),
//             const SizedBox(height: 16),
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopStatsRow({
//     required int total,
//     required int waiting,
//     required int approved,
//     required int rejected,
//     required int fulfilled,
//   }) {
//     final stats = [
//       {"label": "Total", "value": total, "color": InboxColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Waiting", "value": waiting, "color": InboxColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//       {"label": "Approved", "value": approved, "color": InboxColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejected, "color": InboxColors.statusRejected, "icon": Icons.cancel_rounded},
//       if (fulfilled > 0) {"label": "Fulfilled", "value": fulfilled, "color": InboxColors.statusFulfilled, "icon": Icons.check_rounded},
//     ];
//
//     return Container(
//       decoration: BoxDecoration(
//         color: InboxColors.statBgLight,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: InboxColors.statShadow,
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: InboxColors.statBorder),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: stats.map((stat) =>
//               _buildStatItem(
//                   stat["label"] as String,
//                   stat["value"] as int,
//                   stat["color"] as Color,
//                   stat["icon"] as IconData,
//                   false
//               )
//           ).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatItem(String label, int value, Color color, IconData icon, bool isMobile) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(isMobile ? 8 : 10),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: isMobile ? 18 : 22),
//         ),
//         SizedBox(height: isMobile ? 6 : 10),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         SizedBox(height: isMobile ? 2 : 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isMobile ? 10 : 13,
//             fontWeight: FontWeight.w500,
//             color: InboxColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDesktopSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: InboxColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: InboxColors.statShadow,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search requests...',
//           hintStyle: TextStyle(color: InboxColors.textMuted),
//           prefixIcon: Icon(Icons.search_rounded, color: InboxColors.primary),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: InboxColors.primary, width: 1.5),
//           ),
//           filled: true,
//           fillColor: InboxColors.bodyBg,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         onChanged: (value) => _applyFilters(),
//       ),
//     );
//   }
//
//   Widget _buildDesktopFilters() {
//     return Card(
//       elevation: 2,
//       color: InboxColors.cardBg,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.filter_alt_outlined, color: InboxColors.primary, size: 16),
//                 const SizedBox(width: 6),
//                 Text(
//                   'FILTERS',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: InboxColors.primary,
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDesktopFilterDropdown(
//                     value: _selectedPriority,
//                     items: priorities,
//                     label: "Priority",
//                     icon: Icons.flag_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedPriority = value!);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDesktopFilterDropdown(
//                     value: _selectedType,
//                     items: typeNames,
//                     label: "Type",
//                     icon: Icons.category_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedType = value!);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDesktopFilterDropdown(
//                     value: _selectedStatus,
//                     items: statuses,
//                     label: "Status",
//                     icon: Icons.hourglass_top_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedStatus = value!);
//                       _applyFilters();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopFilterDropdown({
//     required String value,
//     required List<String> items,
//     required String label,
//     required IconData icon,
//     required Function(String?) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: InboxColors.statBorder),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             value: value,
//             isExpanded: true,
//             icon: Icon(Icons.arrow_drop_down_rounded, color: InboxColors.textSecondary),
//             style: TextStyle(
//               fontSize: 14,
//               color: InboxColors.textPrimary,
//               fontWeight: FontWeight.w500,
//             ),
//             items: items
//                 .map((item) => DropdownMenuItem(
//               value: item,
//               child: Row(
//                 children: [
//                   Icon(
//                     label == "Status" ? _getStatusFilterIcon(item) : icon,
//                     size: 18,
//                     color: InboxColors.primary,
//                   ),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       item,
//                       style: TextStyle(
//                         color: item == 'All Types' || item == 'All'
//                             ? InboxColors.primary
//                             : InboxColors.textPrimary,
//                         fontWeight: item == 'All Types' || item == 'All'
//                             ? FontWeight.w600
//                             : FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ))
//                 .toList(),
//             onChanged: onChanged,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.inbox_rounded, color: InboxColors.primary, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 'INBOX REQUESTS',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: InboxColors.primary,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: InboxColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(color: InboxColors.primary.withOpacity(0.3)),
//             ),
//             child: Text(
//               '${_filteredRequests.length} items',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: InboxColors.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final id = req["id"].toString();
//         final title = req["title"] ?? "No Title";
//         final type = req["type"]?["name"] ?? "N/A";
//         final priority = req["priority"] ?? "N/A";
//         final senderName =
//             req["lastSenderName"] ?? req["creator"]?["name"] ?? "Unknown";
//         final createdAt = req["createdAt"];
//         final formattedDate = _formatDate(createdAt);
//
//         final forwardStatus = (req['yourForwardStatus'] ?? 'not-assigned')
//             .toString();
//         final isPending =
//             forwardStatus == 'waiting' || forwardStatus == 'not-assigned';
//         final isApproved = forwardStatus == 'approved';
//         final isRejected = forwardStatus == 'rejected';
//         final fulfilled = req["fulfilled"] == true;
//
//         final statusLabel = fulfilled
//             ? "Fulfilled"
//             : (isApproved ? "Approved" : (isPending ? "Waiting" : "Rejected"));
//         final statusColor = fulfilled
//             ? InboxColors.statusFulfilled
//             : (isApproved
//             ? InboxColors.statusApproved
//             : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected));
//
//         return Container(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: _buildDesktopRequestCard(
//             request: req,
//             id: id,
//             title: title,
//             type: type,
//             priority: priority,
//             senderName: senderName,
//             date: formattedDate,
//             statusText: statusLabel,
//             statusColor: statusColor,
//             isPending: isPending,
//             isApproved: isApproved,
//             isRejected: isRejected,
//             fulfilled: fulfilled,
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildDesktopRequestCard({
//     required Map<String, dynamic> request,
//     required String id,
//     required String title,
//     required String type,
//     required String priority,
//     required String senderName,
//     required String date,
//     required String statusText,
//     required Color statusColor,
//     required bool isPending,
//     required bool isApproved,
//     required bool isRejected,
//     required bool fulfilled,
//   }) {
//     final lastForwardSentTo = request['lastForwardSentTo'];
//     final hasForwarded = lastForwardSentTo != null;
//
//     IconData getStatusIcon() {
//       if (fulfilled) return Icons.check_rounded;
//       if (isApproved) return Icons.check_circle_rounded;
//       if (isRejected) return Icons.cancel_rounded;
//       return Icons.hourglass_empty_rounded;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: InboxColors.cardBg,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1️⃣ الصف العلوي: العنوان والحالة
//               Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Icon(getStatusIcon(), color: statusColor, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: InboxColors.textPrimary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor.withOpacity(0.3)),
//                     ),
//                     child: Text(
//                       statusText,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 2️⃣ معلومات المرسل والتاريخ
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Text(
//                     "From: $senderName",
//                     style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                   ),
//                   const SizedBox(width: 24),
//                   Icon(Icons.calendar_today_rounded, size: 14, color: InboxColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       date,
//                       style: TextStyle(fontSize: 13, color: InboxColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, InboxColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, Icons.flag_outlined, _getPriorityColor(priority)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // 4️⃣ أزرار الإجراءات - نفس الموبايل بالضبط
//               if (isPending) ...[
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   CourseApprovalRequestPage(requestId: id),
//                             ),
//                           );
//                         },
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () =>
//                             _performAction(request, 'Approve', InboxColors.accentGreen),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentGreen,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('Approve'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () =>
//                             _performAction(request, 'Reject', InboxColors.accentRed),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: InboxColors.accentRed,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                         ),
//                         child: const Text('Reject'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isApproved && !hasForwarded) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => _forwardTransaction(id, request),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: InboxColors.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: const Text('Forward to Another User'),
//                   ),
//                 ),
//               ] else if (hasForwarded) ...[
//                 Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: InboxColors.bodyBg,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: InboxColors.statBorder),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.send_rounded,
//                             size: 16,
//                             color: InboxColors.primary,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Forwarded to ${lastForwardSentTo['receiverName']}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 color: InboxColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           PopupMenuButton<String>(
//                             icon: Icon(
//                               Icons.more_vert_rounded,
//                               size: 18,
//                               color: InboxColors.textSecondary,
//                             ),
//                             itemBuilder: (context) => [
//                               const PopupMenuItem(
//                                 value: 'cancel',
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
//                                     SizedBox(width: 8),
//                                     Text('Cancel Forward'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             onSelected: (value) {
//                               if (value == 'cancel') {
//                                 _cancelForward(
//                                   id,
//                                   lastForwardSentTo['id'],
//                                   request,
//                                 );
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   CourseApprovalRequestPage(requestId: id),
//                             ),
//                           );
//                         },
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: InboxColors.primary,
//                           side: BorderSide(color: InboxColors.primary),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('View Details'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else if (isRejected || fulfilled) ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => CourseApprovalRequestPage(requestId: id),
//                         ),
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: InboxColors.primary,
//                       side: BorderSide(color: InboxColors.primary),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: const Text('View Details'),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// // 🔹 يجب إضافة هذه الدالة المساعدة بعد _buildDesktopRequestCard مباشرة
//   Widget _buildDesktopChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDesktopActionButtons(Map<String, dynamic> request, String id, bool isPending, bool isApproved, bool hasForwarded) {
//     if (isPending) {
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ElevatedButton(
//             onPressed: () =>
//                 _performAction(request, 'Approve', InboxColors.accentGreen),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: InboxColors.accentGreen,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             ),
//             child: const Text('Approve'),
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton(
//             onPressed: () =>
//                 _performAction(request, 'Reject', InboxColors.accentRed),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: InboxColors.accentRed,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             ),
//             child: const Text('Reject'),
//           ),
//         ],
//       );
//     } else if (isApproved && !hasForwarded) {
//       return ElevatedButton(
//         onPressed: () => _forwardTransaction(id, request),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: InboxColors.primary,
//           foregroundColor: Colors.white,
//         ),
//         child: const Text('Forward'),
//       );
//     }
//     return const SizedBox();
//   }
//
//   Widget _buildChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           const SizedBox(width: 2),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 10,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 🔹 دوال مساعدة
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your inbox...',
//             style: TextStyle(
//               fontSize: 16,
//               color: InboxColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.only(top: 60.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.inbox_outlined,
//               size: 64,
//               color: InboxColors.textMuted,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "No requests found",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: InboxColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Try adjusting your filters or check back later",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: InboxColors.textMuted,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () {
//                 setState(() {
//                   _selectedPriority = 'All';
//                   _selectedType = 'All Types';
//                   _selectedStatus = 'All';
//                   _searchController.clear();
//                 });
//                 _applyFilters();
//               },
//               icon: const Icon(Icons.refresh_rounded, size: 16),
//               label: const Text("Reset Filters"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: InboxColors.primary,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   IconData _getStatusFilterIcon(String status) {
//     switch (status.toLowerCase()) {
//       case "approved":
//         return Icons.check_circle_rounded;
//       case "rejected":
//         return Icons.cancel_rounded;
//       case "waiting":
//         return Icons.hourglass_empty_rounded;
//       case "fulfilled":
//         return Icons.check_rounded;
//       case "all":
//         return Icons.filter_list_rounded;
//       default:
//         return Icons.hourglass_top_outlined;
//     }
//   }
//
//   Color _getPriorityColor(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high':
//         return InboxColors.accentRed;
//       case 'medium':
//         return InboxColors.accentYellow;
//       case 'low':
//         return InboxColors.accentGreen;
//       default:
//         return InboxColors.textMuted;
//     }
//   }
// }


// Notefecation/inbox_page.dart
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // استيراد الملفات الجديدة
// import './inbox_colors.dart';
// import './inbox_api.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
// import './inbox_desktop_card.dart';
// import './inbox_mobile_card.dart';
// import './inbox_desktop_filters.dart';
// import './inbox_mobile_filters.dart';
// import './inbox_mobile_stats.dart';
// import './inbox_stats_widget.dart';
// import './inbox_empty_state.dart';
// import './inbox_header.dart';
//
// import '../request/Ditalis_Request/ditalis_request.dart';
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final InboxApi _apiService = InboxApi();
//   final TextEditingController _searchController = TextEditingController();
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     final userInfo = await _apiService.getUserInfo();
//     setState(() {
//       _userName = userInfo['userName'];
//       _userToken = userInfo['token'];
//     });
//
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//     }
//   }
//
//   Future<void> _fetchTypes() async {
//     try {
//       final types = await _apiService.fetchTypes(_userToken);
//       setState(() {
//         typeNames = types;
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _fetchInboxRequests() async {
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);
//
//       // Process requests in parallel
//       await Future.wait(
//         allRequests.map((req) async {
//           req['yourForwardStatus'] = await _apiService.getYourForwardStatusForRequest(
//             req, _userToken, _userName,
//           );
//           req['lastSenderName'] = await _apiService.getLastSenderNameForYou(
//             req, _userToken, _userName,
//           );
//           req['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
//             req, _userToken, _userName,
//           );
//         }),
//       );
//
//       setState(() {
//         _requests = allRequests;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests: $e";
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final filtered = InboxHelpers.applyFilters(
//       allRequests: _requests,
//       selectedType: _selectedType,
//       selectedPriority: _selectedPriority,
//       selectedStatus: _selectedStatus,
//       searchTerm: _searchController.text.toLowerCase(),
//     );
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor,
//       ) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       request["id"].toString(),
//       action,
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       setState(() {
//         request['yourForwardStatus'] = action.toLowerCase();
//         if (action == 'Approve') {
//           request['fulfilled'] = true;
//         }
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Transaction has been ${action.toLowerCase()}d successfully',
//           ),
//           backgroundColor: snackBarColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to perform action'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     final users = await _apiService.fetchUsers(_userToken);
//
//     if (users.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No users available to forward.')),
//       );
//       return;
//     }
//
//     String? selectedUser;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text("Select user to forward to (${users.length} users available)"),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) => setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedUser == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Please select a user.')),
//                       );
//                       return;
//                     }
//
//                     Navigator.pop(context);
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     final success = await _apiService.forwardTransaction(
//                       transactionId,
//                       selectedUser!,
//                       _userToken,
//                     );
//
//                     if (success) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Transaction forwarded successfully!'),
//                           backgroundColor: InboxColors.accentGreen,
//                         ),
//                       );
//
//                       setState(() {
//                         request['lastForwardSentTo'] = {
//                           'receiverName': selectedUser,
//                           'status': 'waiting',
//                         };
//                       });
//
//                       _applyFilters();
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Failed to forward transaction'),
//                           backgroundColor: InboxColors.accentRed,
//                         ),
//                       );
//                     }
//
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (forwardId == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);
//
//     if (success) {
//       setState(() {
//         request['lastForwardSentTo'] = null;
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Forward cancelled successfully'),
//           backgroundColor: InboxColors.accentGreen,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to cancel forward'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedPriority = 'All';
//       _selectedType = 'All Types';
//       _selectedStatus = 'All';
//       _searchController.clear();
//     });
//     _applyFilters();
//   }
//
//   void _viewDetails(String requestId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CourseApprovalRequestPage(requestId: requestId),
//       ),
//     );
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onSelected(option);
//                 },
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your inbox...',
//             style: TextStyle(
//               fontSize: 16,
//               color: InboxColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     // حساب الإحصائيات
//     final stats = {
//       'total': _requests.length,
//       'waiting': _requests.where((req) {
//         final userForwardStatus = req['yourForwardStatus'];
//         final fulfilled = req["fulfilled"] == true;
//         return (userForwardStatus != "approved" &&
//             userForwardStatus != "rejected" &&
//             !fulfilled) ||
//             (userForwardStatus == null && !fulfilled);
//       }).length,
//       'approved': _requests.where((req) => req['yourForwardStatus'] == "approved").length,
//       'rejected': _requests.where((req) => req['yourForwardStatus'] == "rejected").length,
//       'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
//     };
//
//     return Column(
//       children: [
//         // الإحصائيات المدمجة
//         if (_requests.isNotEmpty)
//           InboxMobileStats(
//             total: stats['total']!,
//             waiting: stats['waiting']!,
//             approved: stats['approved']!,
//             rejected: stats['rejected']!,
//             fulfilled: stats['fulfilled']!,
//           ),
//
//         // البحث والفلاتر
//         InboxMobileFilters(
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           searchController: _searchController,
//           onPriorityChanged: (value) {
//             setState(() => _selectedPriority = value);
//             _applyFilters();
//           },
//           onTypeChanged: (value) {
//             setState(() => _selectedType = value);
//             _applyFilters();
//           },
//           onStatusChanged: (value) {
//             setState(() => _selectedStatus = value);
//             _applyFilters();
//           },
//           onSearchChanged: (value) => _applyFilters(),
//           onShowMobileFilterDialog: _showMobileFilterDialog,
//         ),
//
//         // قائمة الطلبات
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: _filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = _filteredRequests[index];
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxMobileCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _performAction(req, 'Reject', InboxColors.accentRed),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           hasForwarded: hasForwarded,
//         );
//       },
//     );
//   }
//
//   Widget _buildDesktopBody() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // شريط الإحصائيات
//             InboxStatsWidget(requests: _requests),
//             const SizedBox(height: 16),
//
//             // البحث والفلاتر
//             InboxDesktopFilters(
//               selectedPriority: _selectedPriority,
//               selectedType: _selectedType,
//               selectedStatus: _selectedStatus,
//               priorities: priorities,
//               typeNames: typeNames,
//               statuses: statuses,
//               searchController: _searchController,
//               onPriorityChanged: (value) {
//                 setState(() => _selectedPriority = value);
//                 _applyFilters();
//               },
//               onTypeChanged: (value) {
//                 setState(() => _selectedType = value);
//                 _applyFilters();
//               },
//               onStatusChanged: (value) {
//                 setState(() => _selectedStatus = value);
//                 _applyFilters();
//               },
//               onSearchChanged: (value) => _applyFilters(),
//             ),
//             const SizedBox(height: 20),
//
//             // الهيدر
//             InboxHeader(
//               isMobile: false,
//               itemCount: _filteredRequests.length,
//             ),
//             const SizedBox(height: 16),
//
//             // قائمة الطلبات
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxDesktopCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _performAction(req, 'Reject', InboxColors.accentRed),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           hasForwarded: hasForwarded,
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
// }
//
// import 'dart:math';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// // استيراد الملفات الجديدة
// import '../request/editerequest.dart';
// import './inbox_colors.dart';
// import './inbox_api.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
// import './inbox_desktop_card.dart';
// import './inbox_mobile_card.dart';
// import './inbox_desktop_filters.dart';
// import './inbox_mobile_filters.dart';
// import './inbox_mobile_stats.dart';
// import './inbox_stats_widget.dart';
// import './inbox_empty_state.dart';
// import './inbox_header.dart';
//
// import '../request/Ditalis_Request/ditalis_request.dart';
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final InboxApi _apiService = InboxApi();
//   final TextEditingController _searchController = TextEditingController();
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//     'Needs Change',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     final userInfo = await _apiService.getUserInfo();
//     setState(() {
//       _userName = userInfo['userName'];
//       _userToken = userInfo['token'];
//     });
//
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//     }
//   }
//
//   Future<void> _fetchTypes() async {
//     try {
//       final types = await _apiService.fetchTypes(_userToken);
//       setState(() {
//         typeNames = types;
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _fetchInboxRequests() async {
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);
//
//       await Future.wait(
//         allRequests.map((req) async {
//           req['yourForwardStatus'] = await _apiService.getYourForwardStatusForRequest(
//             req, _userToken, _userName,
//           );
//           req['lastSenderName'] = await _apiService.getLastSenderNameForYou(
//             req, _userToken, _userName,
//           );
//           req['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
//             req, _userToken, _userName,
//           );
//         }),
//       );
//
//       setState(() {
//         _requests = allRequests;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests: $e";
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final filtered = InboxHelpers.applyFilters(
//       allRequests: _requests,
//       selectedType: _selectedType,
//       selectedPriority: _selectedPriority,
//       selectedStatus: _selectedStatus,
//       searchTerm: _searchController.text.toLowerCase(),
//     );
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor,
//       ) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       request["id"].toString(),
//       action,
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       setState(() {
//         request['yourForwardStatus'] = action.toLowerCase();
//         if (action == 'Approve') {
//           request['fulfilled'] = true;
//         }
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Transaction has been ${action.toLowerCase()}d successfully',
//           ),
//           backgroundColor: snackBarColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to perform action'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لطلب التعديل
//   Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
//     String comment = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Request Changes'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please specify what changes are needed:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter your comments here...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         comment = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: comment.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _sendNeedChangeRequest(request, comment);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                   child: const Text('Submit Changes Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة لإرسال طلب التعديل (ستضاف لاحقاً في الـ API)
//   Future<void> _sendNeedChangeRequest(
//       Map<String, dynamic> request, String comment) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     // TODO: سيتم إضافة الـ endpoint لاحقاً
//     bool success = true;
//
//     if (success) {
//       setState(() {
//         request['yourForwardStatus'] = 'needs_change';
//         request['changeComment'] = comment;
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Change request sent successfully'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to send change request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لسبب الرفض
//   Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
//     String reason = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Reject Request'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please provide a reason for rejection:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter rejection reason...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         reason = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: reason.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _rejectWithComment(request, reason);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: InboxColors.accentRed,
//                   ),
//                   child: const Text('Reject'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة للرفض مع التعليق (ستضاف لاحقاً في الـ API)
//   Future<void> _rejectWithComment(
//       Map<String, dynamic> request, String reason) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     // TODO: سيتم إضافة الـ endpoint لاحقاً
//     final success = await _apiService.performAction(
//       request["id"].toString(),
//       'Reject',
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       setState(() {
//         request['yourForwardStatus'] = 'rejected';
//         request['rejectionReason'] = reason;
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Request rejected with reason'),
//           backgroundColor: InboxColors.accentRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to reject request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة للتنقل إلى صفحة التعديل
//   void _navigateToEditRequest(Map<String, dynamic> request) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => EditRequestPage(
//           requestId: request["id"].toString(),
//         ),
//       ),
//     ).then((_) {
//       // بعد العودة، قم بتحديث قائمة الطلبات
//       _fetchInboxRequests();
//     });
//   }
//
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     final users = await _apiService.fetchUsers(_userToken);
//
//     if (users.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No users available to forward.')),
//       );
//       return;
//     }
//
//     String? selectedUser;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text("Select user to forward to (${users.length} users available)"),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) => setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedUser == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Please select a user.')),
//                       );
//                       return;
//                     }
//
//                     Navigator.pop(context);
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     final success = await _apiService.forwardTransaction(
//                       transactionId,
//                       selectedUser!,
//                       _userToken,
//                     );
//
//                     if (success) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Transaction forwarded successfully!'),
//                           backgroundColor: InboxColors.accentGreen,
//                         ),
//                       );
//
//                       setState(() {
//                         request['lastForwardSentTo'] = {
//                           'receiverName': selectedUser,
//                           'status': 'waiting',
//                         };
//                       });
//
//                       _applyFilters();
//
//                       // 🔥 الحل الجديد: إعادة جلب البيانات الحقيقية
//                       try {
//                         final forwardData = await _apiService.getLastForwardSentByYou(
//                             request,
//                             _userToken,
//                             _userName
//                         );
//
//                         if (forwardData != null) {
//                           setState(() {
//                             request['lastForwardSentTo'] = forwardData;
//                           });
//                           _applyFilters();
//                         }
//                       } catch (e) {
//                         debugPrint('❌ Error fetching forward data: $e');
//                       }
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Failed to forward transaction'),
//                           backgroundColor: InboxColors.accentRed,
//                         ),
//                       );
//                     }
//
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (forwardId == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);
//
//     if (success) {
//       setState(() {
//         request['lastForwardSentTo'] = null;
//       });
//
//       _applyFilters();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Forward cancelled successfully'),
//           backgroundColor: InboxColors.accentGreen,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to cancel forward'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedPriority = 'All';
//       _selectedType = 'All Types';
//       _selectedStatus = 'All';
//       _searchController.clear();
//     });
//     _applyFilters();
//   }
//
//   void _viewDetails(String requestId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CourseApprovalRequestPage(requestId: requestId),
//       ),
//     );
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onSelected(option);
//                 },
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Loading your inbox...',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: InboxColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     final stats = {
//       'total': _requests.length,
//       'waiting': _requests.where((req) {
//         final userForwardStatus = req['yourForwardStatus'];
//         final fulfilled = req["fulfilled"] == true;
//         return (userForwardStatus != "approved" &&
//             userForwardStatus != "rejected" &&
//             userForwardStatus != "needs_change" &&
//             !fulfilled) ||
//             (userForwardStatus == null && !fulfilled);
//       }).length,
//       'approved': _requests.where((req) => req['yourForwardStatus'] == "approved").length,
//       'rejected': _requests.where((req) => req['yourForwardStatus'] == "rejected").length,
//       'needs_change': _requests.where((req) => req['yourForwardStatus'] == "needs_change").length,
//       'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
//     };
//
//     return Column(
//       children: [
//         if (_requests.isNotEmpty)
//           InboxMobileStats(
//             total: stats['total']!,
//             waiting: stats['waiting']!,
//             approved: stats['approved']!,
//             rejected: stats['rejected']!,
//             fulfilled: stats['fulfilled']!,
//           ),
//
//         InboxMobileFilters(
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           searchController: _searchController,
//           onPriorityChanged: (value) {
//             setState(() => _selectedPriority = value);
//             _applyFilters();
//           },
//           onTypeChanged: (value) {
//             setState(() => _selectedType = value);
//             _applyFilters();
//           },
//           onStatusChanged: (value) {
//             setState(() => _selectedStatus = value);
//             _applyFilters();
//           },
//           onSearchChanged: (value) => _applyFilters(),
//           onShowMobileFilterDialog: _showMobileFilterDialog,
//         ),
//
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: _filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = _filteredRequests[index];
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxMobileCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _showRejectWithCommentDialog(req),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           onNeedChange: () => _showNeedChangeDialog(req),
//           onEditRequest: () => _navigateToEditRequest(req),
//           hasForwarded: hasForwarded,
//         );
//       },
//     );
//   }
//
//   Widget _buildDesktopBody() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             InboxStatsWidget(requests: _requests),
//             const SizedBox(height: 16),
//
//             InboxDesktopFilters(
//               selectedPriority: _selectedPriority,
//               selectedType: _selectedType,
//               selectedStatus: _selectedStatus,
//               priorities: priorities,
//               typeNames: typeNames,
//               statuses: statuses,
//               searchController: _searchController,
//               onPriorityChanged: (value) {
//                 setState(() => _selectedPriority = value);
//                 _applyFilters();
//               },
//               onTypeChanged: (value) {
//                 setState(() => _selectedType = value);
//                 _applyFilters();
//               },
//               onStatusChanged: (value) {
//                 setState(() => _selectedStatus = value);
//                 _applyFilters();
//               },
//               onSearchChanged: (value) => _applyFilters(),
//             ),
//             const SizedBox(height: 20),
//
//             InboxHeader(
//               isMobile: false,
//               itemCount: _filteredRequests.length,
//             ),
//             const SizedBox(height: 16),
//
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxDesktopCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _showRejectWithCommentDialog(req),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           onNeedChange: () => _showNeedChangeDialog(req),
//           onEditRequest: () => _navigateToEditRequest(req),
//           hasForwarded: hasForwarded,
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
// }

//
// import 'dart:math';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// // استيراد الملفات الجديدة
// import '../request/editerequest.dart';
// import './inbox_colors.dart';
// import './inbox_api.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
// import './inbox_desktop_card.dart';
// import './inbox_mobile_card.dart';
// import './inbox_desktop_filters.dart';
// import './inbox_mobile_filters.dart';
// import './inbox_mobile_stats.dart';
// import './inbox_stats_widget.dart';
// import './inbox_empty_state.dart';
// import './inbox_header.dart';
//
// import '../request/Ditalis_Request/ditalis_request.dart';
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final InboxApi _apiService = InboxApi();
//   final TextEditingController _searchController = TextEditingController();
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//     'Needs Change',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     final userInfo = await _apiService.getUserInfo();
//     setState(() {
//       _userName = userInfo['userName'];
//       _userToken = userInfo['token'];
//     });
//
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//     }
//   }
//
//   Future<void> _fetchTypes() async {
//     try {
//       final types = await _apiService.fetchTypes(_userToken);
//       setState(() {
//         typeNames = types;
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _fetchInboxRequests() async {
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);
//
//       await Future.wait(
//         allRequests.map((req) async {
//           req['yourCurrentStatus'] = await _apiService.getYourForwardStatusForRequest(
//             req, _userToken, _userName,
//           );
//           req['lastSenderName'] = await _apiService.getLastSenderNameForYou(
//             req, _userToken, _userName,
//           );
//           req['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
//             req, _userToken, _userName,
//           );
//         }),
//       );
//
//       setState(() {
//         _requests = allRequests;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests: $e";
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final filtered = InboxHelpers.applyFilters(
//       allRequests: _requests,
//       selectedType: _selectedType,
//       selectedPriority: _selectedPriority,
//       selectedStatus: _selectedStatus,
//       searchTerm: _searchController.text.toLowerCase(),
//     );
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor,
//       ) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       request["id"].toString(),
//       action,
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       // 🔥 الحل: إعادة جلب البيانات الحقيقية من السيرفر
//       await _fetchInboxRequests();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Transaction has been ${action.toLowerCase()}d successfully',
//           ),
//           backgroundColor: snackBarColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to perform action'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لطلب التعديل
//   Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
//     String comment = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Request Changes'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please specify what changes are needed:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter your comments here...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         comment = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: comment.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _sendNeedChangeRequest(request, comment);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                   child: const Text('Submit Changes Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة لإرسال طلب التعديل
//   Future<void> _sendNeedChangeRequest(
//       Map<String, dynamic> request, String comment) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     // TODO: سيتم إضافة الـ endpoint لاحقاً
//     bool success = true;
//
//     if (success) {
//       // 🔥 الحل: إعادة جلب البيانات الحقيقية من السيرفر
//       await _fetchInboxRequests();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Change request sent successfully'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to send change request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لسبب الرفض
//   Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
//     String reason = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Reject Request'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please provide a reason for rejection:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter rejection reason...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         reason = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: reason.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _rejectWithComment(request, reason);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: InboxColors.accentRed,
//                   ),
//                   child: const Text('Reject'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة للرفض مع التعليق
//   Future<void> _rejectWithComment(
//       Map<String, dynamic> request, String reason) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       request["id"].toString(),
//       'Reject',
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       // 🔥 الحل: إعادة جلب البيانات الحقيقية من السيرفر
//       await _fetchInboxRequests();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Request rejected with reason'),
//           backgroundColor: InboxColors.accentRed,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to reject request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة للتنقل إلى صفحة التعديل
//   void _navigateToEditRequest(Map<String, dynamic> request) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => EditRequestPage(
//           requestId: request["id"].toString(),
//         ),
//       ),
//     ).then((_) {
//       // بعد العودة، قم بتحديث قائمة الطلبات
//       _fetchInboxRequests();
//     });
//   }
//
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     final users = await _apiService.fetchUsers(_userToken);
//
//     if (users.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No users available to forward.')),
//       );
//       return;
//     }
//
//     String? selectedUser;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text("Select user to forward to (${users.length} users available)"),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) => setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (selectedUser == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Please select a user.')),
//                       );
//                       return;
//                     }
//
//                     Navigator.pop(context);
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     final success = await _apiService.forwardTransaction(
//                       transactionId,
//                       selectedUser!,
//                       _userToken,
//                     );
//
//                     if (success) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Transaction forwarded successfully!'),
//                           backgroundColor: InboxColors.accentGreen,
//                         ),
//                       );
//
//                       // 🔥 الحل: إعادة جلب البيانات الحقيقية من السيرفر
//                       await _fetchInboxRequests();
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Failed to forward transaction'),
//                           backgroundColor: InboxColors.accentRed,
//                         ),
//                       );
//                     }
//
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (forwardId == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);
//
//     if (success) {
//       // 🔥 الحل: إعادة جلب البيانات الحقيقية من السيرفر
//       await _fetchInboxRequests();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Forward cancelled successfully'),
//           backgroundColor: InboxColors.accentGreen,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to cancel forward'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedPriority = 'All';
//       _selectedType = 'All Types';
//       _selectedStatus = 'All';
//       _searchController.clear();
//     });
//     _applyFilters();
//   }
//
//   void _viewDetails(String requestId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CourseApprovalRequestPage(requestId: requestId),
//       ),
//     );
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onSelected(option);
//                 },
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your inbox...',
//             style: TextStyle(
//               fontSize: 16,
//               color: InboxColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     final stats = {
//       'total': _requests.length,
//       'waiting': _requests.where((req) {
//         final userForwardStatus = req['yourForwardStatus'];
//         final fulfilled = req["fulfilled"] == true;
//         return (userForwardStatus != "approved" &&
//             userForwardStatus != "rejected" &&
//             userForwardStatus != "needs_change" &&
//             !fulfilled) ||
//             (userForwardStatus == null && !fulfilled);
//       }).length,
//       'approved': _requests.where((req) => req['yourForwardStatus'] == "approved").length,
//       'rejected': _requests.where((req) => req['yourForwardStatus'] == "rejected").length,
//       'needs_change': _requests.where((req) => req['yourForwardStatus'] == "needs_change").length,
//       'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
//     };
//
//     return Column(
//       children: [
//         if (_requests.isNotEmpty)
//           InboxMobileStats(
//             total: stats['total']!,
//             waiting: stats['waiting']!,
//             approved: stats['approved']!,
//             rejected: stats['rejected']!,
//             fulfilled: stats['fulfilled']!,
//           ),
//
//         InboxMobileFilters(
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           searchController: _searchController,
//           onPriorityChanged: (value) {
//             setState(() => _selectedPriority = value);
//             _applyFilters();
//           },
//           onTypeChanged: (value) {
//             setState(() => _selectedType = value);
//             _applyFilters();
//           },
//           onStatusChanged: (value) {
//             setState(() => _selectedStatus = value);
//             _applyFilters();
//           },
//           onSearchChanged: (value) => _applyFilters(),
//           onShowMobileFilterDialog: _showMobileFilterDialog,
//         ),
//
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: _filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = _filteredRequests[index];
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxMobileCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _showRejectWithCommentDialog(req),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           onNeedChange: () => _showNeedChangeDialog(req),
//           onEditRequest: () => _navigateToEditRequest(req),
//           hasForwarded: hasForwarded,
//         );
//       },
//     );
//   }
//
//   Widget _buildDesktopBody() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             InboxStatsWidget(requests: _requests),
//             const SizedBox(height: 16),
//
//             InboxDesktopFilters(
//               selectedPriority: _selectedPriority,
//               selectedType: _selectedType,
//               selectedStatus: _selectedStatus,
//               priorities: priorities,
//               typeNames: typeNames,
//               statuses: statuses,
//               searchController: _searchController,
//               onPriorityChanged: (value) {
//                 setState(() => _selectedPriority = value);
//                 _applyFilters();
//               },
//               onTypeChanged: (value) {
//                 setState(() => _selectedType = value);
//                 _applyFilters();
//               },
//               onStatusChanged: (value) {
//                 setState(() => _selectedStatus = value);
//                 _applyFilters();
//               },
//               onSearchChanged: (value) => _applyFilters(),
//             ),
//             const SizedBox(height: 20),
//
//             InboxHeader(
//               isMobile: false,
//               itemCount: _filteredRequests.length,
//             ),
//             const SizedBox(height: 16),
//
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//
//         return InboxDesktopCard(
//           request: req,
//           onViewDetails: () => _viewDetails(req["id"].toString()),
//           onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//           onReject: () => _showRejectWithCommentDialog(req),
//           onForward: () => _forwardTransaction(req["id"].toString(), req),
//           onCancelForward: () => _cancelForward(
//             req["id"].toString(),
//             lastForwardSentTo?['id'],
//             req,
//           ),
//           onNeedChange: () => _showNeedChangeDialog(req),
//           onEditRequest: () => _navigateToEditRequest(req),
//           hasForwarded: hasForwarded,
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
// }
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// // استيراد الملفات الجديدة
// import '../request/editerequest.dart';
// import './inbox_colors.dart';
// import './inbox_api.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
// import './inbox_desktop_card.dart';
// import './inbox_mobile_card.dart';
// import './inbox_desktop_filters.dart';
// import './inbox_mobile_filters.dart';
// import './inbox_mobile_stats.dart';
// import './inbox_stats_widget.dart';
// import './inbox_empty_state.dart';
// import './inbox_header.dart';
// import '../request/Ditalis_Request/ditalis_request.dart';
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final InboxApi _apiService = InboxApi();
//   final TextEditingController _searchController = TextEditingController();
//   Timer? _searchTimer;
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//     'Needs Change',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   @override
//   void dispose() {
//     _searchTimer?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _initializeData() async {
//     print('🔄 Initializing InboxPage...');
//
//     final userInfo = await _apiService.getUserInfo();
//     setState(() {
//       _userName = userInfo['userName'];
//       _userToken = userInfo['token'];
//     });
//
//     print('👤 User Info - Name: $_userName, Token: ${_userToken != null ? "Exists" : "NULL"}');
//
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//       print('❌ User info missing: $_errorMessage');
//     }
//   }
//
//   Future<void> _fetchTypes() async {
//     try {
//       final types = await _apiService.fetchTypes(_userToken);
//       setState(() {
//         typeNames = ['All Types', ...types.where((type) => type != 'All Types')];
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _fetchInboxRequests() async {
//     if (_isRefreshing) {
//       print('⏸️ fetchInboxRequests already in progress');
//       return;
//     }
//
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       print('❌ Missing token or userName');
//       return;
//     }
//
//     print('🔄 fetchInboxRequests started');
//
//     setState(() {
//       _isLoading = true;
//       _isRefreshing = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);
//
//       // تحديث البيانات المساعدة لكل طلب
//       final updatedRequests = <dynamic>[];
//       for (var req in allRequests) {
//         try {
//           final request = Map<String, dynamic>.from(req);
//
//           // جلب البيانات الإضافية
//           request['yourCurrentStatus'] = await _apiService.getYourForwardStatusForRequest(
//             request, _userToken, _userName,
//           );
//
//           request['lastSenderName'] = await _apiService.getLastSenderNameForYou(
//             request, _userToken, _userName,
//           );
//
//           request['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
//             request, _userToken, _userName,
//           );
//
//           updatedRequests.add(request);
//         } catch (e) {
//           print('⚠️ Error processing request ${req['id']}: $e');
//           updatedRequests.add(req);
//         }
//       }
//
//       setState(() {
//         _requests = updatedRequests;
//         _applyFilters();
//         _isLoading = false;
//         _isRefreshing = false;
//       });
//
//       print('✅ fetchInboxRequests completed - ${_requests.length} requests');
//
//     } catch (e) {
//       print("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _isRefreshing = false;
//         _errorMessage = "Failed to load requests: ${e.toString()}";
//       });
//
//       // إظهار رسالة خطأ للمستخدم
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Network error: ${e.toString()}'),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final filtered = InboxHelpers.applyFilters(
//       allRequests: _requests,
//       selectedType: _selectedType,
//       selectedPriority: _selectedPriority,
//       selectedStatus: _selectedStatus,
//       searchTerm: _searchController.text.toLowerCase(),
//     );
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//
//     print('🔍 Filters applied - Showing ${_filteredRequests.length} of ${_requests.length} requests');
//   }
//
//   void _onSearchChanged(String value) {
//     // استخدام debounce لمنع تحديث الفلاتر مع كل حرف
//     _searchTimer?.cancel();
//     _searchTimer = Timer(const Duration(milliseconds: 300), () {
//       _applyFilters();
//     });
//   }
//
//   // 🔹 دالة لتحديث حالة طلب محدد في القائمة
//   void _updateRequestInList(String requestId, Map<String, dynamic> updates) {
//     final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
//     if (index != -1) {
//       setState(() {
//         // تحديث الطلب الموجود
//         final updatedRequest = Map<String, dynamic>.from(_requests[index]);
//         updatedRequest.addAll(updates);
//         _requests[index] = updatedRequest;
//
//         // تطبيق الفلاتر مجدداً
//         _applyFilters();
//       });
//       print('✅ Updated request $requestId in UI');
//     } else {
//       print('⚠️ Request $requestId not found in list');
//     }
//   }
//
//   // 🔹 إعادة حساب البيانات المساعدة للطلب
//   Future<void> _recalculateRequestData(String requestId) async {
//     final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
//     if (index == -1) return;
//
//     try {
//       final request = _requests[index];
//
//       // تحديث حالة الـ forward للمستخدم الحالي
//       final newStatus = await _apiService.getYourForwardStatusForRequest(
//         request, _userToken, _userName,
//       );
//
//       // تحديث اسم المرسل
//       final lastSender = await _apiService.getLastSenderNameForYou(
//         request, _userToken, _userName,
//       );
//
//       // تحديث معلومات الـ forward الأخير
//       final lastForward = await _apiService.getLastForwardSentByYou(
//         request, _userToken, _userName,
//       );
//
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': newStatus,
//         'lastSenderName': lastSender,
//         'lastForwardSentTo': lastForward,
//       });
//
//       print('✅ Recalculated data for request $requestId');
//     } catch (e) {
//       print('⚠️ Error recalculating request data for $requestId: $e');
//     }
//   }
//
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor,
//       ) async {
//     if (_isLoading) return;
//
//     final requestId = request["id"].toString();
//     final actionLower = action.toLowerCase();
//
//     print('🎯 Performing $action on request $requestId');
//
//     // تحديث حالة الطلب فوراً في الـ UI (قبل استجابة السيرفر)
//     _updateRequestInList(requestId, {
//       'yourCurrentStatus': actionLower,
//       'isUpdating': true, // علامة للتحديث
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       requestId,
//       action,
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية من السيرفر بعد 500 مللي ثانية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Transaction has been ${actionLower}d successfully',
//           ),
//           backgroundColor: snackBarColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//
//       print('✅ $action successful for request $requestId');
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': request['yourCurrentStatus'],
//         'isUpdating': null,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to perform action'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//
//       print('❌ $action failed for request $requestId');
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لطلب التعديل
//   Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
//     String comment = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Request Changes'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please specify what changes are needed:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter your comments here...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         comment = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: comment.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _sendNeedChangeRequest(request, comment);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                   child: const Text('Submit Changes Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة لإرسال طلب التعديل
//   Future<void> _sendNeedChangeRequest(
//       Map<String, dynamic> request, String comment) async {
//     final requestId = request["id"].toString();
//
//     // تحديث حالة الطلب فوراً في الـ UI
//     _updateRequestInList(requestId, {
//       'yourCurrentStatus': 'needs_change',
//       'isUpdating': true,
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     // TODO: سيتم إضافة الـ endpoint لاحقاً
//     bool success = true;
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Change request sent successfully'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': request['yourCurrentStatus'],
//         'isUpdating': null,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to send change request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لسبب الرفض
//   Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
//     String reason = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Reject Request'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please provide a reason for rejection:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter rejection reason...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         reason = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: reason.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _rejectWithComment(request, reason);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: InboxColors.accentRed,
//                   ),
//                   child: const Text('Reject'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة للرفض مع التعليق
//   Future<void> _rejectWithComment(
//       Map<String, dynamic> request, String reason) async {
//     await _performAction(request, 'Reject', InboxColors.accentRed);
//   }
//
//   // 🔹 دالة للتنقل إلى صفحة التعديل
//   void _navigateToEditRequest(Map<String, dynamic> request) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => EditRequestPage(
//           requestId: request["id"].toString(),
//         ),
//       ),
//     ).then((_) {
//       // بعد العودة، قم بتحديث قائمة الطلبات
//       _fetchInboxRequests();
//     });
//   }
//
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     final users = await _apiService.fetchUsers(_userToken);
//
//     if (users.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No users available to forward.')),
//       );
//       return;
//     }
//
//     String? selectedUser;
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text("Select user to forward to (${users.length} users available)"),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) => setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: selectedUser == null ? null : () async {
//                     Navigator.pop(context);
//
//                     final requestId = transactionId;
//
//                     // تحديث حالة الطلب فوراً في الـ UI
//                     _updateRequestInList(requestId, {
//                       'isUpdating': true,
//                       'lastForwardSentTo': {
//                         'receiverName': selectedUser,
//                         'status': 'pending',
//                       },
//                     });
//
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     final success = await _apiService.forwardTransaction(
//                       transactionId,
//                       selectedUser!,
//                       _userToken,
//                     );
//
//                     if (success) {
//                       // إزالة علامة التحديث
//                       _updateRequestInList(requestId, {'isUpdating': null});
//
//                       // إعادة جلب البيانات الحقيقية
//                       Future.delayed(const Duration(milliseconds: 500), () {
//                         _recalculateRequestData(requestId);
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Transaction forwarded successfully!'),
//                           backgroundColor: InboxColors.accentGreen,
//                         ),
//                       );
//                     } else {
//                       // في حالة الفشل، إرجاع الحالة الأصلية
//                       _updateRequestInList(requestId, {
//                         'isUpdating': null,
//                         'lastForwardSentTo': request['lastForwardSentTo'],
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Failed to forward transaction'),
//                           backgroundColor: InboxColors.accentRed,
//                         ),
//                       );
//                     }
//
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (forwardId == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     final requestId = transactionId;
//
//     // تحديث حالة الطلب فوراً في الـ UI
//     _updateRequestInList(requestId, {
//       'isUpdating': true,
//       'lastForwardSentTo': null,
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Forward cancelled successfully'),
//           backgroundColor: InboxColors.accentGreen,
//         ),
//       );
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'isUpdating': null,
//         'lastForwardSentTo': request['lastForwardSentTo'],
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to cancel forward'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedPriority = 'All';
//       _selectedType = 'All Types';
//       _selectedStatus = 'All';
//       _searchController.clear();
//     });
//     _applyFilters();
//   }
//
//   void _viewDetails(String requestId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CourseApprovalRequestPage(requestId: requestId),
//       ),
//     );
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onSelected(option);
//                 },
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your inbox...',
//             style: TextStyle(
//               fontSize: 16,
//               color: InboxColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: InboxColors.accentRed,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Error Loading Requests',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: InboxColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _errorMessage ?? 'Unknown error occurred',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: InboxColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: _fetchInboxRequests,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: InboxColors.primary,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     if (_errorMessage != null && _requests.isEmpty) {
//       return _buildErrorState();
//     }
//
//     final stats = {
//       'total': _requests.length,
//       'waiting': _requests.where((req) {
//         final userForwardStatus = req['yourCurrentStatus'];
//         final fulfilled = req["fulfilled"] == true;
//         return (userForwardStatus != "approved" &&
//             userForwardStatus != "rejected" &&
//             userForwardStatus != "needs_change" &&
//             !fulfilled) ||
//             (userForwardStatus == null && !fulfilled);
//       }).length,
//       'approved': _requests.where((req) => req['yourCurrentStatus'] == "approved").length,
//       'rejected': _requests.where((req) => req['yourCurrentStatus'] == "rejected").length,
//       'needs_change': _requests.where((req) => req['yourCurrentStatus'] == "needs_change").length,
//       'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
//     };
//
//     return Column(
//       children: [
//         if (_requests.isNotEmpty)
//           InboxMobileStats(
//             total: stats['total']!,
//             waiting: stats['waiting']!,
//             approved: stats['approved']!,
//             rejected: stats['rejected']!,
//             fulfilled: stats['fulfilled']!,
//           ),
//
//         InboxMobileFilters(
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           searchController: _searchController,
//           onPriorityChanged: (value) {
//             setState(() => _selectedPriority = value);
//             _applyFilters();
//           },
//           onTypeChanged: (value) {
//             setState(() => _selectedType = value);
//             _applyFilters();
//           },
//           onStatusChanged: (value) {
//             setState(() => _selectedStatus = value);
//             _applyFilters();
//           },
//           onSearchChanged: _onSearchChanged,
//           onShowMobileFilterDialog: _showMobileFilterDialog,
//         ),
//
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return RefreshIndicator(
//       onRefresh: _fetchInboxRequests,
//       color: InboxColors.primary,
//       child: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         itemCount: _filteredRequests.length,
//         itemBuilder: (context, index) {
//           final req = _filteredRequests[index];
//           final hasForwarded = req['lastForwardSentTo'] != null;
//           final lastForwardSentTo = req['lastForwardSentTo'];
//           final isUpdating = req['isUpdating'] == true;
//
//           return Opacity(
//             opacity: isUpdating ? 0.7 : 1.0,
//             child: InboxMobileCard(
//               request: req,
//               onViewDetails: () => _viewDetails(req["id"].toString()),
//               onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//               onReject: () => _showRejectWithCommentDialog(req),
//               onForward: () => _forwardTransaction(req["id"].toString(), req),
//               onCancelForward: () => _cancelForward(
//                 req["id"].toString(),
//                 lastForwardSentTo?['id'],
//                 req,
//               ),
//               onNeedChange: () => _showNeedChangeDialog(req),
//               onEditRequest: () => _navigateToEditRequest(req),
//               hasForwarded: hasForwarded,
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDesktopBody() {
//     if (_errorMessage != null && _requests.isEmpty) {
//       return _buildErrorState();
//     }
//
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (_requests.isNotEmpty) InboxStatsWidget(requests: _requests),
//             const SizedBox(height: 16),
//
//             InboxDesktopFilters(
//               selectedPriority: _selectedPriority,
//               selectedType: _selectedType,
//               selectedStatus: _selectedStatus,
//               priorities: priorities,
//               typeNames: typeNames,
//               statuses: statuses,
//               searchController: _searchController,
//               onPriorityChanged: (value) {
//                 setState(() => _selectedPriority = value);
//                 _applyFilters();
//               },
//               onTypeChanged: (value) {
//                 setState(() => _selectedType = value);
//                 _applyFilters();
//               },
//               onStatusChanged: (value) {
//                 setState(() => _selectedStatus = value);
//                 _applyFilters();
//               },
//               onSearchChanged: _onSearchChanged,
//             ),
//             const SizedBox(height: 20),
//
//             InboxHeader(
//               isMobile: false,
//               itemCount: _filteredRequests.length,
//             ),
//             const SizedBox(height: 16),
//
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//         final isUpdating = req['isUpdating'] == true;
//
//         return Opacity(
//           opacity: isUpdating ? 0.7 : 1.0,
//           child: InboxDesktopCard(
//             request: req,
//             onViewDetails: () => _viewDetails(req["id"].toString()),
//             onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//             onReject: () => _showRejectWithCommentDialog(req),
//             onForward: () => _forwardTransaction(req["id"].toString(), req),
//             onCancelForward: () => _cancelForward(
//               req["id"].toString(),
//               lastForwardSentTo?['id'],
//               req,
//             ),
//             onNeedChange: () => _showNeedChangeDialog(req),
//             onEditRequest: () => _navigateToEditRequest(req),
//             hasForwarded: hasForwarded,
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//           if (_isLoading || _isRefreshing)
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(InboxColors.sidebarText),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
// }

//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// // استيراد الملفات الجديدة
// import '../request/editerequest.dart';
// import './inbox_colors.dart';
// import './inbox_api.dart';
// import './inbox_helpers.dart';
// import './inbox_formatters.dart';
// import './inbox_desktop_card.dart';
// import './inbox_mobile_card.dart';
// import './inbox_desktop_filters.dart';
// import './inbox_mobile_filters.dart';
// import './inbox_mobile_stats.dart';
// import './inbox_stats_widget.dart';
// import './inbox_empty_state.dart';
// import './inbox_header.dart';
// import '../request/Ditalis_Request/ditalis_request.dart';
//
// class InboxPage extends StatefulWidget {
//   const InboxPage({super.key});
//
//   @override
//   State<InboxPage> createState() => _InboxPageState();
// }
//
// class _InboxPageState extends State<InboxPage> {
//   final InboxApi _apiService = InboxApi();
//   final TextEditingController _searchController = TextEditingController();
//   Timer? _searchTimer;
//
//   List<dynamic> _requests = [];
//   List<dynamic> _filteredRequests = [];
//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   String? _errorMessage;
//   String? _userName;
//   String? _userToken;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   String _selectedType = "All Types";
//   String _selectedPriority = "All";
//
//   // أنواع الطلبات
//   List<String> typeNames = ['All Types'];
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> statuses = [
//     'All',
//     'Waiting',
//     'Approved',
//     'Rejected',
//     'Fulfilled',
//     'Needs Change',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   @override
//   void dispose() {
//     _searchTimer?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _initializeData() async {
//     print('🔄 Initializing InboxPage...');
//
//     final userInfo = await _apiService.getUserInfo();
//     setState(() {
//       _userName = userInfo['userName'];
//       _userToken = userInfo['token'];
//     });
//
//     print('👤 User Info - Name: $_userName, Token: ${_userToken != null ? "Exists" : "NULL"}');
//
//     if (_userName != null && _userToken != null) {
//       await _fetchTypes();
//       await _fetchInboxRequests();
//     } else {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Unable to load user information. Please login again.";
//       });
//       print('❌ User info missing: $_errorMessage');
//     }
//   }
//
//   Future<void> _fetchTypes() async {
//     try {
//       final types = await _apiService.fetchTypes(_userToken);
//       setState(() {
//         typeNames = ['All Types', ...types.where((type) => type != 'All Types')];
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _fetchInboxRequests() async {
//     if (_isRefreshing) {
//       print('⏸️ fetchInboxRequests already in progress');
//       return;
//     }
//
//     if (_userToken == null || _userName == null) {
//       setState(() {
//         _errorMessage = "Please login first";
//         _isLoading = false;
//       });
//       print('❌ Missing token or userName');
//       return;
//     }
//
//     print('🔄 fetchInboxRequests started');
//
//     setState(() {
//       _isLoading = true;
//       _isRefreshing = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);
//
//       // تحديث البيانات المساعدة لكل طلب
//       final updatedRequests = <dynamic>[];
//       for (var req in allRequests) {
//         try {
//           final request = Map<String, dynamic>.from(req);
//
//           // جلب البيانات الإضافية
//           request['yourCurrentStatus'] = await _apiService.getYourForwardStatusForRequest(
//             request, _userToken, _userName,
//           );
//
//           request['lastSenderName'] = await _apiService.getLastSenderNameForYou(
//             request, _userToken, _userName,
//           );
//
//           request['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
//             request, _userToken, _userName,
//           );
//
//           updatedRequests.add(request);
//         } catch (e) {
//           print('⚠️ Error processing request ${req['id']}: $e');
//           updatedRequests.add(req);
//         }
//       }
//
//       setState(() {
//         _requests = updatedRequests;
//         _applyFilters();
//         _isLoading = false;
//         _isRefreshing = false;
//       });
//
//       print('✅ fetchInboxRequests completed - ${_requests.length} requests');
//
//     } catch (e) {
//       print("❌ Network error: $e");
//       setState(() {
//         _isLoading = false;
//         _isRefreshing = false;
//         _errorMessage = "Failed to load requests: ${e.toString()}";
//       });
//
//       // إظهار رسالة خطأ للمستخدم
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Network error: ${e.toString()}'),
//               backgroundColor: InboxColors.accentRed,
//             ),
//           );
//         }
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final filtered = InboxHelpers.applyFilters(
//       allRequests: _requests,
//       selectedType: _selectedType,
//       selectedPriority: _selectedPriority,
//       selectedStatus: _selectedStatus,
//       searchTerm: _searchController.text.toLowerCase(),
//     );
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//
//     print('🔍 Filters applied - Showing ${_filteredRequests.length} of ${_requests.length} requests');
//   }
//
//   void _onSearchChanged(String value) {
//     // استخدام debounce لمنع تحديث الفلاتر مع كل حرف
//     _searchTimer?.cancel();
//     _searchTimer = Timer(const Duration(milliseconds: 300), () {
//       _applyFilters();
//     });
//   }
//
//   // 🔹 دالة لتحديث حالة طلب محدد في القائمة
//   void _updateRequestInList(String requestId, Map<String, dynamic> updates) {
//     final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
//     if (index != -1) {
//       setState(() {
//         // تحديث الطلب الموجود
//         final updatedRequest = Map<String, dynamic>.from(_requests[index]);
//         updatedRequest.addAll(updates);
//         _requests[index] = updatedRequest;
//
//         // تطبيق الفلاتر مجدداً
//         _applyFilters();
//       });
//       print('✅ Updated request $requestId in UI');
//     } else {
//       print('⚠️ Request $requestId not found in list');
//     }
//   }
//
//   // 🔹 إعادة حساب البيانات المساعدة للطلب
//   Future<void> _recalculateRequestData(String requestId) async {
//     final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
//     if (index == -1) return;
//
//     try {
//       final request = _requests[index];
//
//       // تحديث حالة الـ forward للمستخدم الحالي
//       final newStatus = await _apiService.getYourForwardStatusForRequest(
//         request, _userToken, _userName,
//       );
//
//       // تحديث اسم المرسل
//       final lastSender = await _apiService.getLastSenderNameForYou(
//         request, _userToken, _userName,
//       );
//
//       // تحديث معلومات الـ forward الأخير
//       final lastForward = await _apiService.getLastForwardSentByYou(
//         request, _userToken, _userName,
//       );
//
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': newStatus,
//         'lastSenderName': lastSender,
//         'lastForwardSentTo': lastForward,
//       });
//
//       print('✅ Recalculated data for request $requestId');
//     } catch (e) {
//       print('⚠️ Error recalculating request data for $requestId: $e');
//     }
//   }
//
//   Future<void> _performAction(
//       Map<String, dynamic> request,
//       String action,
//       Color snackBarColor,
//       ) async {
//     if (_isLoading) return;
//
//     final requestId = request["id"].toString();
//     final actionLower = action.toLowerCase();
//
//     print('🎯 Performing $action on request $requestId');
//
//     // تحديث حالة الطلب فوراً في الـ UI (قبل استجابة السيرفر)
//     _updateRequestInList(requestId, {
//       'yourCurrentStatus': actionLower,
//       'isUpdating': true, // علامة للتحديث
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.performAction(
//       requestId,
//       action,
//       _userToken,
//       _userName,
//     );
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية من السيرفر بعد 500 مللي ثانية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Transaction has been ${actionLower}d successfully',
//           ),
//           backgroundColor: snackBarColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//
//       print('✅ $action successful for request $requestId');
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': request['yourCurrentStatus'],
//         'isUpdating': null,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to perform action'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//
//       print('❌ $action failed for request $requestId');
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لطلب التعديل
//   Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Request Changes'),
//           content: const Text('Are you sure you want to request changes for this request?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//               ),
//               child: const Text('Request Changes'),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     String comment = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Specify Changes'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please specify what changes are needed:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter your comments here...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         comment = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: comment.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _sendNeedChangeRequest(request, comment);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                   child: const Text('Submit Changes Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة لإرسال طلب التعديل
//   Future<void> _sendNeedChangeRequest(
//       Map<String, dynamic> request, String comment) async {
//     final requestId = request["id"].toString();
//
//     // تحديث حالة الطلب فوراً في الـ UI
//     _updateRequestInList(requestId, {
//       'yourCurrentStatus': 'needs_change',
//       'isUpdating': true,
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     // TODO: سيتم إضافة الـ endpoint لاحقاً
//     bool success = true;
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Change request sent successfully'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'yourCurrentStatus': request['yourCurrentStatus'],
//         'isUpdating': null,
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to send change request'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   // 🔹 دالة لإظهار dialog لسبب الرفض
//   Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
//     String reason = '';
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Reject Request'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('Please provide a reason for rejection:'),
//                   const SizedBox(height: 16),
//                   TextField(
//                     maxLines: 4,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter rejection reason...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         reason = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: reason.trim().isEmpty
//                       ? null
//                       : () {
//                     Navigator.pop(context);
//                     _rejectWithComment(request, reason);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: InboxColors.accentRed,
//                   ),
//                   child: const Text('Reject'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة للرفض مع التعليق
//   Future<void> _rejectWithComment(
//       Map<String, dynamic> request, String reason) async {
//     await _performAction(request, 'Reject', InboxColors.accentRed);
//   }
//
//   // 🔹 دالة للتنقل إلى صفحة التعديل
//   void _navigateToEditRequest(Map<String, dynamic> request) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => EditRequestPage(
//           requestId: request["id"].toString(),
//         ),
//       ),
//     ).then((_) {
//       // بعد العودة، قم بتحديث قائمة الطلبات
//       _fetchInboxRequests();
//     });
//   }
//
//   Future<void> _forwardTransaction(
//       String transactionId,
//       Map<String, dynamic> request,
//       ) async {
//     final users = await _apiService.fetchUsers(_userToken);
//
//     if (users.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No users available to forward.')),
//       );
//       return;
//     }
//
//     String? selectedUser;
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text("Forward Transaction"),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text("Select user to forward to (${users.length} users available)"),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUser,
//                       hint: const Text("Choose user"),
//                       isExpanded: true,
//                       onChanged: (value) => setStateDialog(() => selectedUser = value),
//                       items: users.map<DropdownMenuItem<String>>((user) {
//                         final name = user["name"] ?? "Unknown";
//                         return DropdownMenuItem<String>(
//                           value: name,
//                           child: Text(name),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: selectedUser == null ? null : () async {
//                     Navigator.pop(context);
//
//                     final requestId = transactionId;
//
//                     // تحديث حالة الطلب فوراً في الـ UI
//                     _updateRequestInList(requestId, {
//                       'isUpdating': true,
//                       'lastForwardSentTo': {
//                         'receiverName': selectedUser,
//                         'status': 'pending',
//                       },
//                     });
//
//                     setState(() {
//                       _isLoading = true;
//                     });
//
//                     final success = await _apiService.forwardTransaction(
//                       transactionId,
//                       selectedUser!,
//                       _userToken,
//                     );
//
//                     if (success) {
//                       // إزالة علامة التحديث
//                       _updateRequestInList(requestId, {'isUpdating': null});
//
//                       // إعادة جلب البيانات الحقيقية
//                       Future.delayed(const Duration(milliseconds: 500), () {
//                         _recalculateRequestData(requestId);
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Transaction forwarded successfully!'),
//                           backgroundColor: InboxColors.accentGreen,
//                         ),
//                       );
//                     } else {
//                       // في حالة الفشل، إرجاع الحالة الأصلية
//                       _updateRequestInList(requestId, {
//                         'isUpdating': null,
//                         'lastForwardSentTo': request['lastForwardSentTo'],
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Failed to forward transaction'),
//                           backgroundColor: InboxColors.accentRed,
//                         ),
//                       );
//                     }
//
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text("Forward"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _cancelForward(
//       String transactionId,
//       dynamic forwardId,
//       Map<String, dynamic> request,
//       ) async {
//     if (forwardId == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Cancel Forward'),
//           content: const Text('Are you sure you want to cancel this forward?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     final requestId = transactionId;
//
//     // تحديث حالة الطلب فوراً في الـ UI
//     _updateRequestInList(requestId, {
//       'isUpdating': true,
//       'lastForwardSentTo': null,
//     });
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);
//
//     if (success) {
//       // إزالة علامة التحديث
//       _updateRequestInList(requestId, {'isUpdating': null});
//
//       // إعادة جلب البيانات الحقيقية
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _recalculateRequestData(requestId);
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Forward cancelled successfully'),
//           backgroundColor: InboxColors.accentGreen,
//         ),
//       );
//     } else {
//       // في حالة الفشل، إرجاع الحالة الأصلية
//       _updateRequestInList(requestId, {
//         'isUpdating': null,
//         'lastForwardSentTo': request['lastForwardSentTo'],
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to cancel forward'),
//           backgroundColor: InboxColors.accentRed,
//         ),
//       );
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedPriority = 'All';
//       _selectedType = 'All Types';
//       _selectedStatus = 'All';
//       _searchController.clear();
//     });
//     _applyFilters();
//   }
//
//   void _viewDetails(String requestId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CourseApprovalRequestPage(requestId: requestId),
//       ),
//     );
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: InboxColors.accentRed,
//         action: SnackBarAction(label: 'Login', onPressed: _logout),
//       ),
//     );
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showMobileFilterDialog(
//       String title,
//       List<String> options,
//       String currentValue,
//       Function(String) onSelected,
//       ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: InboxColors.cardBg,
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: InboxColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? InboxColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onSelected(option);
//                 },
//               )),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading your inbox...',
//             style: TextStyle(
//               fontSize: 16,
//               color: InboxColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 64,
//               color: InboxColors.accentRed,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Error Loading Requests',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: InboxColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _errorMessage ?? 'Unknown error occurred',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: InboxColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: _fetchInboxRequests,
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: InboxColors.primary,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     if (_errorMessage != null && _requests.isEmpty) {
//       return _buildErrorState();
//     }
//
//     // استخدام الدوال المساعدة لحساب الإحصائيات
//     final stats = {
//       'total': _requests.length,
//       'waiting': _requests.where((req) => InboxHelpers.isRequestPending(req)).length,
//       'approved': _requests.where((req) => InboxHelpers.isRequestApproved(req)).length,
//       'rejected': _requests.where((req) => InboxHelpers.isRequestRejected(req)).length,
//       'needs_change': _requests.where((req) => InboxHelpers.isRequestNeedsChange(req)).length,
//       'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
//     };
//
//     return Column(
//       children: [
//         if (_requests.isNotEmpty)
//           InboxMobileStats(
//             total: stats['total']!,
//             waiting: stats['waiting']!,
//             approved: stats['approved']!,
//             rejected: stats['rejected']!,
//             fulfilled: stats['fulfilled']!, needsChange: stats['needs_change']!,
//           ),
//
//         InboxMobileFilters(
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           searchController: _searchController,
//           onPriorityChanged: (value) {
//             setState(() => _selectedPriority = value);
//             _applyFilters();
//           },
//           onTypeChanged: (value) {
//             setState(() => _selectedType = value);
//             _applyFilters();
//           },
//           onStatusChanged: (value) {
//             setState(() => _selectedStatus = value);
//             _applyFilters();
//           },
//           onSearchChanged: _onSearchChanged,
//           onShowMobileFilterDialog: _showMobileFilterDialog,
//         ),
//
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return RefreshIndicator(
//       onRefresh: _fetchInboxRequests,
//       color: InboxColors.primary,
//       child: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         itemCount: _filteredRequests.length,
//         itemBuilder: (context, index) {
//           final req = _filteredRequests[index];
//           final hasForwarded = req['lastForwardSentTo'] != null;
//           final lastForwardSentTo = req['lastForwardSentTo'];
//           final isUpdating = req['isUpdating'] == true;
//
//           return Opacity(
//             opacity: isUpdating ? 0.7 : 1.0,
//             child: InboxMobileCard(
//               request: req,
//               onViewDetails: () => _viewDetails(req["id"].toString()),
//               onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//               onReject: () => _showRejectWithCommentDialog(req),
//               onForward: () => _forwardTransaction(req["id"].toString(), req),
//               onCancelForward: () => _cancelForward(
//                 req["id"].toString(),
//                 lastForwardSentTo?['id'],
//                 req,
//               ),
//               onNeedChange: () => _showNeedChangeDialog(req),
//               onEditRequest: () => _navigateToEditRequest(req),
//               hasForwarded: hasForwarded,
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDesktopBody() {
//     if (_errorMessage != null && _requests.isEmpty) {
//       return _buildErrorState();
//     }
//
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (_requests.isNotEmpty) InboxStatsWidget(requests: _requests),
//             const SizedBox(height: 16),
//
//             InboxDesktopFilters(
//               selectedPriority: _selectedPriority,
//               selectedType: _selectedType,
//               selectedStatus: _selectedStatus,
//               priorities: priorities,
//               typeNames: typeNames,
//               statuses: statuses,
//               searchController: _searchController,
//               onPriorityChanged: (value) {
//                 setState(() => _selectedPriority = value);
//                 _applyFilters();
//               },
//               onTypeChanged: (value) {
//                 setState(() => _selectedType = value);
//                 _applyFilters();
//               },
//               onStatusChanged: (value) {
//                 setState(() => _selectedStatus = value);
//                 _applyFilters();
//               },
//               onSearchChanged: _onSearchChanged,
//             ),
//             const SizedBox(height: 20),
//
//             InboxHeader(
//               isMobile: false,
//               itemCount: _filteredRequests.length,
//             ),
//             const SizedBox(height: 16),
//
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return InboxEmptyState(onResetFilters: _resetFilters);
//     }
//
//     return Column(
//       children: _filteredRequests.map((req) {
//         final hasForwarded = req['lastForwardSentTo'] != null;
//         final lastForwardSentTo = req['lastForwardSentTo'];
//         final isUpdating = req['isUpdating'] == true;
//
//         return Opacity(
//           opacity: isUpdating ? 0.7 : 1.0,
//           child: InboxDesktopCard(
//             request: req,
//             onViewDetails: () => _viewDetails(req["id"].toString()),
//             onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
//             onReject: () => _showRejectWithCommentDialog(req),
//             onForward: () => _forwardTransaction(req["id"].toString(), req),
//             onCancelForward: () => _cancelForward(
//               req["id"].toString(),
//               lastForwardSentTo?['id'],
//               req,
//             ),
//             onNeedChange: () => _showNeedChangeDialog(req),
//             onEditRequest: () => _navigateToEditRequest(req),
//             hasForwarded: hasForwarded,
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: InboxColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Inbox',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: InboxColors.sidebarText,
//           ),
//         ),
//         backgroundColor: InboxColors.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
//             onPressed: _fetchInboxRequests,
//             tooltip: 'Refresh',
//           ),
//           if (_isLoading || _isRefreshing)
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(InboxColors.sidebarText),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الملفات الجديدة
import '../request/editerequest.dart';
import './inbox_colors.dart';
import './inbox_api.dart';
import './inbox_helpers.dart';
import './inbox_formatters.dart';
import './inbox_desktop_card.dart';
import './inbox_mobile_card.dart';
import './inbox_desktop_filters.dart';
import './inbox_mobile_filters.dart';
import './inbox_mobile_stats.dart';
import './inbox_stats_widget.dart';
import './inbox_empty_state.dart';
import './inbox_header.dart';
import '../request/Ditalis_Request/ditalis_request.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final InboxApi _apiService = InboxApi();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _userName;
  String? _userToken;

  // الفلاتر
  String _selectedStatus = "All";
  String _selectedType = "All Types";
  String _selectedPriority = "All";

  // أنواع الطلبات
  List<String> typeNames = ['All Types'];
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> statuses = [
    'All',
    'Waiting',
    'Approved',
    'Rejected',
    'Fulfilled',
    'Needs Change',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    print('🔄 Initializing InboxPage...');

    final userInfo = await _apiService.getUserInfo();
    setState(() {
      _userName = userInfo['userName'];
      _userToken = userInfo['token'];
    });

    print('👤 User Info - Name: $_userName, Token: ${_userToken != null ? "Exists" : "NULL"}');

    if (_userName != null && _userToken != null) {
      await _fetchTypes();
      await _fetchInboxRequests();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Unable to load user information. Please login again.";
      });
      print('❌ User info missing: $_errorMessage');
    }
  }

  Future<void> _fetchTypes() async {
    try {
      final types = await _apiService.fetchTypes(_userToken);
      setState(() {
        typeNames = ['All Types', ...types.where((type) => type != 'All Types')];
      });
    } catch (e) {
      print("⚠️ Error fetching types: $e");
    }
  }

  Future<void> _fetchInboxRequests() async {
    if (_isRefreshing) {
      print('⏸️ fetchInboxRequests already in progress');
      return;
    }

    if (_userToken == null || _userName == null) {
      setState(() {
        _errorMessage = "Please login first";
        _isLoading = false;
      });
      print('❌ Missing token or userName');
      return;
    }

    print('🔄 fetchInboxRequests started');

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);

      // تحديث البيانات المساعدة لكل طلب
      final updatedRequests = <dynamic>[];
      for (var req in allRequests) {
        try {
          final request = Map<String, dynamic>.from(req);

          // جلب البيانات الإضافية
          request['yourCurrentStatus'] = await _apiService.getYourForwardStatusForRequestUpdated(
            request, _userToken, _userName,
          );

          request['lastSenderName'] = await _apiService.getLastSenderNameForYou(
            request, _userToken, _userName,
          );

          request['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
            request, _userToken, _userName,
          );

          // 🔹 إضافة: التحقق مما إذا كان يمكن التوجيه (حسب منطق Angular الجديد)
          final canForward = await _apiService.checkIfCanForward(
            request['id'].toString(),
            _userToken,
            _userName,
          );
          request['hasForwarded'] = !canForward; // حفظ القيمة العكسية للحفاظ على التوافق

          updatedRequests.add(request);
        } catch (e) {
          print('⚠️ Error processing request ${req['id']}: $e');
          updatedRequests.add(req);
        }
      }

      setState(() {
        _requests = updatedRequests;
        _applyFilters();
        _isLoading = false;
        _isRefreshing = false;
      });

      print('✅ fetchInboxRequests completed - ${_requests.length} requests');

    } catch (e) {
      print("❌ Network error: $e");
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = "Failed to load requests: ${e.toString()}";
      });

      // إظهار رسالة خطأ للمستخدم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network error: ${e.toString()}'),
              backgroundColor: InboxColors.accentRed,
            ),
          );
        }
      });
    }
  }

  void _applyFilters() {
    final filtered = InboxHelpers.applyFilters(
      allRequests: _requests,
      selectedType: _selectedType,
      selectedPriority: _selectedPriority,
      selectedStatus: _selectedStatus,
      searchTerm: _searchController.text.toLowerCase(),
    );

    setState(() {
      _filteredRequests = filtered;
    });

    print('🔍 Filters applied - Showing ${_filteredRequests.length} of ${_requests.length} requests');
  }

  void _onSearchChanged(String value) {
    // استخدام debounce لمنع تحديث الفلاتر مع كل حرف
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  // 🔹 دالة لتحديث حالة طلب محدد في القائمة
  void _updateRequestInList(String requestId, Map<String, dynamic> updates) {
    final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
    if (index != -1) {
      setState(() {
        // تحديث الطلب الموجود
        final updatedRequest = Map<String, dynamic>.from(_requests[index]);
        updatedRequest.addAll(updates);
        _requests[index] = updatedRequest;

        // تطبيق الفلاتر مجدداً
        _applyFilters();
      });
      print('✅ Updated request $requestId in UI');
    } else {
      print('⚠️ Request $requestId not found in list');
    }
  }

  // 🔹 إعادة حساب البيانات المساعدة للطلب
  Future<void> _recalculateRequestData(String requestId) async {
    final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
    if (index == -1) return;

    try {
      final request = _requests[index];

      // تحديث حالة الـ forward للمستخدم الحالي
      final newStatus = await _apiService.getYourForwardStatusForRequestUpdated(
        request, _userToken, _userName,
      );

      // تحديث اسم المرسل
      final lastSender = await _apiService.getLastSenderNameForYou(
        request, _userToken, _userName,
      );

      // تحديث معلومات الـ forward الأخير
      final lastForward = await _apiService.getLastForwardSentByYou(
        request, _userToken, _userName,
      );

      // 🔹 إعادة حساب حالة canForward
      final canForward = await _apiService.checkIfCanForward(
        request['id'].toString(),
        _userToken,
        _userName,
      );

      _updateRequestInList(requestId, {
        'yourCurrentStatus': newStatus,
        'lastSenderName': lastSender,
        'lastForwardSentTo': lastForward,
        'hasForwarded': !canForward, // حفظ القيمة العكسية للحفاظ على التوافق
      });

      print('✅ Recalculated data for request $requestId');
    } catch (e) {
      print('⚠️ Error recalculating request data for $requestId: $e');
    }
  }

  Future<void> _performAction(
      Map<String, dynamic> request,
      String action,
      Color snackBarColor,
      ) async {
    if (_isLoading) return;

    final requestId = request["id"].toString();
    final actionLower = action.toLowerCase();

    print('🎯 Performing $action on request $requestId');

    // تحديث حالة الطلب فوراً في الـ UI (قبل استجابة السيرفر)
    _updateRequestInList(requestId, {
      'yourCurrentStatus': actionLower,
      'isUpdating': true, // علامة للتحديث
    });

    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.performActionUpdated(
      requestId,
      action,
      _userToken,
      _userName,
    );

    if (success) {
      // إزالة علامة التحديث
      _updateRequestInList(requestId, {'isUpdating': null});

      // إعادة جلب البيانات الحقيقية من السيرفر بعد 500 مللي ثانية
      Future.delayed(const Duration(milliseconds: 500), () {
        _recalculateRequestData(requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction has been ${actionLower}d successfully',
          ),
          backgroundColor: snackBarColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('✅ $action successful for request $requestId');
    } else {
      // في حالة الفشل، إرجاع الحالة الأصلية
      _updateRequestInList(requestId, {
        'yourCurrentStatus': request['yourCurrentStatus'],
        'isUpdating': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to perform action'),
          backgroundColor: InboxColors.accentRed,
        ),
      );

      print('❌ $action failed for request $requestId');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔹 دالة لإظهار dialog لطلب التعديل
  Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Changes'),
          content: const Text('Are you sure you want to request changes for this request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Request Changes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    String comment = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Specify Changes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please specify what changes are needed:'),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter your comments here...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        comment = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: comment.trim().isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    _sendNeedChangeRequest(request, comment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Submit Changes Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 دالة لإرسال طلب التعديل
  Future<void> _sendNeedChangeRequest(
      Map<String, dynamic> request, String comment) async {
    final requestId = request["id"].toString();

    // تحديث حالة الطلب فوراً في الـ UI
    _updateRequestInList(requestId, {
      'yourCurrentStatus': 'needs_change',
      'isUpdating': true,
    });

    setState(() {
      _isLoading = true;
    });

    // TODO: سيتم إضافة الـ endpoint لاحقاً
    bool success = true;

    if (success) {
      // إزالة علامة التحديث
      _updateRequestInList(requestId, {'isUpdating': null});

      // إعادة جلب البيانات الحقيقية
      Future.delayed(const Duration(milliseconds: 500), () {
        _recalculateRequestData(requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Change request sent successfully'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // في حالة الفشل، إرجاع الحالة الأصلية
      _updateRequestInList(requestId, {
        'yourCurrentStatus': request['yourCurrentStatus'],
        'isUpdating': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send change request'),
          backgroundColor: InboxColors.accentRed,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔹 دالة لإظهار dialog لسبب الرفض
  Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
    String reason = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Reject Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please provide a reason for rejection:'),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter rejection reason...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        reason = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: reason.trim().isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    _rejectWithComment(request, reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InboxColors.accentRed,
                  ),
                  child: const Text('Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 دالة للرفض مع التعليق
  Future<void> _rejectWithComment(
      Map<String, dynamic> request, String reason) async {
    await _performAction(request, 'Reject', InboxColors.accentRed);
  }

  // 🔹 دالة للتنقل إلى صفحة التعديل
  void _navigateToEditRequest(Map<String, dynamic> request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRequestPage(
          requestId: request["id"].toString(),
        ),
      ),
    ).then((_) {
      // بعد العودة، قم بتحديث قائمة الطلبات
      _fetchInboxRequests();
    });
  }

  Future<void> _forwardTransaction(
      String transactionId,
      Map<String, dynamic> request,
      ) async {
    final users = await _apiService.fetchUsers(_userToken);

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to forward.')),
      );
      return;
    }

    String? selectedUser;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Forward Transaction"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select user to forward to (${users.length} users available)"),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedUser,
                      hint: const Text("Choose user"),
                      isExpanded: true,
                      onChanged: (value) => setStateDialog(() => selectedUser = value),
                      items: users.map<DropdownMenuItem<String>>((user) {
                        final name = user["name"] ?? "Unknown";
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedUser == null ? null : () async {
                    Navigator.pop(context);

                    final requestId = transactionId;

                    // تحديث حالة الطلب فوراً في الـ UI
                    _updateRequestInList(requestId, {
                      'isUpdating': true,
                      'lastForwardSentTo': {
                        'receiverName': selectedUser,
                        'status': 'pending',
                      },
                      'hasForwarded': true, // تحديث حالة hasForwarded بعد التوجيه
                    });

                    setState(() {
                      _isLoading = true;
                    });

                    final success = await _apiService.forwardTransaction(
                      transactionId,
                      selectedUser!,
                      _userToken,
                    );

                    if (success) {
                      // إزالة علامة التحديث
                      _updateRequestInList(requestId, {'isUpdating': null});

                      // إعادة جلب البيانات الحقيقية
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _recalculateRequestData(requestId);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction forwarded successfully!'),
                          backgroundColor: InboxColors.accentGreen,
                        ),
                      );
                    } else {
                      // في حالة الفشل، إرجاع الحالة الأصلية
                      _updateRequestInList(requestId, {
                        'isUpdating': null,
                        'lastForwardSentTo': request['lastForwardSentTo'],
                        'hasForwarded': request['hasForwarded'],
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to forward transaction'),
                          backgroundColor: InboxColors.accentRed,
                        ),
                      );
                    }

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: const Text("Forward"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelForward(
      String transactionId,
      dynamic forwardId,
      Map<String, dynamic> request,
      ) async {
    if (forwardId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Forward'),
          content: const Text('Are you sure you want to cancel this forward?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final requestId = transactionId;

    // تحديث حالة الطلب فوراً في الـ UI
    _updateRequestInList(requestId, {
      'isUpdating': true,
      'lastForwardSentTo': null,
      'hasForwarded': false, // إعادة تعيين حالة hasForwarded بعد الإلغاء
    });

    setState(() {
      _isLoading = true;
    });

    final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);

    if (success) {
      // إزالة علامة التحديث
      _updateRequestInList(requestId, {'isUpdating': null});

      // إعادة جلب البيانات الحقيقية
      Future.delayed(const Duration(milliseconds: 500), () {
        _recalculateRequestData(requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forward cancelled successfully'),
          backgroundColor: InboxColors.accentGreen,
        ),
      );
    } else {
      // في حالة الفشل، إرجاع الحالة الأصلية
      _updateRequestInList(requestId, {
        'isUpdating': null,
        'lastForwardSentTo': request['lastForwardSentTo'],
        'hasForwarded': request['hasForwarded'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel forward'),
          backgroundColor: InboxColors.accentRed,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedPriority = 'All';
      _selectedType = 'All Types';
      _selectedStatus = 'All';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _viewDetails(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseApprovalRequestPage(requestId: requestId),
      ),
    );
  }

  void _handleTokenExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Session expired. Please login again."),
        backgroundColor: InboxColors.accentRed,
        action: SnackBarAction(label: 'Login', onPressed: _logout),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showMobileFilterDialog(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: InboxColors.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: InboxColors.primary,
                  ),
                ),
              ),
              ...options.map((option) => ListTile(
                leading: Icon(
                  Icons.check_rounded,
                  color: option == currentValue ? InboxColors.primary : Colors.transparent,
                ),
                title: Text(option, style: TextStyle(color: InboxColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(option);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your inbox...',
            style: TextStyle(
              fontSize: 16,
              color: InboxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: InboxColors.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: InboxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: InboxColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchInboxRequests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: InboxColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOptimizedBody() {
    if (_errorMessage != null && _requests.isEmpty) {
      return _buildErrorState();
    }

    // استخدام الدوال المساعدة لحساب الإحصائيات
    final stats = {
      'total': _requests.length,
      'waiting': _requests.where((req) => InboxHelpers.isRequestPending(req)).length,
      'approved': _requests.where((req) => InboxHelpers.isRequestApproved(req)).length,
      'rejected': _requests.where((req) => InboxHelpers.isRequestRejected(req)).length,
      'needs_change': _requests.where((req) => InboxHelpers.isRequestNeedsChange(req)).length,
      'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
    };

    return Column(
      children: [
        if (_requests.isNotEmpty)
          InboxMobileStats(
            total: stats['total']!,
            waiting: stats['waiting']!,
            approved: stats['approved']!,
            rejected: stats['rejected']!,
            fulfilled: stats['fulfilled']!, needsChange: stats['needs_change']!,
          ),

        InboxMobileFilters(
          selectedPriority: _selectedPriority,
          selectedType: _selectedType,
          selectedStatus: _selectedStatus,
          priorities: priorities,
          typeNames: typeNames,
          statuses: statuses,
          searchController: _searchController,
          onPriorityChanged: (value) {
            setState(() => _selectedPriority = value);
            _applyFilters();
          },
          onTypeChanged: (value) {
            setState(() => _selectedType = value);
            _applyFilters();
          },
          onStatusChanged: (value) {
            setState(() => _selectedStatus = value);
            _applyFilters();
          },
          onSearchChanged: _onSearchChanged,
          onShowMobileFilterDialog: _showMobileFilterDialog,
        ),

        Expanded(
          child: _buildMobileRequestsList(),
        ),
      ],
    );
  }

  Widget _buildMobileRequestsList() {
    if (_filteredRequests.isEmpty) {
      return InboxEmptyState(onResetFilters: _resetFilters);
    }

    return RefreshIndicator(
      onRefresh: _fetchInboxRequests,
      color: InboxColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final req = _filteredRequests[index];
          final hasForwarded = req['hasForwarded'] ?? false;
          final lastForwardSentTo = req['lastForwardSentTo'];
          final isUpdating = req['isUpdating'] == true;

          return Opacity(
            opacity: isUpdating ? 0.7 : 1.0,
            child: InboxMobileCard(
              request: req,
              onViewDetails: () => _viewDetails(req["id"].toString()),
              onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
              onReject: () => _showRejectWithCommentDialog(req),
              onForward: () => _forwardTransaction(req["id"].toString(), req),
              onCancelForward: () => _cancelForward(
                req["id"].toString(),
                lastForwardSentTo?['id'],
                req,
              ),
              onNeedChange: () => _showNeedChangeDialog(req),
              onEditRequest: () => _navigateToEditRequest(req),
              hasForwarded: hasForwarded,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopBody() {
    if (_errorMessage != null && _requests.isEmpty) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_requests.isNotEmpty) InboxStatsWidget(requests: _requests),
            const SizedBox(height: 16),

            InboxDesktopFilters(
              selectedPriority: _selectedPriority,
              selectedType: _selectedType,
              selectedStatus: _selectedStatus,
              priorities: priorities,
              typeNames: typeNames,
              statuses: statuses,
              searchController: _searchController,
              onPriorityChanged: (value) {
                setState(() => _selectedPriority = value);
                _applyFilters();
              },
              onTypeChanged: (value) {
                setState(() => _selectedType = value);
                _applyFilters();
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value);
                _applyFilters();
              },
              onSearchChanged: _onSearchChanged,
            ),
            const SizedBox(height: 20),

            InboxHeader(
              isMobile: false,
              itemCount: _filteredRequests.length,
            ),
            const SizedBox(height: 16),

            _buildDesktopRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRequestsList() {
    if (_filteredRequests.isEmpty) {
      return InboxEmptyState(onResetFilters: _resetFilters);
    }

    return Column(
      children: _filteredRequests.map((req) {
        final hasForwarded = req['hasForwarded'] ?? false;
        final lastForwardSentTo = req['lastForwardSentTo'];
        final isUpdating = req['isUpdating'] == true;

        return Opacity(
          opacity: isUpdating ? 0.7 : 1.0,
          child: InboxDesktopCard(
            request: req,
            onViewDetails: () => _viewDetails(req["id"].toString()),
            onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
            onReject: () => _showRejectWithCommentDialog(req),
            onForward: () => _forwardTransaction(req["id"].toString(), req),
            onCancelForward: () => _cancelForward(
              req["id"].toString(),
              lastForwardSentTo?['id'],
              req,
            ),
            onNeedChange: () => _showNeedChangeDialog(req),
            onEditRequest: () => _navigateToEditRequest(req),
            hasForwarded: hasForwarded,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: InboxColors.bodyBg,
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: min(width * 0.04, 20),
            color: InboxColors.sidebarText,
          ),
        ),
        backgroundColor: InboxColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
            onPressed: _fetchInboxRequests,
            tooltip: 'Refresh',
          ),
          if (_isLoading || _isRefreshing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(InboxColors.sidebarText),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : isMobile
          ? _buildMobileOptimizedBody()
          : _buildDesktopBody(),
    );
  }
}