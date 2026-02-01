// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// import '../Auth/login.dart';
// import '../Notefecation/inbox.dart';
// import '../drawer.dart';
// import '../request/Ditalis_Request/ditalis_request.dart';
// import '../request/RequestTracking/request_tracking.dart';
import 'package:college_project/l10n/app_localizations.dart';
//
// // 🎨 COLOR PALETTE - Based on CSS Variables
// class AppColors {
//   // Primary Colors
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
//   // Accent Colors
//   static const Color accentYellow = Color(0xFFFFB74D);
//   static const Color accentRed = Color(0xFFE74C3C);
//   static const Color accentGreen = Color(0xFF27AE60);
//   static const Color accentBlue = Color(0xFF1E88E5);
//
//   // Chart Colors
//   static const Color chartLine1 = Color(0xFF009688);
//   static const Color chartLine2 = Color(0xFFFFB300);
//
//   // Additional Colors for Statistics
//   static const Color statBgLight = Color(0xFFF0F8F7); // ⬅️ درجة فاتحة من اللون الأساسي
//   static const Color statBorder = Color(0xFFB2DFDB);
//   static const Color statShadow = Color(0x1A00695C);
//
//   // Status Colors with unique icons
//   static const Color statusApproved = Color(0xFF27AE60);
//   static const Color statusRejected = Color(0xFFE74C3C);
//   static const Color statusWaiting = Color(0xFF1E88E5);
//   static const Color statusPending = Color(0xFFFFB74D);
// }
//
// class AdministrativeDashboardPage extends StatefulWidget {
//   const AdministrativeDashboardPage({super.key});
//
//   @override
//   State<AdministrativeDashboardPage> createState() =>
//       _AdministrativeDashboardPageState();
// }
//
// class _AdministrativeDashboardPageState
//     extends State<AdministrativeDashboardPage> {
//   final String _baseUrl = "http://192.168.1.3:3000";
//
//   List<dynamic> requests = [];
//   List<dynamic> filteredRequests = [];
//   bool isLoading = false;
//   final TextEditingController _searchController = TextEditingController();
//
//   // إحصائيات
//   int total = 0;
//   int approved = 0;
//   int rejected = 0;
//   int waiting = 0;
//
//   // فلاتر
//   String selectedPriority = 'All';
//   String selectedType = 'All Types';
//   String selectedStatus = 'All';
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> typeNames = ['All Types'];
//   List<String> statuses = ['All', 'Approved', 'Rejected', 'Waiting'];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchTypes();
//     fetchRequests();
//   }
//
//   // 🟦 جلب أنواع المعاملات مع المصادقة
//   Future<void> fetchTypes() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//
//       if (token == null) {
//         debugPrint("❌ No token found");
//         return;
//       }
//
//       final response = await http.get(
//         Uri.parse("$_baseUrl/transactions/types"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
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
//         debugPrint("✅ Types loaded: ${typeNames.length} types");
//       } else if (response.statusCode == 401) {
//         debugPrint("❌ Unauthorized - Token may be expired");
//         _handleTokenExpired();
//       } else {
//         debugPrint("❌ Failed to load types: ${response.statusCode}");
//         debugPrint("Response body: ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error fetching types: $e");
//     }
//   }
//
//   // 🔹 دالة الحذف
//   Future<void> _deleteRequest(String requestId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//
//     if (token == null) return;
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
//         Uri.parse("$_baseUrl/transactions/$requestId"),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData["status"] == "success") {
//           setState(() {
//             requests.removeWhere((req) => req["id"].toString() == requestId);
//             _applyFilters(requests);
//           });
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Request deleted successfully!'),
//               backgroundColor: AppColors.accentGreen,
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Failed to delete: ${responseData["message"] ?? "Unknown error"}'),
//               backgroundColor: AppColors.accentRed,
//             ),
//           );
//         }
//       } else {
//         final errorData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to delete: ${errorData["message"] ?? "Status code: ${response.statusCode}"}'),
//             backgroundColor: AppColors.accentRed,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: AppColors.accentRed,
//         ),
//       );
//     }
//   }
//
//   // 🔹 جلب آخر حالة Forward في المعاملة - الإصدار المصحح
//   Future<String?> _getLastForwardStatus(String transactionId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//
//       if (token == null) return null;
//
//       final response = await http.get(
//         Uri.parse("$_baseUrl/transactions/$transactionId/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> forwards = data["transaction"]?["forwards"] ?? [];
//
//         if (forwards.isNotEmpty) {
//           // 🔄 نرتب الـ forwards حسب updatedAt من الأحدث إلى الأقدم
//           forwards.sort((a, b) {
//             final timeA = DateTime.parse(a["updatedAt"] ?? a["forwardedAt"]);
//             final timeB = DateTime.parse(b["updatedAt"] ?? b["forwardedAt"]);
//             return timeB.compareTo(timeA); // ترتيب تنازلي
//           });
//
//           // نرجع حالة أول forward (الأحدث وقتياً)
//           return forwards.first["status"];
//         }
//       }
//       return null;
//     } catch (e) {
//       debugPrint("❌ Error fetching forward status for transaction $transactionId: $e");
//       return null;
//     }
//   }
//
//   // 🔁 جلب كل البيانات من جميع الصفحات
//   Future<void> fetchRequests() async {
//     setState(() => isLoading = true);
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//
//       if (token == null) {
//         debugPrint("❌ No token found for requests");
//         _handleTokenExpired();
//         return;
//       }
//
//       List<dynamic> allRequests = [];
//       int currentPage = 1;
//       int lastPage = 1;
//
//       do {
//         final queryParams = {
//           "pageNumber": currentPage.toString(),
//           if (selectedPriority != 'All')
//             "priority": selectedPriority.toLowerCase(),
//           if (selectedType != 'All Types') "typeName": selectedType,
//         };
//
//         final uri = Uri.parse("$_baseUrl/transactions")
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
//           lastPage = data["page"]["last"];
//           currentPage++;
//           debugPrint("📄 Loaded page ${currentPage - 1}: ${pageRequests.length} requests");
//         } else if (response.statusCode == 401) {
//           debugPrint("❌ Unauthorized - Token may be expired");
//           _handleTokenExpired();
//           break;
//         } else {
//           debugPrint("⚠️ Failed to load page $currentPage: ${response.statusCode}");
//           break;
//         }
//       } while (currentPage <= lastPage);
//
//       // 🔹 جلب آخر حالة forward لكل طلب
//       for (var request in allRequests) {
//         final lastStatus = await _getLastForwardStatus(request["id"].toString());
//         request["lastForwardStatus"] = lastStatus;
//       }
//
//       _updateStats(allRequests);
//       _applyFilters(allRequests);
//
//       setState(() {
//         requests = allRequests;
//       });
//
//       debugPrint("✅ Total requests loaded: ${allRequests.length}");
//     } catch (e) {
//       debugPrint("❌ Exception while fetching data: $e");
//     }
//     setState(() => isLoading = false);
//   }
//
//   // ⭐ دالة تطبيق الفلاتر محلياً
//   void _applyFilters(List<dynamic> allRequests) {
//     List<dynamic> filtered = allRequests;
//
//     // فلترة النوع
//     if (selectedType != "All Types") {
//       filtered = filtered.where((request) {
//         final type = request["type"]?["name"] ?? "";
//         return type == selectedType;
//       }).toList();
//     }
//
//     // فلترة الأولوية
//     if (selectedPriority != "All") {
//       filtered = filtered.where((request) {
//         final priority = request["priority"] ?? "";
//         return priority.toLowerCase() == selectedPriority.toLowerCase();
//       }).toList();
//     }
//
//     // فلترة الحالة
//     if (selectedStatus != "All") {
//       filtered = filtered.where((request) {
//         final lastForwardStatus = request["lastForwardStatus"];
//
//         switch (selectedStatus) {
//           case "Approved":
//             return lastForwardStatus == "approved";
//           case "Rejected":
//             return lastForwardStatus == "rejected";
//           case "Waiting":
//             return lastForwardStatus == "waiting";
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
//         final creator = (request["creator"]?["name"] ?? "").toLowerCase();
//         return title.contains(searchTerm) || creator.contains(searchTerm);
//       }).toList();
//     }
//
//     setState(() {
//       filteredRequests = filtered;
//     });
//   }
//
//   // معالجة انتهاء صلاحية التوكن
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Session expired. Please login again."),
//         backgroundColor: AppColors.accentRed,
//         duration: Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'Login',
//           textColor: Colors.white,
//           onPressed: () {
//             logout();
//           },
//         ),
//       ),
//     );
//   }
//
//   void _updateStats(List<dynamic> data) {
//     total = data.length;
//
//     // 🔹 إحصائيات بناءً على آخر حالة forward
//     approved = data.where((e) => e["lastForwardStatus"] == "approved").length;
//     rejected = data.where((e) => e["lastForwardStatus"] == "rejected").length;
//     waiting = data.where((e) => e["lastForwardStatus"] == "waiting").length;
//   }
//
//   Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginPage()),
//     );
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
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: Text(
//           'Administrative Dashboard',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: AppColors.sidebarText,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: AppColors.sidebarText),
//             onPressed: fetchRequests,
//             tooltip: 'Refresh',
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications_outlined, color: AppColors.sidebarText),
//             onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const InboxPage())
//             ),
//             tooltip: 'Notifications',
//           ),
//         ],
//       ),
//       drawer: CustomDrawer(onLogout: logout),
//       body: isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody() // ⬅️ تصميم جديد للجوال
//           : _buildDesktopBodyWithScroll(), // ⬅️ ديسكتوب مع سكرول
//     );
//   }
//
//   // ⭐ تصميم الديسكتوب مع سكرول للصفحة كلها
//   Widget _buildDesktopBodyWithScroll() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildStatsRow(false),
//             SizedBox(height: 16),
//             _buildSearchBar(false),
//             SizedBox(height: 16),
//             _buildFilters(false),
//             SizedBox(height: 20),
//             _buildHeader(false),
//             SizedBox(height: 16),
//             _buildRequestsListForDesktop(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ⭐ قائمة الطلبات للديسكتوب (بدون Expanded)
//   Widget _buildRequestsListForDesktop() {
//     if (filteredRequests.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return Column(
//       children: [
//         ...filteredRequests.map((req) {
//           final id = req["id"].toString();
//           final title = req["title"] ?? "No Title";
//           final type = req["type"]?["name"] ?? "N/A";
//           final priority = req["priority"] ?? "N/A";
//           final creator = req["creator"]?["name"] ?? "Unknown";
//
//           final lastForwardStatus = req["lastForwardStatus"];
//           final statusInfo = _getStatusInfo(lastForwardStatus);
//
//           return Container(
//             margin: EdgeInsets.only(bottom: 8),
//             child: _buildRequestCard(
//               id: id,
//               title: title,
//               type: type,
//               priority: priority,
//               creator: creator,
//               statusText: statusInfo['text'],
//               statusColor: statusInfo['color'],
//               statusIcon: statusInfo['icon'],
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }
//
//   // ⭐ تصميم جديد محسن للجوال
//   Widget _buildMobileOptimizedBody() {
//     return Column(
//       children: [
//         // الإحصائيات المدمجة
//         _buildMobileStatsSection(),
//
//         // البحث والفلاتر في قسم واحد
//         _buildMobileFilterSection(),
//
//         // قائمة الطلبات تأخذ كل المساحة المتبقية
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   // ⭐ تصميم محسن لشريط الإحصائيات للجوال
//   Widget _buildMobileStatsSection() {
//     final statItems = [
//       {"label": "Total", "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Approved", "value": approved, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejected, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
//       {"label": "Waiting", "value": waiting, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
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
//             onChanged: (value) => _applyFilters(requests),
//           ),
//           const SizedBox(height: 12),
//
//           // الفلاتر في صف واحد
//           Row(
//             children: [
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Priority",
//                   value: selectedPriority,
//                   icon: Icons.flag_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Priority",
//                     priorities,
//                     selectedPriority,
//                         (value) {
//                       setState(() => selectedPriority = value);
//                       _applyFilters(requests);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Type",
//                   value: selectedType,
//                   icon: Icons.category_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Type",
//                     typeNames,
//                     selectedType,
//                         (value) {
//                       setState(() => selectedType = value);
//                       _applyFilters(requests);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Status",
//                   value: selectedStatus,
//                   icon: Icons.hourglass_top_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Status",
//                     statuses,
//                     selectedStatus,
//                         (value) {
//                       setState(() => selectedStatus = value);
//                       _applyFilters(requests);
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
//     if (filteredRequests.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = filteredRequests[index];
//         final id = req["id"].toString();
//         final title = req["title"] ?? "No Title";
//         final type = req["type"]?["name"] ?? "N/A";
//         final priority = req["priority"] ?? "N/A";
//         final creator = req["creator"]?["name"] ?? "Unknown";
//
//         final lastForwardStatus = req["lastForwardStatus"];
//         final statusInfo = _getStatusInfo(lastForwardStatus);
//
//         return _buildMobileRequestCard(
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           creator: creator,
//           statusText: statusInfo['text'],
//           statusColor: statusInfo['color'],
//           statusIcon: statusInfo['icon'],
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
//     required String creator,
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
//               // معلومات المرسل والنوع
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 12, color: AppColors.textSecondary),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       "By: $creator",
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
//                   _buildMobileChip(priority, Icons.flag_outlined, getPriorityColor(priority)),
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
//                       } else if (value == "track") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => TransactionTrackingPage(transactionId: id),
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
//                         value: "track",
//                         child: Row(
//                           children: [
//                             Icon(Icons.track_changes_outlined, size: 16, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("Track Request", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
//   // 🔹 باقي الدوال (للديسكتوب) مع تطبيق الألوان الجديدة
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Loading transactions...',
//             style: TextStyle(
//               fontSize: 16,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar(bool isMobile) {
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
//           contentPadding: EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: isMobile ? 12 : 14,
//           ),
//         ),
//         onChanged: (value) => _applyFilters(requests),
//       ),
//     );
//   }
//
//   Widget _buildStatsRow(bool isMobile) {
//     final stats = [
//       {"label": "Total", "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Approved", "value": approved, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Rejected", "value": rejected, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
//       {"label": "Waiting", "value": waiting, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//     ];
//
//     return Container(
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
//       child: Padding(
//         padding: EdgeInsets.all(isMobile ? 16 : 20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: stats.map((stat) =>
//               _buildStatItem(
//                   stat["label"] as String,
//                   stat["value"] as int,
//                   stat["color"] as Color,
//                   stat["icon"] as IconData,
//                   isMobile
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
//         SizedBox(height: isMobile ? 8 : 10),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         SizedBox(height: isMobile ? 4 : 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isMobile ? 11 : 13,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFilters(bool isMobile) {
//     return Card(
//       elevation: 2,
//       color: AppColors.cardBg,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(isMobile ? 12 : 16),
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
//                     fontSize: isMobile ? 10 : 12,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primary,
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: isMobile ? 8 : 12),
//             isMobile
//                 ? _buildMobileFilters()
//                 : _buildDesktopFilters(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileFilters() {
//     return Column(
//       children: [
//         _buildFilterDropdown(
//           value: selectedPriority,
//           items: priorities,
//           label: "Priority",
//           icon: Icons.flag_outlined,
//           onChanged: (value) {
//             setState(() => selectedPriority = value!);
//             _applyFilters(requests);
//           },
//           isMobile: true,
//         ),
//         SizedBox(height: 8),
//         _buildFilterDropdown(
//           value: selectedType,
//           items: typeNames,
//           label: "Type",
//           icon: Icons.category_outlined,
//           onChanged: (value) {
//             setState(() => selectedType = value!);
//             _applyFilters(requests);
//           },
//           isMobile: true,
//         ),
//         SizedBox(height: 8),
//         _buildFilterDropdown(
//           value: selectedStatus,
//           items: statuses,
//           label: "Status",
//           icon: Icons.hourglass_top_outlined,
//           onChanged: (value) {
//             setState(() => selectedStatus = value!);
//             _applyFilters(requests);
//           },
//           isMobile: true,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDesktopFilters() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildFilterDropdown(
//             value: selectedPriority,
//             items: priorities,
//             label: "Priority",
//             icon: Icons.flag_outlined,
//             onChanged: (value) {
//               setState(() => selectedPriority = value!);
//               _applyFilters(requests);
//             },
//             isMobile: false,
//           ),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: _buildFilterDropdown(
//             value: selectedType,
//             items: typeNames,
//             label: "Type",
//             icon: Icons.category_outlined,
//             onChanged: (value) {
//               setState(() => selectedType = value!);
//               _applyFilters(requests);
//             },
//             isMobile: false,
//           ),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: _buildFilterDropdown(
//             value: selectedStatus,
//             items: statuses,
//             label: "Status",
//             icon: Icons.hourglass_top_outlined,
//             onChanged: (value) {
//               setState(() => selectedStatus = value!);
//               _applyFilters(requests);
//             },
//             isMobile: false,
//           ),
//         ),
//       ],
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
//         padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             value: value,
//             isExpanded: true,
//             icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
//             style: TextStyle(
//               fontSize: isMobile ? 12 : 14,
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
//                     size: isMobile ? 14 : 18,
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
//   Widget _buildHeader(bool isMobile) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.list_alt_outlined, color: AppColors.primary, size: isMobile ? 14 : 18),
//               SizedBox(width: 6),
//               Text(
//                 'TRANSACTIONS',
//                 style: TextStyle(
//                   fontSize: isMobile ? 12 : 14,
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
//               '${filteredRequests.length} items',
//               style: TextStyle(
//                 fontSize: isMobile ? 10 : 12,
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
//                   selectedPriority = 'All';
//                   selectedType = 'All Types';
//                   selectedStatus = 'All';
//                   _searchController.clear();
//                 });
//                 _applyFilters(requests);
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
//   // 📋 قائمة المعاملات
//   Widget _buildRequestsList() {
//     if (filteredRequests.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return ListView.separated(
//       itemCount: filteredRequests.length,
//       separatorBuilder: (context, index) => SizedBox(height: 8),
//       itemBuilder: (context, index) {
//         final req = filteredRequests[index];
//         final id = req["id"].toString();
//         final title = req["title"] ?? "No Title";
//         final type = req["type"]?["name"] ?? "N/A";
//         final priority = req["priority"] ?? "N/A";
//         final creator = req["creator"]?["name"] ?? "Unknown";
//
//         final lastForwardStatus = req["lastForwardStatus"];
//         final statusInfo = _getStatusInfo(lastForwardStatus);
//
//         return _buildRequestCard(
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           creator: creator,
//           statusText: statusInfo['text'],
//           statusColor: statusInfo['color'],
//           statusIcon: statusInfo['icon'],
//         );
//       },
//     );
//   }
//
//   // 🔹 دالة مساعدة للحصول على معلومات الحالة
//   Map<String, dynamic> _getStatusInfo(String? status) {
//     switch (status) {
//       case "approved":
//         return {
//           'text': 'Approved',
//           'color': AppColors.statusApproved,
//           'icon': Icons.check_circle_rounded, // ⬅️ أيقونة مختلفة للموافقة
//         };
//       case "rejected":
//         return {
//           'text': 'Rejected',
//           'color': AppColors.statusRejected,
//           'icon': Icons.cancel_rounded, // ⬅️ أيقونة مختلفة للرفض
//         };
//       case "waiting":
//         return {
//           'text': 'Waiting',
//           'color': AppColors.statusWaiting,
//           'icon': Icons.hourglass_empty_rounded, // ⬅️ أيقونة مختلفة للانتظار
//         };
//       default:
//         return {
//           'text': 'Pending',
//           'color': AppColors.statusPending,
//           'icon': Icons.access_time_filled_rounded, // ⬅️ أيقونة للمعلقة
//         };
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
//
//   Widget _buildRequestCard({
//     required String id,
//     required String title,
//     required String type,
//     required String priority,
//     required String creator,
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
//               // 2️⃣ معلومات المرسل
//               Row(
//                 children: [
//                   Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
//                   const SizedBox(width: 6),
//                   Text(
//                     "By: $creator",
//                     style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // 3️⃣ النوع والأولوية
//               Row(
//                 children: [
//                   _buildDesktopChip(type, Icons.category_outlined, AppColors.primary),
//                   const SizedBox(width: 8),
//                   _buildDesktopChip(priority, Icons.flag_outlined, getPriorityColor(priority)),
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
//                       } else if (value == "track") {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => TransactionTrackingPage(
//                               transactionId: id,
//                             ),
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
//                         value: "track",
//                         child: Row(
//                           children: [
//                             Icon(Icons.track_changes_outlined, size: 18, color: AppColors.primary),
//                             SizedBox(width: 8),
//                             Text("Track Request", style: TextStyle(color: AppColors.textPrimary)),
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
//
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
// }
// //
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../Auth/login.dart';
// import '../Notefecation/inbox.dart';
// import '../drawer.dart' hide AppColors;  // ⬅️ هنا التعديل
// import '../request/Ditalis_Request/ditalis_request.dart' hide AppColors;  // ⬅️ هنا التعديل
// import '../request/RequestTracking/request_tracking.dart';
// import 'dashboard_api.dart';
// import 'dashboard_colors.dart';
// import 'dashboard_helpers.dart';
// import 'stats_widget.dart';
// import 'filters_widget.dart';
// import 'header_widget.dart';
// import 'empty_state.dart';
// import 'desktop_request_card.dart';
// import 'mobile_request_card.dart';
//
// // باقي الكود كما هو...
// class AdministrativeDashboardPage extends StatefulWidget {
//   const AdministrativeDashboardPage({super.key});
//
//   @override
//   State<AdministrativeDashboardPage> createState() =>
//       _AdministrativeDashboardPageState();
// }
//
// class _AdministrativeDashboardPageState
//     extends State<AdministrativeDashboardPage> {
//   final DashboardAPI _api = DashboardAPI();
//   final TextEditingController _searchController = TextEditingController();
//
//   List<dynamic> requests = [];
//   List<dynamic> filteredRequests = [];
//   bool isLoading = false;
//
//   // إحصائيات
//   int total = 0;
//   int approved = 0;
//   int rejected = 0;
//   int waiting = 0;
//
//   // فلاتر
//   String selectedPriority = 'All';
//   String selectedType = 'All Types';
//   String selectedStatus = 'All';
//   List<String> priorities = ['All', 'High', 'Medium', 'Low'];
//   List<String> typeNames = ['All Types'];
//   List<String> statuses = ['All', 'Approved', 'Rejected', 'Waiting'];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchTypes();
//     fetchRequests();
//   }
//
//   Future<void> fetchTypes() async {
//     try {
//       final result = await _api.fetchTypes();
//       setState(() {
//         typeNames = ['All Types', ...result];
//       });
//     } catch (e) {
//       debugPrint("⚠️ Error fetching types: $e");
//     }
//   }
//
//   Future<void> _deleteRequest(String requestId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Request'),
//           content: const Text(
//               'Are you sure you want to delete this request? This action cannot be undone.'),
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
//       if (success) {
//         setState(() {
//           requests.removeWhere((req) => req["id"].toString() == requestId);
//           _applyFilters(requests);
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Request deleted successfully!'),
//             backgroundColor: AppColors.accentGreen,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to delete request'),
//             backgroundColor: AppColors.accentRed,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: AppColors.accentRed,
//         ),
//       );
//     }
//   }
//
//   Future<void> fetchRequests() async {
//     setState(() => isLoading = true);
//     try {
//       final allRequests = await _api.fetchAllRequests(
//         priority: selectedPriority != 'All' ? selectedPriority : null,
//         typeName: selectedType != 'All Types' ? selectedType : null,
//       );
//
//       _updateStats(allRequests);
//       _applyFilters(allRequests);
//
//       setState(() {
//         requests = allRequests;
//       });
//
//       debugPrint("✅ Total requests loaded: ${allRequests.length}");
//     } catch (e) {
//       debugPrint("❌ Exception while fetching data: $e");
//       if (e.toString().contains('Unauthorized')) {
//         _handleTokenExpired();
//       }
//     }
//     setState(() => isLoading = false);
//   }
//
//   void _applyFilters(List<dynamic> allRequests) {
//     List<dynamic> filtered = allRequests;
//
//     if (selectedType != "All Types") {
//       filtered = filtered.where((request) {
//         final type = request["type"]?["name"] ?? "";
//         return type == selectedType;
//       }).toList();
//     }
//
//     if (selectedPriority != "All") {
//       filtered = filtered.where((request) {
//         final priority = request["priority"] ?? "";
//         return priority.toLowerCase() == selectedPriority.toLowerCase();
//       }).toList();
//     }
//
//     if (selectedStatus != "All") {
//       filtered = filtered.where((request) {
//         final lastForwardStatus = request["lastForwardStatus"];
//
//         switch (selectedStatus) {
//           case "Approved":
//             return lastForwardStatus == "approved";
//           case "Rejected":
//             return lastForwardStatus == "rejected";
//           case "Waiting":
//             return lastForwardStatus == "waiting";
//           default:
//             return true;
//         }
//       }).toList();
//     }
//
//     final searchTerm = _searchController.text.toLowerCase();
//     if (searchTerm.isNotEmpty) {
//       filtered = filtered.where((request) {
//         final title = (request["title"] ?? "").toLowerCase();
//         final creator = (request["creator"]?["name"] ?? "").toLowerCase();
//         return title.contains(searchTerm) || creator.contains(searchTerm);
//       }).toList();
//     }
//
//     setState(() {
//       filteredRequests = filtered;
//     });
//   }
//
//   void _handleTokenExpired() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text("Session expired. Please login again."),
//         backgroundColor: AppColors.accentRed,
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'Login',
//           textColor: Colors.white,
//           onPressed: () {
//             logout();
//           },
//         ),
//       ),
//     );
//   }
//
//   void _updateStats(List<dynamic> data) {
//     total = data.length;
//     approved = data.where((e) => e["lastForwardStatus"] == "approved").length;
//     rejected = data.where((e) => e["lastForwardStatus"] == "rejected").length;
//     waiting = data.where((e) => e["lastForwardStatus"] == "waiting").length;
//   }
//
//   Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginPage()),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading transactions...',
//             style: TextStyle(
//               fontSize: 16,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
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
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: Text(
//           'Administrative Dashboard',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: min(width * 0.04, 20),
//             color: AppColors.sidebarText,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, color: AppColors.sidebarText),
//             onPressed: fetchRequests,
//             tooltip: 'Refresh',
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications_outlined,
//                 color: AppColors.sidebarText),
//             onPressed: () => Navigator.push(context,
//                 MaterialPageRoute(builder: (_) => const InboxPage())),
//             tooltip: 'Notifications',
//           ),
//         ],
//       ),
//       drawer: CustomDrawer(onLogout: logout),
//       body: isLoading
//           ? _buildLoadingState()
//           : isMobile
//           ? _buildMobileOptimizedBody()
//           : _buildDesktopBodyWithScroll(),
//     );
//   }
//
//   Widget _buildDesktopBodyWithScroll() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             StatsWidget(
//               total: total,
//               approved: approved,
//               rejected: rejected,
//               waiting: waiting,
//               isMobile: false,
//             ),
//             const SizedBox(height: 16),
//             _buildSearchBar(false),
//             const SizedBox(height: 16),
//             _buildFilters(false),
//             const SizedBox(height: 20),
//             _buildHeader(false),
//             const SizedBox(height: 16),
//             _buildRequestsListForDesktop(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileOptimizedBody() {
//     return Column(
//       children: [
//         _buildMobileStatsSection(),
//         _buildMobileFilterSection(),
//         Expanded(
//           child: _buildMobileRequestsList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSearchBar(bool isMobile) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
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
//           contentPadding: EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: isMobile ? 12 : 14,
//           ),
//         ),
//         onChanged: (value) => _applyFilters(requests),
//       ),
//     );
//   }
//
//   Widget _buildFilters(bool isMobile) {
//     return FiltersWidget(
//       searchController: _searchController,
//       selectedPriority: selectedPriority,
//       selectedType: selectedType,
//       selectedStatus: selectedStatus,
//       priorities: priorities,
//       typeNames: typeNames,
//       statuses: statuses,
//       isMobile: isMobile,
//       onSearchChanged: (value) => _applyFilters(requests),
//       onPriorityChanged: (value) {
//         setState(() => selectedPriority = value!);
//         _applyFilters(requests);
//       },
//       onTypeChanged: (value) {
//         setState(() => selectedType = value!);
//         _applyFilters(requests);
//       },
//       onStatusChanged: (value) {
//         setState(() => selectedStatus = value!);
//         _applyFilters(requests);
//       },
//     );
//   }
//
//   Widget _buildHeader(bool isMobile) {
//     return HeaderWidget(
//       itemCount: filteredRequests.length,
//       isMobile: isMobile,
//     );
//   }
//
//   Widget _buildRequestsListForDesktop() {
//     if (filteredRequests.isEmpty) {
//       return const EmptyState();
//     }
//
//     return Column(
//       children: [
//         ...filteredRequests.map((req) {
//           final id = req["id"].toString();
//           final title = req["title"] ?? "No Title";
//           final type = req["type"]?["name"] ?? "N/A";
//           final priority = req["priority"] ?? "N/A";
//           final creator = req["creator"]?["name"] ?? "Unknown";
//           final lastForwardStatus = req["lastForwardStatus"];
//           final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);
//
//           return Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             child: DesktopRequestCard(
//               id: id,
//               title: title,
//               type: type,
//               priority: priority,
//               creator: creator,
//               statusText: statusInfo['text'],
//               statusColor: statusInfo['color'],
//               statusIcon: statusInfo['icon'],
//               onViewDetails: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => CourseApprovalRequestPage(requestId: id),
//                   ),
//                 );
//               },
//               onTrackRequest: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TransactionTrackingPage(
//                       transactionId: id,
//                     ),
//                   ),
//                 );
//               },
//               onDeleteRequest: () => _deleteRequest(id),
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }
//
//   Widget _buildMobileStatsSection() {
//     final statItems = [
//       {
//         "label": "Total",
//         "value": total,
//         "color": AppColors.textPrimary,
//         "icon": Icons.dashboard_rounded
//       },
//       {
//         "label": "Approved",
//         "value": approved,
//         "color": AppColors.statusApproved,
//         "icon": Icons.check_circle_rounded
//       },
//       {
//         "label": "Rejected",
//         "value": rejected,
//         "color": AppColors.statusRejected,
//         "icon": Icons.cancel_rounded
//       },
//       {
//         "label": "Waiting",
//         "value": waiting,
//         "color": AppColors.statusWaiting,
//         "icon": Icons.hourglass_empty_rounded
//       },
//     ];
//
//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.statBgLight,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 10,
//             offset: const Offset(0, 4),
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
//   Widget _buildMobileStatItem(
//       {required String label,
//         required int value,
//         required Color color,
//         required IconData icon}) {
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
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search transactions...',
//               hintStyle: TextStyle(color: AppColors.textMuted),
//               prefixIcon:
//               const Icon(Icons.search_rounded, color: AppColors.primary),
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
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               isDense: true,
//             ),
//             onChanged: (value) => _applyFilters(requests),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Priority",
//                   value: selectedPriority,
//                   icon: Icons.flag_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Priority",
//                     priorities,
//                     selectedPriority,
//                         (value) {
//                       setState(() => selectedPriority = value);
//                       _applyFilters(requests);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Type",
//                   value: selectedType,
//                   icon: Icons.category_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Type",
//                     typeNames,
//                     selectedType,
//                         (value) {
//                       setState(() => selectedType = value);
//                       _applyFilters(requests);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _buildMobileFilterChip(
//                   label: "Status",
//                   value: selectedStatus,
//                   icon: Icons.hourglass_top_outlined,
//                   onTap: () => _showMobileFilterDialog(
//                     "Select Status",
//                     statuses,
//                     selectedStatus,
//                         (value) {
//                       setState(() => selectedStatus = value);
//                       _applyFilters(requests);
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
//   void _showMobileFilterDialog(String title, List<String> options,
//       String currentValue, Function(String) onSelected) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: AppColors.cardBg,
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
//                     color: AppColors.primary,
//                   ),
//                 ),
//               ),
//               ...options.map((option) => ListTile(
//                 leading: Icon(
//                   Icons.check_rounded,
//                   color: option == currentValue
//                       ? AppColors.primary
//                       : Colors.transparent,
//                 ),
//                 title: Text(option,
//                     style: TextStyle(color: AppColors.textPrimary)),
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
//     if (filteredRequests.isEmpty) {
//       return const EmptyState();
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: filteredRequests.length,
//       itemBuilder: (context, index) {
//         final req = filteredRequests[index];
//         final id = req["id"].toString();
//         final title = req["title"] ?? "No Title";
//         final type = req["type"]?["name"] ?? "N/A";
//         final priority = req["priority"] ?? "N/A";
//         final creator = req["creator"]?["name"] ?? "Unknown";
//         final lastForwardStatus = req["lastForwardStatus"];
//         final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);
//
//         return MobileRequestCard(
//           id: id,
//           title: title,
//           type: type,
//           priority: priority,
//           creator: creator,
//           statusText: statusInfo['text'],
//           statusColor: statusInfo['color'],
//           statusIcon: statusInfo['icon'],
//           onViewDetails: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => CourseApprovalRequestPage(requestId: id),
//               ),
//             );
//           },
//           onTrackRequest: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     TransactionTrackingPage(transactionId: id),
//               ),
//             );
//           },
//           onDeleteRequest: () => _deleteRequest(id),
//         );
//       },
//     );
//   }
// }



import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/login.dart';
import '../Notefecation/inbox.dart';
import '../drawer.dart' hide AppColors;
import '../request/Ditalis_Request/ditalis_request.dart' hide AppColors;
import '../request/RequestTracking/request_tracking.dart';
import 'dashboard_api.dart';
import 'dashboard_colors.dart';
import 'dashboard_helpers.dart';
import 'stats_widget.dart';
import 'filters_widget.dart';
import 'header_widget.dart';
import 'empty_state.dart';
import 'desktop_request_card.dart';
import 'mobile_request_card.dart';

class AdministrativeDashboardPage extends StatefulWidget {
  const AdministrativeDashboardPage({super.key});

  @override
  State<AdministrativeDashboardPage> createState() =>
      _AdministrativeDashboardPageState();
}

class _AdministrativeDashboardPageState
    extends State<AdministrativeDashboardPage> {
  final DashboardAPI _api = DashboardAPI();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> requests = [];
  List<dynamic> filteredRequests = [];
  bool isLoading = false;

  // إحصائيات - تم إضافة حالتين جديدتين
  int total = 0;
  int approved = 0;
  int rejected = 0;
  int waiting = 0;
  int needsChange = 0; // حالة جديدة
  int fulfilled = 0;   // حالة جديدة

  // فلاتر - تم تحديث قائمة الحالات
  String selectedPriority = 'All';
  String selectedType = 'All Types';
  String selectedStatus = 'All';
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> typeNames = ['All Types'];
// في dashboard.dart
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Fulfilled', 'Needs Change'];

  @override
  void initState() {
    super.initState();
    fetchTypes();
    fetchRequests();
  }

  Future<void> fetchTypes() async {
    try {
      final result = await _api.fetchTypes();
      setState(() {
        typeNames = ['All Types', ...result];
      });
    } catch (e) {
      debugPrint("⚠️ Error fetching types: $e");
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('delete_request_title')),
          content: Text(
              AppLocalizations.of(context)!.translate('delete_request_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context)!.translate('delete'),
                style: const TextStyle(color: Colors.red),
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
          requests.removeWhere((req) => req["id"].toString() == requestId);
          _applyFilters(requests);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('request_deleted_success')),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_delete')),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.translate('network_error')}: ${e.toString()}'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final allRequests = await _api.fetchAllRequests(
        priority: selectedPriority != 'All' ? selectedPriority : null,
        typeName: selectedType != 'All Types' ? selectedType : null,
      );

      _updateStats(allRequests);
      _applyFilters(allRequests);

      setState(() {
        requests = allRequests;
      });

      debugPrint("✅ Total requests loaded: ${allRequests.length}");
    } catch (e) {
      debugPrint("❌ Exception while fetching data: $e");
      if (e.toString().contains('Unauthorized')) {
        _handleTokenExpired();
      }
    }
    setState(() => isLoading = false);
  }

  void _applyFilters(List<dynamic> allRequests) {
    List<dynamic> filtered = allRequests;

    if (selectedType != "All Types") {
      filtered = filtered.where((request) {
        final type = request["type"]?["name"] ?? "";
        return type == selectedType;
      }).toList();
    }

    if (selectedPriority != "All") {
      filtered = filtered.where((request) {
        final priority = request["priority"] ?? "";
        return priority.toLowerCase() == selectedPriority.toLowerCase();
      }).toList();
    }

    if (selectedStatus != "All") {
      filtered = filtered.where((request) {
        final lastForwardStatus = request["lastForwardStatus"];

        switch (selectedStatus) {
          case "Approved":
            return lastForwardStatus == "approved";
          case "Rejected":
            return lastForwardStatus == "rejected";
          case "Waiting":
            return lastForwardStatus == "waiting";
          case "Fulfilled": // حالة جديدة
            return lastForwardStatus == "fulfilled";
          case "Needs Change": // حالة جديدة
            return lastForwardStatus == "needsChange";
          default:
            return true;
        }
      }).toList();
    }

    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((request) {
        final title = (request["title"] ?? "").toLowerCase();
        final creator = (request["creator"]?["name"] ?? "").toLowerCase();
        return title.contains(searchTerm) || creator.contains(searchTerm);
      }).toList();
    }

    setState(() {
      filteredRequests = filtered;
    });
  }

  void _handleTokenExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('session_expired')),
        backgroundColor: AppColors.accentRed,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.translate('login'),
          textColor: Colors.white,
          onPressed: () {
            logout();
          },
        ),
      ),
    );
  }

  void _updateStats(List<dynamic> data) {
    total = data.length;
    approved = data.where((e) => e["lastForwardStatus"] == "approved").length;
    rejected = data.where((e) => e["lastForwardStatus"] == "rejected").length;
    waiting = data.where((e) => e["lastForwardStatus"] == "waiting").length;
    // إضافة الحالتين الجديدتين:
    needsChange = data.where((e) => e["lastForwardStatus"] == "needsChange").length;
    fulfilled = data.where((e) => e["lastForwardStatus"] == "fulfilled").length;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_transactions'),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
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
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('administrative_dashboard'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: min(width * 0.04, 20),
            color: AppColors.sidebarText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.sidebarText),
            onPressed: fetchRequests,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: AppColors.sidebarText),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InboxPage())),
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: CustomDrawer(onLogout: logout),
      body: isLoading
          ? _buildLoadingState()
          : isMobile
          ? _buildMobileOptimizedBody()
          : _buildDesktopBodyWithScroll(),
    );
  }

  Widget _buildDesktopBodyWithScroll() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsWidget(
              total: total,
              approved: approved,
              rejected: rejected,
              waiting: waiting,
              needsChange: needsChange, // تمرير القيمة الجديدة
              fulfilled: fulfilled,     // تمرير القيمة الجديدة
              isMobile: false,
            ),
            const SizedBox(height: 16),
            _buildSearchBar(false),
            const SizedBox(height: 16),
            _buildFilters(false),
            const SizedBox(height: 20),
            _buildHeader(false),
            const SizedBox(height: 16),
            _buildRequestsListForDesktop(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOptimizedBody() {
    return Column(
      children: [
        _buildMobileStatsSection(),
        _buildMobileFilterSection(),
        Expanded(
          child: _buildMobileRequestsList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: AppColors.bodyBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 12 : 14,
          ),
        ),
        onChanged: (value) => _applyFilters(requests),
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return FiltersWidget(
      searchController: _searchController,
      selectedPriority: selectedPriority,
      selectedType: selectedType,
      selectedStatus: selectedStatus,
      priorities: priorities,
      typeNames: typeNames,
      statuses: statuses,
      isMobile: isMobile,
      onSearchChanged: (value) => _applyFilters(requests),
      onPriorityChanged: (value) {
        setState(() => selectedPriority = value!);
        _applyFilters(requests);
      },
      onTypeChanged: (value) {
        setState(() => selectedType = value!);
        _applyFilters(requests);
      },
      onStatusChanged: (value) {
        setState(() => selectedStatus = value!);
        _applyFilters(requests);
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return HeaderWidget(
      itemCount: filteredRequests.length,
      isMobile: isMobile,
    );
  }

  Widget _buildRequestsListForDesktop() {
    if (filteredRequests.isEmpty) {
      return const EmptyState();
    }

    return Column(
      children: [
        ...filteredRequests.map((req) {
          final id = req["id"].toString();
          final title = req["title"] ?? "No Title";
          final type = req["type"]?["name"] ?? "N/A";
          final priority = req["priority"] ?? "N/A";
          final creator = req["creator"]?["name"] ?? "Unknown";
          final lastForwardStatus = req["lastForwardStatus"];
          final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: DesktopRequestCard(
              id: id,
              title: title,
              type: type,
              priority: priority,
              creator: creator,
              statusText: statusInfo['text'],
              statusColor: statusInfo['color'],
              statusIcon: statusInfo['icon'],
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseApprovalRequestPage(requestId: id),
                  ),
                );
              },
              onTrackRequest: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionTrackingPage(
                      transactionId: id,
                    ),
                  ),
                );
              },
              onDeleteRequest: () => _deleteRequest(id),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMobileStatsSection() {
    final statItems = [
      {
        "label": "Total",
        "value": total,
        "color": AppColors.textPrimary,
        "icon": Icons.dashboard_rounded
      },
      {
        "label": "Approved",
        "value": approved,
        "color": AppColors.statusApproved,
        "icon": Icons.check_circle_rounded
      },
      {
        "label": "Rejected",
        "value": rejected,
        "color": AppColors.statusRejected,
        "icon": Icons.cancel_rounded
      },
      {
        "label": "Waiting",
        "value": waiting,
        "color": AppColors.statusWaiting,
        "icon": Icons.hourglass_empty_rounded
      },
      // إضافة الحالتين الجديدتين:
      {
        "label": "Needs Change",
        "value": needsChange,
        "color": AppColors.statusNeedsChange,
        "icon": Icons.edit_note_rounded
      },
      {
        "label": "Fulfilled",
        "value": fulfilled,
        "color": AppColors.statusFulfilled,
        "icon": Icons.task_alt_rounded
      },
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statBgLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.statBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statItems.map((stat) => _buildMobileStatItem(
          label: stat["label"] as String,
          value: stat["value"] as int,
          color: stat["color"] as Color,
          icon: stat["icon"] as IconData,
        )).toList(),
      ),
    );
  }

  Widget _buildMobileStatItem(
      {required String label,
        required int value,
        required Color color,
        required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context)?.translate(label.toLowerCase().replaceAll(' ', '_')) ?? label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_transactions'),
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.bodyBg,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            onChanged: (value) => _applyFilters(requests),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileFilterChip(
                  label: AppLocalizations.of(context)!.translate('priority'),
                  value: selectedPriority,
                  icon: Icons.flag_outlined,
                  onTap: () => _showMobileFilterDialog(
                    AppLocalizations.of(context)!.translate('select_priority'),
                    priorities,
                    selectedPriority,
                        (value) {
                      setState(() => selectedPriority = value);
                      _applyFilters(requests);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileFilterChip(
                  label: AppLocalizations.of(context)!.translate('type'),
                  value: selectedType,
                  icon: Icons.category_outlined,
                  onTap: () => _showMobileFilterDialog(
                    AppLocalizations.of(context)!.translate('select_type'),
                    typeNames,
                    selectedType,
                        (value) {
                      setState(() => selectedType = value);
                      _applyFilters(requests);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileFilterChip(
                  label: AppLocalizations.of(context)!.translate('status'),
                  value: selectedStatus,
                  icon: Icons.hourglass_top_outlined,
                  onTap: () => _showMobileFilterDialog(
                    AppLocalizations.of(context)!.translate('select_status'),
                    statuses,
                    selectedStatus,
                        (value) {
                      setState(() => selectedStatus = value);
                      _applyFilters(requests);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    String displayValue = value;
    if (value != 'All' && value != 'All Types') {
        displayValue = AppLocalizations.of(context)?.translate(value.toLowerCase().replaceAll(' ', '_')) ?? value;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value != 'All' && value != 'All Types')
              Text(
                displayValue.length > 8 ? displayValue.substring(0, 8) + '...' : displayValue,
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _showMobileFilterDialog(String title, List<String> options,
      String currentValue, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.only(
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
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ...options.map((option) => ListTile(
                  leading: Icon(
                    Icons.check_rounded,
                    color: option == currentValue
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                  title: Text(option,
                      style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () => onSelected(option),
                )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRequestsList() {
    if (filteredRequests.isEmpty) {
      return const EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final req = filteredRequests[index];
        final id = req["id"].toString();
        final title = req["title"] ?? "No Title";
        final type = req["type"]?["name"] ?? "N/A";
        final priority = req["priority"] ?? "N/A";
        final creator = req["creator"]?["name"] ?? "Unknown";
        final lastForwardStatus = req["lastForwardStatus"];
        final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);

        return MobileRequestCard(
          id: id,
          title: title,
          type: type,
          priority: priority,
          creator: creator,
          statusText: statusInfo['text'],
          statusColor: statusInfo['color'],
          statusIcon: statusInfo['icon'],
          onViewDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseApprovalRequestPage(requestId: id),
              ),
            );
          },
          onTrackRequest: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionTrackingPage(transactionId: id),
              ),
            );
          },
          onDeleteRequest: () => _deleteRequest(id),
        );
      },
    );
  }
}

