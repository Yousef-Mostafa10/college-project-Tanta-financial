// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
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
//   static const Color statusNeedsEditing = Color(0xFFFFB74D);
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
// class TransactionTrackingPage extends StatefulWidget {
//   final String transactionId;
//
//   const TransactionTrackingPage({super.key, required this.transactionId});
//
//   @override
//   State<TransactionTrackingPage> createState() => _TransactionTrackingPageState();
// }
//
// class _TransactionTrackingPageState extends State<TransactionTrackingPage> {
//   final String baseUrl = "http://192.168.1.3:3000";
//   String? _userToken;
//   List<dynamic> _forwards = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   Map<String, dynamic>? _transactionInfo;
//
//   // الفلاتر
//   String _selectedStatus = "All";
//   final List<String> _statusFilters = ["All", "waiting", "approved", "rejected", "needs-editing"];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     await _getUserToken();
//     await _fetchTransactionForwards();
//   }
//
//   Future<void> _getUserToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     _userToken = prefs.getString('token');
//   }
//
//   Future<void> _fetchTransactionForwards() async {
//     if (_userToken == null) {
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
//       final response = await http.get(
//         Uri.parse("$baseUrl/transactions/${widget.transactionId}/forwards"),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $_userToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _transactionInfo = data['transaction'];
//           _forwards = data['transaction']?['forwards'] ?? [];
//         });
//       } else {
//         setState(() {
//           _errorMessage = "Failed to load transaction data";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Network error: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   List<dynamic> get _filteredForwards {
//     if (_selectedStatus == "All") return _forwards;
//     return _forwards.where((forward) => forward['status'] == _selectedStatus).toList();
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'approved':
//         return AppColors.statusApproved;
//       case 'rejected':
//         return AppColors.statusRejected;
//       case 'needs-editing':
//         return AppColors.statusNeedsEditing;
//       case 'waiting':
//         return AppColors.statusWaiting;
//       default:
//         return AppColors.textMuted;
//     }
//   }
//
//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'approved':
//         return Icons.check_circle_rounded; // ⬅️ أيقونة مختلفة للموافقة
//       case 'rejected':
//         return Icons.cancel_rounded; // ⬅️ أيقونة مختلفة للرفض
//       case 'needs-editing':
//         return Icons.edit_note_rounded;
//       case 'waiting':
//         return Icons.hourglass_empty_rounded; // ⬅️ أيقونة مختلفة للانتظار
//       default:
//         return Icons.help_rounded;
//     }
//   }
//
//   String _formatDate(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       return DateFormat('MMM dd, yyyy - HH:mm').format(date);
//     } catch (e) {
//       return dateString;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;
//     final isTablet = width >= 600 && width < 1024;
//     final isDesktop = width >= 1024;
//
//     return Scaffold(
//       backgroundColor: AppColors.bodyBg,
//       appBar: AppBar(
//         title: Text(
//           'Transaction Tracking',
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
//             onPressed: _fetchTransactionForwards,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState(isMobile)
//           : _errorMessage != null
//           ? _buildErrorState(isMobile)
//           : _buildMainContent(isMobile, isTablet, isDesktop),
//     );
//   }
//
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
//             'Loading transaction tracking...',
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
//   Widget _buildErrorState(bool isMobile) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(isMobile ? 20 : 40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline_rounded, size: isMobile ? 48 : 64, color: AppColors.accentRed),
//             SizedBox(height: isMobile ? 12 : 16),
//             Text(
//               _errorMessage!,
//               style: TextStyle(
//                 fontSize: isMobile ? 14 : 16,
//                 color: AppColors.textPrimary,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: isMobile ? 16 : 20),
//             ElevatedButton.icon(
//               onPressed: _fetchTransactionForwards,
//               icon: Icon(Icons.refresh_rounded, size: isMobile ? 18 : 20),
//               label: Text('Try Again', style: TextStyle(fontSize: isMobile ? 14 : 16)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isMobile ? 20 : 24,
//                   vertical: isMobile ? 12 : 14,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMainContent(bool isMobile, bool isTablet, bool isDesktop) {
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       child: Column(
//         children: [
//           // الهيدر مع معلومات المعاملة
//           _buildTransactionHeader(isMobile, isTablet),
//
//           // قسم الفلاتر
//           _buildFilterSection(isMobile, isTablet),
//
//           // الإحصائيات
//           _buildStatsSection(isMobile, isTablet),
//
//           // مسار التتبع
//           _forwards.isEmpty
//               ? _buildEmptyState(isMobile)
//               : _buildTrackingTimeline(isMobile, isTablet),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTransactionHeader(bool isMobile, bool isTablet) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(isMobile ? 16 : 24),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withOpacity(0.1),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(30),
//           bottomRight: Radius.circular(30),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isMobile ? 10 : 12),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//                 ),
//                 child: Icon(Icons.timeline_rounded, color: AppColors.primary, size: isMobile ? 24 : 28),
//               ),
//               SizedBox(width: isMobile ? 12 : 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Transaction #${widget.transactionId}',
//                       style: TextStyle(
//                         fontSize: isMobile ? 18 : 20,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     SizedBox(height: isMobile ? 2 : 4),
//                     Text(
//                       'Tracking ${_forwards.length} forwarding steps',
//                       style: TextStyle(
//                         fontSize: isMobile ? 12 : 14,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: isMobile ? 12 : 16),
//           // معلومات سريعة عن الحالة الحالية
//           if (_forwards.isNotEmpty) ...[
//             Container(
//               padding: EdgeInsets.all(isMobile ? 10 : 12),
//               decoration: BoxDecoration(
//                 color: AppColors.cardBg,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.statShadow,
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(_forwards.last['status']).withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: _getStatusColor(_forwards.last['status']).withOpacity(0.3)),
//                     ),
//                     child: Icon(
//                       _getStatusIcon(_forwards.last['status']),
//                       color: _getStatusColor(_forwards.last['status']),
//                       size: 20,
//                     ),
//                   ),
//                   SizedBox(width: isMobile ? 8 : 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Current Status',
//                           style: TextStyle(
//                             fontSize: isMobile ? 11 : 12,
//                             color: AppColors.textSecondary,
//                           ),
//                         ),
//                         Text(
//                           _forwards.last['status'].toString().toUpperCase(),
//                           style: TextStyle(
//                             fontSize: isMobile ? 14 : 16,
//                             fontWeight: FontWeight.bold,
//                             color: _getStatusColor(_forwards.last['status']),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Last Update',
//                         style: TextStyle(
//                           fontSize: isMobile ? 11 : 12,
//                           color: AppColors.textSecondary,
//                         ),
//                       ),
//                       Text(
//                         _formatDate(_forwards.last['updatedAt'] ?? _forwards.last['forwardedAt']),
//                         style: TextStyle(
//                           fontSize: isMobile ? 10 : 12,
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterSection(bool isMobile, bool isTablet) {
//     return Container(
//       margin: EdgeInsets.all(isMobile ? 12 : 16),
//       padding: EdgeInsets.all(isMobile ? 16 : 20),
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.statShadow,
//             blurRadius: 15,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: AppColors.statBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.filter_alt_rounded, color: AppColors.primary, size: isMobile ? 18 : 20),
//               SizedBox(width: isMobile ? 6 : 8),
//               Text(
//                 'FILTER BY STATUS',
//                 style: TextStyle(
//                   fontSize: isMobile ? 12 : 14,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: isMobile ? 12 : 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: _statusFilters.map((status) {
//               final isSelected = _selectedStatus == status;
//               final statusColor = _getStatusColor(status);
//
//               return FilterChip(
//                 selected: isSelected,
//                 label: Text(
//                   status == "All" ? "All" : status.toUpperCase(),
//                   style: TextStyle(
//                     fontSize: isMobile ? 11 : 12,
//                     color: isSelected ? Colors.white : AppColors.textPrimary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 backgroundColor: AppColors.bodyBg,
//                 selectedColor: status == "All" ? AppColors.primary : statusColor,
//                 checkmarkColor: Colors.white,
//                 avatar: status != "All" ? Icon(
//                   _getStatusIcon(status),
//                   size: isMobile ? 14 : 16,
//                   color: isSelected ? Colors.white : statusColor,
//                 ) : null,
//                 onSelected: (selected) {
//                   setState(() {
//                     _selectedStatus = selected ? status : "All";
//                   });
//                 },
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatsSection(bool isMobile, bool isTablet) {
//     final total = _forwards.length;
//     final waiting = _forwards.where((f) => f['status'] == 'waiting').length;
//     final approved = _forwards.where((f) => f['status'] == 'approved').length;
//     final rejected = _forwards.where((f) => f['status'] == 'rejected').length;
//     final needsEditing = _forwards.where((f) => f['status'] == 'needs-editing').length;
//
//     final statItems = [
//       {"label": "Total", "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
//       {"label": "Waiting", "value": waiting, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
//       {"label": "Approved", "value": approved, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
//       {"label": "Others", "value": rejected + needsEditing, "color": AppColors.statusNeedsEditing, "icon": Icons.more_horiz_rounded},
//     ];
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
//       padding: EdgeInsets.all(isMobile ? 16 : 20),
//       decoration: BoxDecoration(
//         color: AppColors.statBgLight, // ⬅️ استخدام درجة فاتحة من اللون الأساسي
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
//         children: statItems.map((stat) => _buildStatItem(
//           label: stat["label"] as String,
//           value: stat["value"] as int,
//           color: stat["color"] as Color,
//           icon: stat["icon"] as IconData,
//           isMobile: isMobile,
//         )).toList(),
//       ),
//     );
//   }
//
//   Widget _buildStatItem({required String label, required int value, required Color color, required IconData icon, required bool isMobile}) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(isMobile ? 8 : 10),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(color: color.withOpacity(0.3), width: 1),
//           ),
//           child: Icon(icon, color: color, size: isMobile ? 18 : 20),
//         ),
//         SizedBox(height: isMobile ? 6 : 8),
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isMobile ? 10 : 12,
//             color: AppColors.textSecondary,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildEmptyState(bool isMobile) {
//     return Container(
//       height: 300,
//       child: Center(
//         child: Padding(
//           padding: EdgeInsets.all(isMobile ? 20 : 40),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isMobile ? 20 : 24),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//                 ),
//                 child: Icon(Icons.timeline_rounded, size: isMobile ? 48 : 64, color: AppColors.primary),
//               ),
//               SizedBox(height: isMobile ? 16 : 24),
//               Text(
//                 "No forwarding history found",
//                 style: TextStyle(
//                   fontSize: isMobile ? 18 : 20,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primary,
//                 ),
//               ),
//               SizedBox(height: isMobile ? 6 : 8),
//               Text(
//                 "This transaction hasn't been forwarded to any users yet",
//                 style: TextStyle(
//                   fontSize: isMobile ? 12 : 14,
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTrackingTimeline(bool isMobile, bool isTablet) {
//     final filteredForwards = _filteredForwards;
//
//     return Padding(
//       padding: EdgeInsets.all(isMobile ? 12 : 16),
//       child: ListView.separated(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: filteredForwards.length,
//         separatorBuilder: (context, index) => SizedBox(height: isMobile ? 8 : 12),
//         itemBuilder: (context, index) {
//           final forward = filteredForwards[index];
//           final isFirst = index == 0;
//           final isLast = index == filteredForwards.length - 1;
//
//           return _buildTimelineStep(
//             forward: forward,
//             stepNumber: filteredForwards.length - index,
//             isFirst: isFirst,
//             isLast: isLast,
//             totalSteps: filteredForwards.length,
//             isMobile: isMobile,
//             isTablet: isTablet,
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTimelineStep({
//     required dynamic forward,
//     required int stepNumber,
//     required bool isFirst,
//     required bool isLast,
//     required int totalSteps,
//     required bool isMobile,
//     required bool isTablet,
//   }) {
//     final statusColor = _getStatusColor(forward['status']);
//     final statusIcon = _getStatusIcon(forward['status']);
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // الخط الزمني العمودي
//           Column(
//             children: [
//               // الدائرة العلوية (للخط)
//               if (!isFirst) ...[
//                 Container(
//                   width: 2,
//                   height: isMobile ? 16 : 20,
//                   color: AppColors.primary.withOpacity(0.3),
//                 ),
//               ],
//               // الدائرة الرئيسية
//               Container(
//                 width: isMobile ? 32 : 40,
//                 height: isMobile ? 32 : 40,
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: statusColor, width: 2),
//                 ),
//                 child: Center(
//                   child: Text(
//                     stepNumber.toString(),
//                     style: TextStyle(
//                       fontSize: isMobile ? 12 : 14,
//                       fontWeight: FontWeight.bold,
//                       color: statusColor,
//                     ),
//                   ),
//                 ),
//               ),
//               // الخط السفلي (للخط)
//               if (!isLast) ...[
//                 Container(
//                   width: 2,
//                   height: isMobile ? 16 : 20,
//                   color: AppColors.primary.withOpacity(0.3),
//                 ),
//               ],
//             ],
//           ),
//           SizedBox(width: isMobile ? 12 : 16),
//
//           // محتوى الخطوة
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(isMobile ? 12 : 16),
//               decoration: BoxDecoration(
//                 color: AppColors.cardBg,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.statShadow,
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//                 border: Border.all(
//                   color: statusColor.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // الهيدر - المرسل والمستقبل
//                   Row(
//                     children: [
//                       // المرسل
//                       Expanded(
//                         child: _buildUserCard(
//                           forward['sender'],
//                           'From',
//                           Icons.person_outline_rounded,
//                           AppColors.accentBlue,
//                           isMobile,
//                         ),
//                       ),
//                       SizedBox(width: isMobile ? 6 : 8),
//                       // السهم
//                       Container(
//                         padding: EdgeInsets.all(isMobile ? 3 : 4),
//                         decoration: BoxDecoration(
//                           color: AppColors.primary.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                           border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//                         ),
//                         child: Icon(Icons.arrow_forward_rounded, size: isMobile ? 14 : 16, color: AppColors.primary),
//                       ),
//                       SizedBox(width: isMobile ? 6 : 8),
//                       // المستقبل
//                       Expanded(
//                         child: _buildUserCard(
//                           forward['receiver'],
//                           'To',
//                           Icons.person_rounded,
//                           AppColors.accentGreen,
//                           isMobile,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: isMobile ? 8 : 12),
//
//                   // معلومات الحالة والوقت
//                   Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: isMobile ? 10 : 12,
//                           vertical: isMobile ? 4 : 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: statusColor.withOpacity(0.3)),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(statusIcon, size: isMobile ? 14 : 16, color: statusColor),
//                             SizedBox(width: isMobile ? 4 : 6),
//                             Text(
//                               forward['status'].toString().toUpperCase(),
//                               style: TextStyle(
//                                 fontSize: isMobile ? 10 : 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: statusColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         _formatDate(forward['forwardedAt']),
//                         style: TextStyle(
//                           fontSize: isMobile ? 10 : 12,
//                           color: AppColors.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   // وقت التحديث إذا كان مختلفاً
//                   if (forward['updatedAt'] != null && forward['updatedAt'] != forward['forwardedAt']) ...[
//                     SizedBox(height: isMobile ? 6 : 8),
//                     Text(
//                       'Updated: ${_formatDate(forward['updatedAt'])}',
//                       style: TextStyle(
//                         fontSize: isMobile ? 10 : 11,
//                         color: AppColors.textMuted,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUserCard(Map<String, dynamic>? user, String label, IconData icon, Color color, bool isMobile) {
//     final userName = user?['name'] ?? 'Unknown';
//     final userGroup = user?['group'] ?? 'N/A';
//
//     return Container(
//       padding: EdgeInsets.all(isMobile ? 8 : 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: isMobile ? 12 : 14, color: color),
//               SizedBox(width: isMobile ? 3 : 4),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: isMobile ? 10 : 12,
//                   color: color,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: isMobile ? 2 : 4),
//           Text(
//             userName,
//             style: TextStyle(
//               fontSize: isMobile ? 12 : 14,
//               fontWeight: FontWeight.bold,
//               color: AppColors.textPrimary,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           Text(
//             userGroup,
//             style: TextStyle(
//               fontSize: isMobile ? 9 : 11,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'tracking_colors.dart';
import 'tracking_api.dart';
import 'tracking_helpers.dart';
import 'tracking_header.dart';
import 'tracking_filters.dart';
import 'tracking_stats.dart';
import 'tracking_empty_state.dart';
import 'tracking_loading_state.dart';
import 'tracking_error_state.dart';
import 'tracking_timeline.dart';

class TransactionTrackingPage extends StatefulWidget {
  final String transactionId;

  const TransactionTrackingPage({super.key, required this.transactionId});

  @override
  State<TransactionTrackingPage> createState() => _TransactionTrackingPageState();
}

class _TransactionTrackingPageState extends State<TransactionTrackingPage> {
  final String baseUrl = "http://192.168.1.3:3000";
  String? _userToken;
  List<dynamic> _forwards = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _transactionInfo;

  // الفلاتر
  String _selectedStatus = "All";
  final List<String> _statusFilters = ["All", "waiting", "approved", "rejected", "needs-editing"];

  late TrackingApi _api;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserToken();
    await _fetchTransactionForwards();
  }

  Future<void> _getUserToken() async {
    _userToken = await TrackingApi.getUserToken();
  }

  Future<void> _fetchTransactionForwards() async {
    if (_userToken == null) {
      setState(() {
        _errorMessage = "Please login first";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _api = TrackingApi(baseUrl: baseUrl, userToken: _userToken);
    final result = await _api.fetchTransactionForwards(widget.transactionId);

    setState(() {
      if (result['success'] == true) {
        _transactionInfo = result['transaction'];
        _forwards = result['forwards'];
      } else {
        _errorMessage = result['error'];
      }
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredForwards {
    if (_selectedStatus == "All") return _forwards;
    return _forwards.where((forward) => forward['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: TrackingColors.bodyBg,
      appBar: AppBar(
        title: Text(
          'Transaction Tracking',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TrackingColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
            onPressed: _fetchTransactionForwards,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? buildLoadingState(isMobile)
          : _errorMessage != null
          ? buildErrorState(
        errorMessage: _errorMessage!,
        onRetry: _fetchTransactionForwards,
        isMobile: isMobile,
      )
          : _buildMainContent(isMobile, isTablet),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // الهيدر مع معلومات المعاملة
          buildTransactionHeader(
            transactionId: widget.transactionId,
            forwards: _forwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // قسم الفلاتر
          buildFilterSection(
            selectedStatus: _selectedStatus,
            statusFilters: _statusFilters,
            onStatusChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // الإحصائيات
          buildStatsSection(
            forwards: _forwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),

          // مسار التتبع
          _forwards.isEmpty
              ? buildEmptyState(isMobile: isMobile, isTablet: isTablet)
              : buildTrackingTimeline(
            forwards: _filteredForwards,
            isMobile: isMobile,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }
}