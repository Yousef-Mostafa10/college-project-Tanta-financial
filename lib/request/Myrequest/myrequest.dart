// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import '../ditalis_request.dart';
// import '../editerequest.dart';
//
// // 🎨 COLOR PALETTE - Consistent with the whole application
// class AppColors {
//   // Primary Colors
//   static const Color primary = Color(0xFF00695C);
//   static const Color primaryLight = Color(0xFF00796B);
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
//   // Accent Colors
//   static const Color accentRed = Color(0xFFE74C3C);
//   static const Color accentGreen = Color(0xFF27AE60);
//   static const Color accentBlue = Color(0xFF1E88E5);
//   static const Color accentYellow = Color(0xFFFFB74D);
//
//   // Status Colors
//   static const Color statusApproved = Color(0xFF27AE60);
//   static const Color statusRejected = Color(0xFFE74C3C);
//   static const Color statusWaiting = Color(0xFF1E88E5);
//   static const Color statusPending = Color(0xFFFFB74D);
//   static const Color statusCompleted = Color(0xFF27AE60);
//
//   // Border Colors
//   static const Color borderColor = Color(0xFFE0E0E0);
//   static const Color focusBorderColor = Color(0xFF00695C);
//
//   // Stat Colors
//   static const Color statBgLight = Color(0xFFF0F8F7);
//   static const Color statBorder = Color(0xFFB2DFDB);
//   static const Color statShadow = Color(0x1A00695C);
// }
//
// class MyRequestsPage extends StatefulWidget {
//   const MyRequestsPage({super.key});
//
//   @override
//   _MyRequestsPageState createState() => _MyRequestsPageState();
// }
//
// class _MyRequestsPageState extends State<MyRequestsPage> {
//   final String baseUrl = AppConfig.baseUrl;
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
//   List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected'];
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
//       await _fetchMyRequests();
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
//       final userName = prefs.getString('userName') ??
//           prefs.getString('username') ??
//           'admin';
//
//       final token = prefs.getString('token');
//
//       setState(() {
//         _userName = userName;
//         _userToken = token;
//       });
//
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
//   // 🔹 جلب حالة الـ Forward للمستخدم الحالي فقط
//   Future<String?> _getUserForwardStatus(String transactionId) async {
//     if (_userToken == null || _userName == null) return null;
//
//     try {
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> forwards = data["transaction"]?["forwards"] ?? [];
//
//         // البحث من الأحدث إلى الأقدم
//         for (var i = forwards.length - 1; i >= 0; i--) {
//           final forward = forwards[i];
//           final sender = forward["sender"];
//           final receiver = forward["receiver"];
//
//           // إذا كان المستخدم هو sender
//           if (sender != null && sender["name"] == _userName) {
//             return forward["status"];
//           }
//         }
//
//         // إذا كان المستخدم هو receiver
//         for (var i = forwards.length - 1; i >= 0; i--) {
//           final forward = forwards[i];
//           final receiver = forward["receiver"];
//
//           if (receiver != null && receiver["name"] == _userName) {
//             return forward["status"];
//           }
//         }
//       }
//       return null;
//     } catch (e) {
//       debugPrint("❌ Error fetching forward status for transaction $transactionId: $e");
//       return null;
//     }
//   }
//
//   // 🔹 جلب كل الطلبات بدون فلترة أولية
//   Future<void> _fetchMyRequests() async {
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
//       List<dynamic> combinedRequests = [];
//
//       // دالة لجلب الطلبات حسب المعامل
//       Future<List<dynamic>> fetchByParam(String key) async {
//         List<dynamic> allRequests = [];
//         int currentPage = 1;
//         int lastPage = 1;
//
//         do {
//           final Map<String, String> queryParams = {
//             "pageNumber": currentPage.toString(),
//             "pageSize": "10",
//             key: _userName!,
//           };
//
//           final uri = Uri.parse("$baseUrl/transactions")
//               .replace(queryParameters: queryParams);
//
//           final response = await http.get(
//             uri,
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $_userToken',
//             },
//           );
//
//           if (response.statusCode == 200) {
//             final data = jsonDecode(response.body);
//             final List<dynamic> pageRequests = data["transactions"] ?? [];
//             allRequests.addAll(pageRequests);
//             lastPage = data["page"]?["last"] ?? 1;
//             currentPage++;
//           } else {
//             break;
//           }
//         } while (currentPage <= lastPage);
//
//         return allRequests;
//       }
//
//       // جلب الطلبات من مصدرين
//       final creatorRequests = await fetchByParam("creatorName");
//       final senderRequests = await fetchByParam("senderName");
//
//       // دمج بدون تكرار
//       final ids = <dynamic>{};
//       combinedRequests = [...creatorRequests, ...senderRequests]
//           .where((req) => ids.add(req["id"]))
//           .toList();
//
//       // جلب حالة الـ Forward لكل طلب
//       for (var request in combinedRequests) {
//         final forwardStatus = await _getUserForwardStatus(request["id"].toString());
//         request["userForwardStatus"] = forwardStatus;
//       }
//
//       setState(() {
//         _requests = combinedRequests;
//         _applyFilters(); // تطبيق الفلاتر بعد جلب البيانات
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint("❌ Error fetching requests: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests";
//       });
//     }
//   }
//
//   // 🔹 تطبيق الفلاتر محلياً
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
//         final userForwardStatus = request["userForwardStatus"];
//         final fulfilled = request["fulfilled"] == true;
//
//         switch (_selectedStatus) {
//           case "Approved":
//             return userForwardStatus == "approved";
//           case "Rejected":
//             return userForwardStatus == "rejected";
//           case "Waiting":
//           // إذا لم تكن approved أو rejected وكانت fulfilled = false
//             return (userForwardStatus != "approved" &&
//                 userForwardStatus != "rejected") ||
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
//         return title.contains(searchTerm);
//       }).toList();
//     }
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   // 🔹 دالة لتحويل التاريخ
//   String _formatDate(dynamic dateValue) {
//     try {
//       if (dateValue == null || dateValue == "N/A" || dateValue.toString().isEmpty) {
//         return "N/A";
//       }
//
//       String dateString = dateValue.toString();
//       if (dateString.contains('T')) {
//         final date = DateTime.parse(dateString);
//         return DateFormat('MMM dd, yyyy - HH:mm').format(date);
//       }
//
//       return dateString;
//     } catch (e) {
//       debugPrint("❌ Error formatting date: $dateValue - $e");
//       return "N/A";
//     }
//   }
//
//   // 🔹 دالة الحذف
//   Future<void> _deleteRequest(String requestId) async {
//     if (_userToken == null) return;
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Request'),
//           content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text(
//                 'Delete',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     try {
//       final response = await http.delete(
//         Uri.parse("$baseUrl/transactions/$requestId"),
//         headers: {
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData["status"] == "success") {
//           setState(() {
//             _requests.removeWhere((req) => req["id"].toString() == requestId);
//             _applyFilters();
//           });
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Request deleted successfully!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Failed to delete: ${responseData["message"] ?? "Unknown error"}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       } else {
//         final errorData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to delete: ${errorData["message"] ?? "Status code: ${response.statusCode}"}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: AppColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'My Requests',
//           style: TextStyle(
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
//             onPressed: _fetchMyRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState(isMobile)
//           : isMobile
//           ? _buildMobileOptimizedBody() // ⬅️ تصميم جديد للجوال مع Sticky Header
//           : _buildDesktopBody(),
//     );
//   }
//
//   // ⭐ تصميم الجوال مع Sticky Header
//   Widget _buildMobileOptimizedBody() {
//     return Column(
//       children: [
//         // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات
//         _buildMobileStatsSection(),
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
//   Widget _buildMobileStatsSection() {
//     final total = _requests.length;
//     final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
//     final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
//     final waitingForwards = _requests.where((req) =>
//     (req["userForwardStatus"] != "approved" &&
//         req["userForwardStatus"] != "rejected") ||
//         (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;
//
//     final statItems = [
//       {"label": "Total", "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Approved", "value": approvedForwards, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejectedForwards, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
//       {"label": "Waiting", "value": waitingForwards, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//     ];
//
//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.statBgLight, // ⬅️ استخدام درجة فاتحة من اللون الأساسي
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: AppColors.statBorder),
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
//             color: AppColors.textSecondary,
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
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // شريط البحث
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search transactions...',
//               hintStyle: TextStyle(color: AppColors.textMuted),
//               prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
//                 borderSide: BorderSide(color: AppColors.primary, width: 1.5),
//               ),
//               filled: true,
//               fillColor: AppColors.bodyBg,
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
//           color: AppColors.primary.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: AppColors.primary.withOpacity(0.2)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 14, color: AppColors.primary),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 9,
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             if (value != 'All' && value != 'All Types')
//               Text(
//                 value.length > 8 ? value.substring(0, 8) + '...' : value,
//                 style: TextStyle(
//                   fontSize: 8,
//                   color: AppColors.textPrimary,
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
//             color: AppColors.cardBg,
//             borderRadius: BorderRadius.only(
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
//                     color: AppColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue ? AppColors.primary : Colors.transparent,
//                 ),
//                 title: Text(option, style: TextStyle(color: AppColors.textPrimary)),
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
//       return _buildEmptyState(true);
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
//         final createdAt = req["created_at"];
//         final formattedDate = _formatDate(createdAt);
//
//         final userForwardStatus = req["userForwardStatus"];
//         final fulfilled = req["fulfilled"] == true;
//
//         final String status;
//         final Color statusColor;
//         final IconData statusIcon;
//
//         if (userForwardStatus != null) {
//           switch (userForwardStatus) {
//             case "approved":
//               status = "Approved";
//               statusColor = AppColors.statusApproved;
//               statusIcon = Icons.check_circle_rounded;
//               break;
//             case "rejected":
//               status = "Rejected";
//               statusColor = AppColors.statusRejected;
//               statusIcon = Icons.cancel_rounded;
//               break;
//             case "waiting":
//               status = "Waiting";
//               statusColor = AppColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//               break;
//             default:
//               status = "Waiting";
//               statusColor = AppColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//           }
//         } else {
//           if (fulfilled) {
//             status = "Completed";
//             statusColor = AppColors.statusCompleted;
//             statusIcon = Icons.check_circle_rounded;
//           } else {
//             status = "Waiting";
//             statusColor = AppColors.statusWaiting;
//             statusIcon = Icons.hourglass_empty_rounded;
//           }
//         }
//
//         return _buildMobileRequestCard(
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           date: formattedDate,
//           statusText: status,
//           statusColor: statusColor,
//           statusIcon: statusIcon,
//         );
//       },
//     );
//   }
//
//   Widget _buildMobileRequestCard({
//     required String id,
//     required String title,
//     required String type,
//     required String priority,
//     required String date,
//     required String statusText,
//     required Color statusColor,
//     required IconData statusIcon,
//   }) {
//     Color getPriorityColor(String priority) {
//       switch (priority.toLowerCase()) {
//         case 'high':
//           return AppColors.accentRed;
//         case 'medium':
//           return AppColors.accentYellow;
//         case 'low':
//           return AppColors.accentGreen;
//         default:
//           return AppColors.textMuted;
//       }
//     }
//
//     final priorityColor = getPriorityColor(priority);
//     final priorityIcon = _getPriorityIcon(priority);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: AppColors.cardBg,
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
//                     child: Icon(statusIcon, color: statusColor, size: 16),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
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
//               // التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       date,
//                       style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
//                   _buildMobileChip(type, Icons.category_outlined, AppColors.primary),
//                   const SizedBox(width: 6),
//                   _buildMobileChip(priority, priorityIcon, priorityColor),
//                   const Spacer(),
//                   PopupMenuButton<String>(
//                     icon: Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     onSelected: (value) {
//                       if (value == "details") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CourseApprovalRequestPage(requestId: id),
//                           ),
//                         );
//                       } else if (value == "edit") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => EditRequestPage(requestId: id),
//                           ),
//                         );
//                       } else if (value == "delete") {
//                         _deleteRequest(id);
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       PopupMenuItem(
//                         value: "details",
//                         child: Row(
//                           children: [
//                             Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("View Details", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: "edit",
//                         child: Row(
//                           children: [
//                             Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("Edit Request", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: "delete",
//                         child: Row(
//                           children: [
//                             Icon(Icons.delete_outlined, size: 16, color: AppColors.accentRed),
//                             SizedBox(width: 8),
//                             Text("Delete", style: TextStyle(fontSize: 12, color: AppColors.accentRed)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
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
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDesktopStatsRow(),
//             SizedBox(height: 16),
//             _buildDesktopSearchBar(),
//             SizedBox(height: 16),
//             _buildDesktopFilters(),
//             SizedBox(height: 20),
//             _buildDesktopHeader(),
//             SizedBox(height: 16),
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopStatsRow() {
//     final total = _requests.length;
//     final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
//     final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
//     final waitingForwards = _requests.where((req) =>
//     (req["userForwardStatus"] != "approved" &&
//         req["userForwardStatus"] != "rejected") ||
//         (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;
//
//     final stats = [
//       {"label": "Total", "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Approved", "value": approvedForwards, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejectedForwards, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
//       {"label": "Waiting", "value": waitingForwards, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//     ];
//
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.statBgLight,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: AppColors.statBorder),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(20),
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
//           padding: EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: 22),
//         ),
//         SizedBox(height: 10),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDesktopSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search transactions...',
//           hintStyle: TextStyle(color: AppColors.textMuted),
//           prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
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
//             borderSide: BorderSide(color: AppColors.primary, width: 1.5),
//           ),
//           filled: true,
//           fillColor: AppColors.bodyBg,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         onChanged: (value) => _applyFilters(),
//       ),
//     );
//   }
//
//   Widget _buildDesktopFilters() {
//     return Card(
//       elevation: 2,
//       color: AppColors.cardBg,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.filter_alt_outlined, color: AppColors.primary, size: 16),
//                 SizedBox(width: 6),
//                 Text(
//                   'FILTERS',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primary,
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildFilterDropdown(
//                     value: _selectedPriority,
//                     items: priorities,
//                     label: "Priority",
//                     icon: Icons.flag_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedPriority = value!);
//                       _applyFilters();
//                     },
//                     isMobile: false,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: _buildFilterDropdown(
//                     value: _selectedType,
//                     items: typeNames,
//                     label: "Type",
//                     icon: Icons.category_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedType = value!);
//                       _applyFilters();
//                     },
//                     isMobile: false,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: _buildFilterDropdown(
//                     value: _selectedStatus,
//                     items: statuses,
//                     label: "Status",
//                     icon: Icons.hourglass_top_outlined,
//                     onChanged: (value) {
//                       setState(() => _selectedStatus = value!);
//                       _applyFilters();
//                     },
//                     isMobile: false,
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
//   Widget _buildFilterDropdown({
//     required String value,
//     required List<String> items,
//     required String label,
//     required IconData icon,
//     required Function(String?) onChanged,
//     required bool isMobile,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.statBorder),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 12),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             value: value,
//             isExpanded: true,
//             icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
//             style: TextStyle(
//               fontSize: 14,
//               color: AppColors.textPrimary,
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
//                     color: AppColors.primary,
//                   ),
//                   SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       item,
//                       style: TextStyle(
//                         color: item == 'All Types' || item == 'All'
//                             ? AppColors.primary
//                             : AppColors.textPrimary,
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
//               Icon(Icons.list_alt_outlined, color: AppColors.primary, size: 18),
//               SizedBox(width: 6),
//               Text(
//                 'MY REQUESTS',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//             ),
//             child: Text(
//               '${_filteredRequests.length} items',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: AppColors.primary,
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
//       return _buildEmptyState(false);
//     }
//
//     return Column(
//       children: [
//         ..._filteredRequests.map((req) {
//           final id = req["id"].toString();
//           final title = req["title"] ?? "No Title";
//           final type = req["type"]?["name"] ?? "N/A";
//           final priority = req["priority"] ?? "N/A";
//           final createdAt = req["created_at"];
//           final formattedDate = _formatDate(createdAt);
//
//           final userForwardStatus = req["userForwardStatus"];
//           final fulfilled = req["fulfilled"] == true;
//
//           final String status;
//           final Color statusColor;
//           final IconData statusIcon;
//
//           if (userForwardStatus != null) {
//             switch (userForwardStatus) {
//               case "approved":
//                 status = "Approved";
//                 statusColor = AppColors.statusApproved;
//                 statusIcon = Icons.check_circle_rounded;
//                 break;
//               case "rejected":
//                 status = "Rejected";
//                 statusColor = AppColors.statusRejected;
//                 statusIcon = Icons.cancel_rounded;
//                 break;
//               case "waiting":
//                 status = "Waiting";
//                 statusColor = AppColors.statusWaiting;
//                 statusIcon = Icons.hourglass_empty_rounded;
//                 break;
//               default:
//                 status = "Waiting";
//                 statusColor = AppColors.statusWaiting;
//                 statusIcon = Icons.hourglass_empty_rounded;
//             }
//           } else {
//             if (fulfilled) {
//               status = "Completed";
//               statusColor = AppColors.statusCompleted;
//               statusIcon = Icons.check_circle_rounded;
//             } else {
//               status = "Waiting";
//               statusColor = AppColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//             }
//           }
//
//           return Container(
//             margin: EdgeInsets.only(bottom: 8),
//             child: _buildRequestCard(
//               id: id,
//               title: title,
//               type: type,
//               priority: priority,
//               date: formattedDate,
//               statusText: status,
//               statusColor: statusColor,
//               statusIcon: statusIcon,
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }
//
//   Widget _buildRequestCard({
//     required String id,
//     required String title,
//     required String type,
//     required String priority,
//     required String date,
//     required String statusText,
//     required Color statusColor,
//     required IconData statusIcon,
//   }) {
//     Color getPriorityColor(String priority) {
//       switch (priority.toLowerCase()) {
//         case 'high':
//           return AppColors.accentRed;
//         case 'medium':
//           return AppColors.accentYellow;
//         case 'low':
//           return AppColors.accentGreen;
//         default:
//           return AppColors.textMuted;
//       }
//     }
//
//     final priorityColor = getPriorityColor(priority);
//     final priorityIcon = _getPriorityIcon(priority);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: AppColors.cardBg,
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
//                     child: Icon(statusIcon, color: statusColor, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
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
//               // 2️⃣ التاريخ
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       date,
//                       style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية والأزرار
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, AppColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, priorityIcon, priorityColor),
//                   const Spacer(),
//
//                   // 4️⃣ أزرار الإجراءات
//                   PopupMenuButton<String>(
//                     icon: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     onSelected: (value) {
//                       if (value == "details") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CourseApprovalRequestPage(requestId: id),
//                           ),
//                         );
//                       } else if (value == "edit") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => EditRequestPage(requestId: id),
//                           ),
//                         );
//                       } else if (value == "delete") {
//                         _deleteRequest(id);
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       PopupMenuItem(
//                         value: "details",
//                         child: Row(
//                           children: [
//                             Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("View Details", style: TextStyle(color: AppColors.textPrimary)),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: "edit",
//                         child: Row(
//                           children: [
//                             Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("Edit Request", style: TextStyle(color: AppColors.textPrimary)),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: "delete",
//                         child: Row(
//                           children: [
//                             Icon(Icons.delete_outlined, size: 18, color: AppColors.accentRed),
//                             SizedBox(width: 8),
//                             Text("Delete", style: TextStyle(color: AppColors.accentRed)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// // 🔹 أضف هذه الدالة المساعدة بعد _buildRequestCard مباشرة
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
//   Widget _buildChip(String text, IconData icon, Color color) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: color),
//           SizedBox(width: 2),
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
//   Widget _buildLoadingState(bool isMobile) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//           ),
//           SizedBox(height: isMobile ? 16 : 20),
//           Text(
//             'Loading your requests...',
//             style: TextStyle(
//               fontSize: isMobile ? 16 : 18,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(bool isMobile) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.only(top: 60.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.inbox_outlined,
//               size: 64,
//               color: AppColors.textMuted,
//             ),
//             SizedBox(height: 16),
//             Text(
//               "No transactions found",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Try adjusting your filters or check back later",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: AppColors.textMuted,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16),
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
//               icon: Icon(Icons.refresh_rounded, size: 16),
//               label: Text("Reset Filters"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
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
//   IconData _getPriorityIcon(String priority) {
//     switch (priority.toLowerCase()) {
//       case 'high': return Icons.warning_amber_rounded;
//       case 'medium': return Icons.info_rounded;
//       case 'low': return Icons.flag_rounded;
//       default: return Icons.flag_rounded;
//     }
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
//       case "all":
//         return Icons.filter_list_rounded;
//       default:
//         return Icons.hourglass_top_outlined;
//     }
//   }
// }


//
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'my_requests_colors.dart';
// import 'my_requests_api.dart';
// import 'my_requests_helpers.dart';
// import 'my_requests_desktop_card.dart';
// import 'my_requests_mobile_card.dart';
// import 'my_requests_desktop_filters.dart';
// import 'my_requests_mobile_filters.dart';
// import 'my_requests_mobile_stats.dart';
// import 'my_requests_stats_widget.dart';
// import 'my_requests_empty_state.dart';
// import 'my_requests_header.dart';
//
// import '../Ditalis_Request/ditalis_request.dart';
// import '../editerequest.dart';
//
// class MyRequestsPage extends StatefulWidget {
//   const MyRequestsPage({super.key});
//
//   @override
//   _MyRequestsPageState createState() => _MyRequestsPageState();
// }
//
// class _MyRequestsPageState extends State<MyRequestsPage> {
//   final String baseUrl = AppConfig.baseUrl;
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
//   List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Needs Change', 'Fulfilled'];
//
//   late MyRequestsApi _api;
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
//       _api = MyRequestsApi(
//         baseUrl: baseUrl,
//         userToken: _userToken,
//         userName: _userName,
//       );
//       await _fetchTypes();
//       await _fetchMyRequests();
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
//       final userInfo = await MyRequestsApi.getUserInfo();
//       setState(() {
//         _userName = userInfo['userName'];
//         _userToken = userInfo['token'];
//       });
//     } catch (e) {
//       print("❌ Error getting user info: $e");
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
//       final types = await _api.fetchTypes();
//       setState(() {
//         typeNames = types;
//       });
//     } catch (e) {
//       print("⚠️ Error fetching types: $e");
//     }
//   }
//
//   // 🔹 جلب كل الطلبات بدون فلترة أولية
//   Future<void> _fetchMyRequests() async {
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
//       final requests = await _api.fetchMyRequests();
//       setState(() {
//         _requests = requests;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("❌ Error fetching requests: $e");
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load requests";
//       });
//     }
//   }
//
//   // 🔹 تطبيق الفلاتر محلياً
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
//         final userForwardStatus = request["userForwardStatus"];
//         final fulfilled = request["fulfilled"] == true;
//
//         switch (_selectedStatus) {
//           case "Approved":
//             return userForwardStatus == "approved";
//           case "Rejected":
//             return userForwardStatus == "rejected";
//           case "Waiting":
//             return (userForwardStatus != "approved" &&
//                 userForwardStatus != "rejected") ||
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
//         return title.contains(searchTerm);
//       }).toList();
//     }
//
//     setState(() {
//       _filteredRequests = filtered;
//     });
//   }
//
//   // 🔹 دالة الحذف
//   Future<void> _deleteRequest(String requestId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Request'),
//           content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text(
//                 'Delete',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) return;
//
//     try {
//       final success = await _api.deleteRequest(requestId);
//
//       if (success) {
//         setState(() {
//           _requests.removeWhere((req) => req["id"].toString() == requestId);
//           _applyFilters();
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Request deleted successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to delete request'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   // 🔹 عرض فلتر الموبايل
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
//             color: MyRequestsColors.cardBg,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: MyRequestsColors.primary,
//                     ),
//                   ),
//                 ),
//                 ...options.map((option) => ListTile(
//                   leading: Icon(
//                     Icons.check_rounded,
//                     color: option == currentValue ? MyRequestsColors.primary : Colors.transparent,
//                   ),
//                   title: Text(option, style: TextStyle(color: MyRequestsColors.textPrimary)),
//                   onTap: () {
//                     Navigator.pop(context);
//                     onSelected(option);
//                   },
//                 )),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           )
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//
//     return Scaffold(
//       backgroundColor: MyRequestsColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'My Requests',
//           style: TextStyle(
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: MyRequestsColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
//             onPressed: _fetchMyRequests,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? buildLoadingState(isMobile)
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBody(),
//     );
//   }
//
//   // ⭐ تصميم الجوال مع Sticky Header
//   Widget _buildMobileOptimizedBody() {
//     final total = _requests.length;
//     final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
//     final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
//     final waitingForwards = _requests.where((req) =>
//     (req["userForwardStatus"] != "approved" &&
//         req["userForwardStatus"] != "rejected") ||
//         (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;
//
//     return Column(
//       children: [
//         // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات
//         buildMobileStatsSection(total, approvedForwards, rejectedForwards, waitingForwards),
//
//         // 2️⃣ الجزء الثابت عند الأعلى - البحث والفلترة
//         buildMobileFilterSection(
//           searchController: _searchController,
//           selectedPriority: _selectedPriority,
//           selectedType: _selectedType,
//           selectedStatus: _selectedStatus,
//           priorities: priorities,
//           typeNames: typeNames,
//           statuses: statuses,
//           onSearchChanged: (value) => _applyFilters(),
//           onPriorityTap: () => _showMobileFilterDialog(
//             "Select Priority",
//             priorities,
//             _selectedPriority,
//                 (value) {
//               setState(() => _selectedPriority = value);
//               _applyFilters();
//             },
//           ),
//           onTypeTap: () => _showMobileFilterDialog(
//             "Select Type",
//             typeNames,
//             _selectedType,
//                 (value) {
//               setState(() => _selectedType = value);
//               _applyFilters();
//             },
//           ),
//           onStatusTap: () => _showMobileFilterDialog(
//             "Select Status",
//             statuses,
//             _selectedStatus,
//                 (value) {
//               setState(() => _selectedStatus = value);
//               _applyFilters();
//             },
//           ),
//         ),
//
//         // 3️⃣ قائمة الطلبات فقط هي التي تسكرول
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return buildEmptyState(true, onResetFilters: () {
//         setState(() {
//           _selectedPriority = 'All';
//           _selectedType = 'All Types';
//           _selectedStatus = 'All';
//           _searchController.clear();
//         });
//         _applyFilters();
//       });
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
//         final createdAt = req["created_at"];
//         final formattedDate = MyRequestsHelpers.formatDate(createdAt);
//
//         final userForwardStatus = req["userForwardStatus"];
//         final fulfilled = req["fulfilled"] == true;
//
//         final String status;
//         final Color statusColor;
//         final IconData statusIcon;
//
//         if (userForwardStatus != null) {
//           switch (userForwardStatus) {
//             case "approved":
//               status = "Approved";
//               statusColor = MyRequestsColors.statusApproved;
//               statusIcon = Icons.check_circle_rounded;
//               break;
//             case "rejected":
//               status = "Rejected";
//               statusColor = MyRequestsColors.statusRejected;
//               statusIcon = Icons.cancel_rounded;
//               break;
//             case "waiting":
//               status = "Waiting";
//               statusColor = MyRequestsColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//               break;
//             default:
//               status = "Waiting";
//               statusColor = MyRequestsColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//           }
//         } else {
//           if (fulfilled) {
//             status = "Completed";
//             statusColor = MyRequestsColors.statusFulfilled;
//             statusIcon = Icons.check_circle_rounded;
//           } else {
//             status = "Waiting";
//             statusColor = MyRequestsColors.statusWaiting;
//             statusIcon = Icons.hourglass_empty_rounded;
//           }
//         }
//
//         return buildMobileRequestCard(
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           date: formattedDate,
//           statusText: status,
//           statusColor: statusColor,
//           statusIcon: statusIcon,
//           onDelete: _deleteRequest,
//           context: context,
//         );
//       },
//     );
//   }
//
//   // ⭐ تصميم الديسكتوب
//   Widget _buildDesktopBody() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDesktopStatsRow(),
//             SizedBox(height: 16),
//             _buildDesktopSearchBar(),
//             SizedBox(height: 16),
//             _buildDesktopFilters(),
//             SizedBox(height: 20),
//             _buildDesktopHeader(_filteredRequests.length),
//             SizedBox(height: 16),
//             _buildDesktopRequestsList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopStatsRow() {
//     final total = _requests.length;
//     final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
//     final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
//     final waitingForwards = _requests.where((req) =>
//     (req["userForwardStatus"] != "approved" &&
//         req["userForwardStatus"] != "rejected") ||
//         (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;
//
//     return buildDesktopStatsRow(total, approvedForwards, rejectedForwards, waitingForwards);
//   }
//
//   Widget _buildDesktopSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: MyRequestsColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: MyRequestsColors.statShadow,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search transactions...',
//           hintStyle: TextStyle(color: MyRequestsColors.textMuted),
//           prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
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
//             borderSide: BorderSide(color: MyRequestsColors.primary, width: 1.5),
//           ),
//           filled: true,
//           fillColor: MyRequestsColors.bodyBg,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         onChanged: (value) => _applyFilters(),
//       ),
//     );
//   }
//
//   Widget _buildDesktopFilters() {
//     return buildDesktopFilters(
//       selectedPriority: _selectedPriority,
//       selectedType: _selectedType,
//       selectedStatus: _selectedStatus,
//       priorities: priorities,
//       typeNames: typeNames,
//       statuses: statuses,
//       onPriorityChanged: (value) {
//         setState(() => _selectedPriority = value!);
//         _applyFilters();
//       },
//       onTypeChanged: (value) {
//         setState(() => _selectedType = value!);
//         _applyFilters();
//       },
//       onStatusChanged: (value) {
//         setState(() => _selectedStatus = value!);
//         _applyFilters();
//       },
//     );
//   }
//
//   Widget _buildDesktopHeader(int itemCount) {
//     return buildDesktopHeader(itemCount);
//   }
//
//   Widget _buildDesktopRequestsList() {
//     if (_filteredRequests.isEmpty) {
//       return buildEmptyState(false, onResetFilters: () {
//         setState(() {
//           _selectedPriority = 'All';
//           _selectedType = 'All Types';
//           _selectedStatus = 'All';
//           _searchController.clear();
//         });
//         _applyFilters();
//       });
//     }
//
//     return Column(
//       children: [
//         ..._filteredRequests.map((req) {
//           final id = req["id"].toString();
//           final title = req["title"] ?? "No Title";
//           final type = req["type"]?["name"] ?? "N/A";
//           final priority = req["priority"] ?? "N/A";
//           final createdAt = req["created_at"];
//           final formattedDate = MyRequestsHelpers.formatDate(createdAt);
//
//           final userForwardStatus = req["userForwardStatus"];
//           final fulfilled = req["fulfilled"] == true;
//
//           final String status;
//           final Color statusColor;
//           final IconData statusIcon;
//
//           if (userForwardStatus != null) {
//             switch (userForwardStatus) {
//               case "approved":
//                 status = "Approved";
//                 statusColor = MyRequestsColors.statusApproved;
//                 statusIcon = Icons.check_circle_rounded;
//                 break;
//               case "rejected":
//                 status = "Rejected";
//                 statusColor = MyRequestsColors.statusRejected;
//                 statusIcon = Icons.cancel_rounded;
//                 break;
//               case "waiting":
//                 status = "Waiting";
//                 statusColor = MyRequestsColors.statusWaiting;
//                 statusIcon = Icons.hourglass_empty_rounded;
//                 break;
//               default:
//                 status = "Waiting";
//                 statusColor = MyRequestsColors.statusWaiting;
//                 statusIcon = Icons.hourglass_empty_rounded;
//             }
//           } else {
//             if (fulfilled) {
//               status = "Completed";
//               statusColor = MyRequestsColors.statusFulfilled;
//               statusIcon = Icons.check_circle_rounded;
//             } else {
//               status = "Waiting";
//               statusColor = MyRequestsColors.statusWaiting;
//               statusIcon = Icons.hourglass_empty_rounded;
//             }
//           }
//
//           return buildDesktopRequestCard(
//             id: id,
//             title: title,
//             type: type,
//             priority: priority,
//             date: formattedDate,
//             statusText: status,
//             statusColor: statusColor,
//             statusIcon: statusIcon,
//             onDelete: _deleteRequest,
//             context: context,
//           );
//         }).toList(),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:college_project/l10n/app_localizations.dart';

import '../../app_config.dart';
import 'my_requests_colors.dart';
import 'my_requests_api.dart';
import 'my_requests_helpers.dart';
import 'my_requests_desktop_card.dart';
import 'my_requests_mobile_card.dart';
import 'my_requests_desktop_filters.dart';
import 'my_requests_mobile_filters.dart';
import 'my_requests_mobile_stats.dart';
import 'my_requests_stats_widget.dart';
import 'my_requests_empty_state.dart';
import 'my_requests_header.dart';

import '../Ditalis_Request/ditalis_request.dart';
import '../editerequest.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final String baseUrl = AppConfig.baseUrl;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
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
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Needs Change', 'Fulfilled'];

  late MyRequestsApi _api;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 🔹 تهيئة البيانات
  Future<void> _initializeData() async {
    await _getUserInfo();
    if (_userName != null && _userToken != null) {
      _api = MyRequestsApi(
        baseUrl: baseUrl,
        userToken: _userToken,
        userName: _userName,
      );
      await _fetchTypes();
      await _fetchMyRequests();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.translate('unable_load_user_info');
      });
    }
  }

  // 🔹 جلب معلومات المستخدم المسجل
  Future<void> _getUserInfo() async {
    try {
      final userInfo = await MyRequestsApi.getUserInfo();
      setState(() {
        _userName = userInfo['userName'];
        _userToken = userInfo['token'];
      });
    } catch (e) {
      print("❌ Error getting user info: $e");
      setState(() {
        _userName = 'admin';
        _isLoading = false;
      });
    }
  }

  // 🔹 جلب أنواع المعاملات
  Future<void> _fetchTypes() async {
    try {
      final types = await _api.fetchTypes();
      setState(() {
        typeNames = types;
      });
    } catch (e) {
      print("⚠️ Error fetching types: $e");
    }
  }

  // 🔹 جلب كل الطلبات بدون فلترة أولية
  Future<void> _fetchMyRequests() async {
    if (_userToken == null || _userName == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('please_login_first');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _api.fetchMyRequests();
      setState(() {
        _requests = requests;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching requests: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.translate('failed_load_requests');
      });
    }
  }

  // 🔹 تطبيق الفلاتر محلياً
  void _applyFilters() {
    List<dynamic> filtered = _requests;

    // فلترة النوع
    if (_selectedType != "All Types") {
      filtered = filtered.where((request) {
        final type = request["type"]?["name"] ?? "";
        return type == _selectedType;
      }).toList();
    }

    // فلترة الأولوية
    if (_selectedPriority != "All") {
      filtered = filtered.where((request) {
        final priority = request["priority"] ?? "";
        return priority.toLowerCase() == _selectedPriority.toLowerCase();
      }).toList();
    }

    // فلترة الحالة
    if (_selectedStatus != "All") {
      filtered = filtered.where((request) {
        final userForwardStatus = request["userForwardStatus"];
        final fulfilled = request["fulfilled"] == true;

        switch (_selectedStatus) {
          case "Approved":
            return userForwardStatus == "approved";
          case "Rejected":
            return userForwardStatus == "rejected";
          case "Waiting":
            return (userForwardStatus != "approved" &&
                userForwardStatus != "rejected" &&
                userForwardStatus != "needs_change") ||
                (userForwardStatus == null && !fulfilled);
          case "Needs Change":
            return userForwardStatus == "needs_change";
          case "Fulfilled":
            return fulfilled == true;
          default:
            return true;
        }
      }).toList();
    }

    // فلترة البحث
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((request) {
        final title = (request["title"] ?? "").toLowerCase();
        return title.contains(searchTerm);
      }).toList();
    }

    setState(() {
      _filteredRequests = filtered;
    });
  }

  // 🔹 دالة الحذف
  Future<void> _deleteRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('delete_request_confirm_title')),
          content: Text(AppLocalizations.of(context)!.translate('delete_request_confirm_content')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.translate('cancel_button')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context)!.translate('delete_button'),
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final success = await _api.deleteRequest(requestId);

      if (success) {
        setState(() {
          _requests.removeWhere((req) => req["id"].toString() == requestId);
          _applyFilters();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('request_deleted_success')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_delete_request')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.translate('network_error')}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔹 عرض فلتر الموبايل
  void _showMobileFilterDialog(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
            decoration: BoxDecoration(
              color: MyRequestsColors.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
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
                        color: MyRequestsColors.primary,
                      ),
                    ),
                  ),
                ...options.map((option) {
                    String displayText = option;
                    if (option == 'All') displayText = AppLocalizations.of(context)!.translate('all_filter');
                    if (option == 'All Types') displayText = AppLocalizations.of(context)!.translate('all_types_filter');
                    if (option == 'Waiting') displayText = AppLocalizations.of(context)!.translate('status_waiting');
                    if (option == 'Approved') displayText = AppLocalizations.of(context)!.translate('status_approved');
                    if (option == 'Rejected') displayText = AppLocalizations.of(context)!.translate('status_rejected');
                    if (option == 'Needs Change') displayText = AppLocalizations.of(context)!.translate('status_needs_editing');
                    if (option == 'Fulfilled') displayText = AppLocalizations.of(context)!.translate('status_fulfilled');
                    if (option == 'High') displayText = AppLocalizations.of(context)!.translate('priority_high');
                    if (option == 'Medium') displayText = AppLocalizations.of(context)!.translate('priority_medium');
                    if (option == 'Low') displayText = AppLocalizations.of(context)!.translate('priority_low');

                    return ListTile(
                      leading: Icon(
                        Icons.check_rounded,
                        color: option == currentValue ? MyRequestsColors.primary : Colors.transparent,
                      ),
                      title: Text(displayText, style: TextStyle(color: MyRequestsColors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(option);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            )
        );
      },
    );
  }

  Widget buildLoadingState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: MyRequestsColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_requests'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: MyRequestsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: MyRequestsColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('my_requests'),
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MyRequestsColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
            onPressed: _fetchMyRequests,
            tooltip: AppLocalizations.of(context)!.translate('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? buildLoadingState(isMobile)
          : isMobile
          ? _buildMobileBody()
          : _buildDesktopBody(),
    );
  }

  // ⭐ تصميم الجوال
  Widget _buildMobileBody() {
    final total = _requests.length;
    final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
    final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
    final waitingForwards = _requests.where((req) =>
    (req["userForwardStatus"] != "approved" &&
        req["userForwardStatus"] != "rejected" &&
        req["userForwardStatus"] != "needs_change") ||
        (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;

    // الحالات الجديدة
    final needsChangeForwards = _requests.where((req) => req["userForwardStatus"] == "needs_change").length;
    final fulfilledForwards = _requests.where((req) => req["fulfilled"] == true).length;

    return Column(
      children: [
        // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات
        buildMobileStatsSection(context, total, approvedForwards, rejectedForwards, waitingForwards, needsChangeForwards, fulfilledForwards),

        // 2️⃣ الجزء الثابت عند الأعلى - البحث والفلترة
        buildMobileFilterSection(
          context: context,
          searchController: _searchController,
          selectedPriority: _selectedPriority,
          selectedType: _selectedType,
          selectedStatus: _selectedStatus,
          priorities: priorities,
          typeNames: typeNames,
          statuses: statuses,
          onSearchChanged: (value) => _applyFilters(),
          onPriorityTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_priority'),
            priorities,
            _selectedPriority,
                (value) {
              setState(() => _selectedPriority = value);
              _applyFilters();
            },
          ),
          onTypeTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_type'),
            typeNames,
            _selectedType,
                (value) {
              setState(() => _selectedType = value);
              _applyFilters();
            },
          ),
          onStatusTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_status'),
            statuses,
            _selectedStatus,
                (value) {
              setState(() => _selectedStatus = value);
              _applyFilters();
            },
          ),
        ),

        // 3️⃣ قائمة الطلبات فقط هي التي تسكرول
        Expanded(
          child: _buildMobileRequestsList(),
        ),
      ],
    );
  }

  Widget _buildMobileRequestsList() {
    if (_filteredRequests.isEmpty) {
      return buildEmptyState(context, true, onResetFilters: () {
        setState(() {
          _selectedPriority = 'All';
          _selectedType = 'All Types';
          _selectedStatus = 'All';
          _searchController.clear();
        });
        _applyFilters();
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final req = _filteredRequests[index];
        final id = req["id"].toString();
        final title = req["title"] ?? "No Title";
        final type = req["type"]?["name"] ?? AppLocalizations.of(context)!.translate('not_available');
        String priority = req["priority"] ?? AppLocalizations.of(context)!.translate('not_available');
        if (priority.toLowerCase() == 'high') priority = AppLocalizations.of(context)!.translate('priority_high');
        else if (priority.toLowerCase() == 'medium') priority = AppLocalizations.of(context)!.translate('priority_medium');
        else if (priority.toLowerCase() == 'low') priority = AppLocalizations.of(context)!.translate('priority_low');

        final createdAt = req["created_at"];
        final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

        final userForwardStatus = req["userForwardStatus"];
        final fulfilled = req["fulfilled"] == true;

        final String status;
        final Color statusColor;
        final IconData statusIcon;

        if (userForwardStatus != null) {
          switch (userForwardStatus) {
            case "approved":
              status = AppLocalizations.of(context)!.translate('status_approved');
              statusColor = MyRequestsColors.statusApproved;
              statusIcon = Icons.check_circle_rounded;
              break;
            case "rejected":
              status = AppLocalizations.of(context)!.translate('status_rejected');
              statusColor = MyRequestsColors.statusRejected;
              statusIcon = Icons.cancel_rounded;
              break;
            case "waiting":
              status = AppLocalizations.of(context)!.translate('status_waiting');
              statusColor = MyRequestsColors.statusWaiting;
              statusIcon = Icons.hourglass_empty_rounded;
              break;
            case "needs_change":
              status = AppLocalizations.of(context)!.translate('status_needs_editing');
              statusColor = MyRequestsColors.statusNeedsChange;
              statusIcon = Icons.edit_note_rounded;
              break;
            default:
              status = AppLocalizations.of(context)!.translate('status_waiting');
              statusColor = MyRequestsColors.statusWaiting;
              statusIcon = Icons.hourglass_empty_rounded;
          }
        } else {
          if (fulfilled) {
            status = AppLocalizations.of(context)!.translate('status_fulfilled');
            statusColor = MyRequestsColors.statusFulfilled;
            statusIcon = Icons.task_alt_rounded;
          } else {
            status = AppLocalizations.of(context)!.translate('status_waiting');
            statusColor = MyRequestsColors.statusWaiting;
            statusIcon = Icons.hourglass_empty_rounded;
          }
        }

        return buildMobileRequestCard(
          id: id,
          title: title,
          type: type,
          priority: priority,
          date: formattedDate,
          statusText: status,
          statusColor: statusColor,
          statusIcon: statusIcon,
          onDelete: _deleteRequest,
          context: context,
        );
      },
    );
  }

  // ⭐ تصميم الديسكتوب
  Widget _buildDesktopBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopStatsRow(),
            SizedBox(height: 16),

            // استخدام MyRequestsDesktopFilters بدلاً من الدوال القديمة
            MyRequestsDesktopFilters(
              selectedPriority: _selectedPriority,
              selectedType: _selectedType,
              selectedStatus: _selectedStatus,
              priorities: priorities,
              typeNames: typeNames,
              statuses: statuses,
              searchController: _searchController,
              onPriorityChanged: (value) {
                setState(() => _selectedPriority = value!);
                _applyFilters();
              },
              onTypeChanged: (value) {
                setState(() => _selectedType = value!);
                _applyFilters();
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value!);
                _applyFilters();
              },
              onSearchChanged: (value) => _applyFilters(),
            ),

            SizedBox(height: 20),
            _buildDesktopHeader(_filteredRequests.length),
            SizedBox(height: 16),
            _buildDesktopRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatsRow() {
    final total = _requests.length;
    final approvedForwards = _requests.where((req) => req["userForwardStatus"] == "approved").length;
    final rejectedForwards = _requests.where((req) => req["userForwardStatus"] == "rejected").length;
    final waitingForwards = _requests.where((req) =>
    (req["userForwardStatus"] != "approved" &&
        req["userForwardStatus"] != "rejected" &&
        req["userForwardStatus"] != "needs_change") ||
        (req["userForwardStatus"] == null && req["fulfilled"] != true)).length;

    // الحالات الجديدة
    final needsChangeForwards = _requests.where((req) => req["userForwardStatus"] == "needs_change").length;
    final fulfilledForwards = _requests.where((req) => req["fulfilled"] == true).length;

    return buildDesktopStatsRow(
        context,
        total,
        approvedForwards,
        rejectedForwards,
        waitingForwards,
        needsChangeForwards,
        fulfilledForwards
    );
  }

  Widget _buildDesktopHeader(int itemCount) {
    return buildDesktopHeader(context, itemCount);
  }

  Widget _buildDesktopRequestsList() {
    if (_filteredRequests.isEmpty) {
      return buildEmptyState(context, false, onResetFilters: () {
        setState(() {
          _selectedPriority = 'All';
          _selectedType = 'All Types';
          _selectedStatus = 'All';
          _searchController.clear();
        });
        _applyFilters();
      });
    }

    return Column(
      children: [
        ..._filteredRequests.map((req) {
          final id = req["id"].toString();
          final title = req["title"] ?? "No Title";
          final type = req["type"]?["name"] ?? AppLocalizations.of(context)!.translate('not_available');
          String priority = req["priority"] ?? AppLocalizations.of(context)!.translate('not_available');
          if (priority.toLowerCase() == 'high') priority = AppLocalizations.of(context)!.translate('priority_high');
          else if (priority.toLowerCase() == 'medium') priority = AppLocalizations.of(context)!.translate('priority_medium');
          else if (priority.toLowerCase() == 'low') priority = AppLocalizations.of(context)!.translate('priority_low');

          final createdAt = req["created_at"];
          final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

          final userForwardStatus = req["userForwardStatus"];
          final fulfilled = req["fulfilled"] == true;

          final String status;
          final Color statusColor;
          final IconData statusIcon;

          if (userForwardStatus != null) {
            switch (userForwardStatus) {
              case "approved":
                status = AppLocalizations.of(context)!.translate('status_approved');
                statusColor = MyRequestsColors.statusApproved;
                statusIcon = Icons.check_circle_rounded;
                break;
              case "rejected":
                status = AppLocalizations.of(context)!.translate('status_rejected');
                statusColor = MyRequestsColors.statusRejected;
                statusIcon = Icons.cancel_rounded;
                break;
              case "waiting":
                status = AppLocalizations.of(context)!.translate('status_waiting');
                statusColor = MyRequestsColors.statusWaiting;
                statusIcon = Icons.hourglass_empty_rounded;
                break;
              case "needs_change":
                status = AppLocalizations.of(context)!.translate('status_needs_editing');
                statusColor = MyRequestsColors.statusNeedsChange;
                statusIcon = Icons.edit_note_rounded;
                break;
              default:
                status = AppLocalizations.of(context)!.translate('status_waiting');
                statusColor = MyRequestsColors.statusWaiting;
                statusIcon = Icons.hourglass_empty_rounded;
            }
          } else {
            if (fulfilled) {
              status = AppLocalizations.of(context)!.translate('status_fulfilled');
              statusColor = MyRequestsColors.statusFulfilled;
              statusIcon = Icons.task_alt_rounded;
            } else {
              status = AppLocalizations.of(context)!.translate('status_waiting');
              statusColor = MyRequestsColors.statusWaiting;
              statusIcon = Icons.hourglass_empty_rounded;
            }
          }

          return buildDesktopRequestCard(
            id: id,
            title: title,
            type: type,
            priority: priority,
            date: formattedDate,
            statusText: status,
            statusColor: statusColor,
            statusIcon: statusIcon,
            onDelete: _deleteRequest,
            context: context,
          );
        }).toList(),
      ],
    );
  }
}