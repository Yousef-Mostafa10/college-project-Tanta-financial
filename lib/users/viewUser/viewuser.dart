// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
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
//
//   // Role Colors
//   static const Color roleAdmin = Color(0xFFE74C3C);
//   static const Color roleUser = Color(0xFF27AE60);
//
//   // Border Colors
//   static const Color borderColor = Color(0xFFE0E0E0);
//   static const Color focusBorderColor = Color(0xFF00695C);
//
//   // Gradient Colors
//   static const Color gradientStart = Color(0xFFE0F2F1);
//   static const Color gradientEnd = Color(0xFFB2DFDB);
//
//   // Filter Colors
//   static const Color filterSelectedBg = Color(0xFFE0F2F1);
//   static const Color filterSelectedBorder = Color(0xFF00695C);
// }
//
// class User {
//   final String name;
//   final String group;
//   final String createdAt;
//   final String updatedAt;
//
//   User({
//     required this.name,
//     required this.group,
//     required this.createdAt,
//     required this.updatedAt,
//   });
// }
//
// class ViewUsersPage extends StatefulWidget {
//   const ViewUsersPage({super.key});
//
//   @override
//   State<ViewUsersPage> createState() => _ViewUsersPageState();
// }
//
// class _ViewUsersPageState extends State<ViewUsersPage> {
//   List<User> _users = [];
//   bool _isLoading = false;
//   bool _isLoadingMore = false;
//   int _pageNumber = 1;
//   final int _pageSize = 10;
//   bool _hasMore = true;
//   String _searchQuery = '';
//   String _selectedFilter = 'all';
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 100 &&
//           !_isLoadingMore &&
//           _hasMore &&
//           _searchQuery.isEmpty &&
//           _selectedFilter == 'all') { // الفلتر الداخلي بيوقف الـ pagination
//         _loadMoreUsers();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadUsers() async {
//     setState(() {
//       _isLoading = true;
//       _pageNumber = 1;
//       _hasMore = true;
//       _users.clear();
//     });
//
//     await _fetchUsers();
//     setState(() => _isLoading = false);
//   }
//
//   Future<void> _loadMoreUsers() async {
//     if (!_hasMore || _isLoadingMore) return;
//
//     setState(() => _isLoadingMore = true);
//     await _fetchUsers();
//     setState(() => _isLoadingMore = false);
//   }
//
//   Future<void> _fetchUsers() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       final url = Uri.parse("http://192.168.1.3:3000/users?pageNumber=$_pageNumber&pageSize=$_pageSize");
//
//       final response = await http.get(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         if (data["status"] == "success") {
//           List<User> fetchedUsers = [];
//
//           for (var u in data["users"]) {
//             fetchedUsers.add(User(
//               name: u["name"] ?? "Unknown",
//               group: u["group"] ?? "user",
//               createdAt: u["createdAt"] ?? "",
//               updatedAt: u["updatedAt"] ?? u["createdAt"] ?? "",
//             ));
//           }
//
//           setState(() {
//             _users.addAll(fetchedUsers);
//
//             final pageInfo = data["page"];
//             if (pageInfo != null) {
//               final currentPage = pageInfo["number"] ?? _pageNumber;
//               final lastPage = pageInfo["last"] ?? 1;
//               _hasMore = currentPage < lastPage;
//               if (_hasMore) _pageNumber = currentPage + 1;
//             } else {
//               _hasMore = fetchedUsers.length == _pageSize;
//               if (_hasMore) _pageNumber++;
//             }
//           });
//         }
//       } else if (response.statusCode == 401) {
//         _showErrorMessage("⛔ Unauthorized — Please log in again.");
//       } else {
//         _showErrorMessage("Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error fetching users: $e");
//       _showErrorMessage("⚠️ Connection error");
//     }
//   }
//
//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: AppColors.statusRejected,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: AppColors.statusApproved,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   List<User> get _filteredUsers {
//     List<User> filtered = _users;
//
//     // البحث المحلي
//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where((u) =>
//           u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
//           .toList();
//     }
//
//     // الفلتر المحلي حسب النوع
//     if (_selectedFilter != 'all') {
//       filtered = filtered
//           .where((u) => u.group.toLowerCase() == _selectedFilter)
//           .toList();
//     }
//
//     return filtered;
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
//           'Users Management',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: isMobile ? 18 : 20,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // Search and Filter Section
//           Container(
//             padding: EdgeInsets.all(isMobile ? 12 : 16),
//             decoration: BoxDecoration(
//               color: AppColors.cardBg,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Search Field
//                 TextField(
//                   onChanged: (value) => setState(() => _searchQuery = value),
//                   decoration: InputDecoration(
//                     hintText: 'Search users...',
//                     hintStyle: TextStyle(color: AppColors.textMuted),
//                     prefixIcon: Icon(
//                         Icons.search,
//                         color: AppColors.primary,
//                         size: isMobile ? 20 : 24
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
//                       borderSide: BorderSide(
//                           color: AppColors.focusBorderColor,
//                           width: 1.5
//                       ),
//                     ),
//                     filled: true,
//                     fillColor: AppColors.bodyBg,
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: isMobile ? 16 : 20,
//                       vertical: isMobile ? 14 : 16,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: isMobile ? 8 : 12),
//                 _buildFilterRow(isMobile),
//               ],
//             ),
//           ),
//
//           // Users List
//           Expanded(
//             child: _isLoading
//                 ? Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//               ),
//             )
//                 : _filteredUsers.isEmpty
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.people_outline,
//                     size: isMobile ? 48 : 64,
//                     color: AppColors.textMuted,
//                   ),
//                   SizedBox(height: isMobile ? 12 : 16),
//                   Text(
//                     _selectedFilter != 'all'
//                         ? 'No ${_selectedFilter}s found'
//                         : 'No users found',
//                     style: TextStyle(
//                       fontSize: isMobile ? 16 : 18,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                   if (_selectedFilter != 'all' && _users.isNotEmpty)
//                     Padding(
//                       padding: EdgeInsets.only(top: isMobile ? 8 : 12),
//                       child: Text(
//                         'Try loading more users or change filter',
//                         style: TextStyle(
//                           fontSize: isMobile ? 12 : 14,
//                           color: AppColors.textMuted,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                 ],
//               ),
//             )
//                 : Column(
//               children: [
//                 // Header with count
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     vertical: isMobile ? 6 : 8,
//                     horizontal: isMobile ? 12 : 16,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.bodyBg,
//                     border: Border(
//                       bottom: BorderSide(color: AppColors.borderColor),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Showing ${_filteredUsers.length} ${_selectedFilter != 'all' ? _selectedFilter + 's' : 'users'}',
//                         style: TextStyle(
//                           color: AppColors.textSecondary,
//                           fontSize: isMobile ? 12 : 14,
//                         ),
//                       ),
//                       if (_hasMore && _searchQuery.isEmpty && _selectedFilter == 'all')
//                         Text(
//                           'Scroll to load more',
//                           style: TextStyle(
//                             color: AppColors.primary,
//                             fontSize: isMobile ? 10 : 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Users List
//                 Expanded(
//                   child: ListView.builder(
//                     controller: _scrollController,
//                     padding: EdgeInsets.all(isMobile ? 12 : 16),
//                     itemCount: _filteredUsers.length + (_isLoadingMore ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index == _filteredUsers.length) {
//                         return Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
//                             child: CircularProgressIndicator(
//                               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//                             ),
//                           ),
//                         );
//                       }
//                       final user = _filteredUsers[index];
//                       return _buildUserCard(user, isMobile, isTablet);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterRow(bool isMobile) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           _buildFilterChip('All', 'all', isMobile),
//           _buildFilterChip('Admins', 'admin', isMobile),
//           _buildFilterChip('Users', 'user', isMobile),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterChip(String label, String value, bool isMobile) {
//     bool isSelected = _selectedFilter == value;
//     return Container(
//       margin: EdgeInsets.only(right: isMobile ? 6 : 8),
//       child: FilterChip(
//         label: Text(
//           label,
//           style: TextStyle(
//             fontSize: isMobile ? 12 : 14,
//             color: isSelected ? AppColors.primary : AppColors.textPrimary,
//           ),
//         ),
//         selected: isSelected,
//         onSelected: (selected) {
//           setState(() {
//             _selectedFilter = selected ? value : 'all';
//           });
//         },
//         backgroundColor: AppColors.cardBg,
//         selectedColor: AppColors.filterSelectedBg,
//         labelStyle: TextStyle(
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//         ),
//         checkmarkColor: AppColors.primary,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//           side: BorderSide(
//             color: isSelected ? AppColors.filterSelectedBorder : AppColors.borderColor,
//             width: isSelected ? 1.5 : 1,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUserCard(User user, bool isMobile, bool isTablet) {
//     return Container(
//       margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: AppColors.borderColor, width: 1),
//       ),
//       child: ListTile(
//         contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
//         leading: Container(
//           width: isMobile ? 40 : 50,
//           height: isMobile ? 40 : 50,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.gradientStart, AppColors.gradientEnd],
//             ),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             Icons.person,
//             color: AppColors.primary,
//             size: isMobile ? 18 : 22,
//           ),
//         ),
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 user.name,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textPrimary,
//                   fontSize: isMobile ? 14 : 16,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             SizedBox(width: isMobile ? 4 : 6),
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: isMobile ? 6 : 8,
//                 vertical: isMobile ? 2 : 4,
//               ),
//               decoration: BoxDecoration(
//                 color: _getRoleColor(user.group).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                 border: Border.all(
//                   color: _getRoleColor(user.group).withOpacity(0.3),
//                   width: 1,
//                 ),
//               ),
//               child: Text(
//                 user.group,
//                 style: TextStyle(
//                   fontSize: isMobile ? 9 : 10,
//                   fontWeight: FontWeight.w600,
//                   color: _getRoleColor(user.group),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         subtitle: Text(
//           "${user.name}@company.com",
//           style: TextStyle(
//             color: AppColors.textSecondary,
//             fontSize: isMobile ? 12 : 14,
//           ),
//           overflow: TextOverflow.ellipsis,
//         ),
//         trailing: PopupMenuButton<String>(
//           icon: Icon(
//             Icons.more_vert_rounded,
//             color: AppColors.textSecondary,
//             size: isMobile ? 18 : 20,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//           ),
//           onSelected: (value) {
//             if (value == 'view') {
//               _fetchUserDetails(user.name, isMobile);
//             } else if (value == 'change_password') {
//               _showChangePasswordDialog(user.name, isMobile);
//             }
//           },
//           itemBuilder: (context) => [
//             PopupMenuItem(
//               value: 'view',
//               child: Row(
//                 children: [
//                   Icon(Icons.remove_red_eye_rounded,
//                       color: AppColors.primary,
//                       size: isMobile ? 16 : 18
//                   ),
//                   SizedBox(width: isMobile ? 6 : 8),
//                   Text(
//                     'View Profile',
//                     style: TextStyle(
//                       fontSize: isMobile ? 13 : 14,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             PopupMenuItem(
//               value: 'change_password',
//               child: Row(
//                 children: [
//                   Icon(Icons.lock_reset_rounded,
//                       color: AppColors.accentBlue,
//                       size: isMobile ? 16 : 18
//                   ),
//                   SizedBox(width: isMobile ? 6 : 8),
//                   Text(
//                     'Change Password',
//                     style: TextStyle(
//                       fontSize: isMobile ? 13 : 14,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _showChangePasswordDialog(String userName, bool isMobile) async {
//     final newPasswordController = TextEditingController();
//     final confirmPasswordController = TextEditingController();
//     bool isLoading = false;
//     bool showNewPassword = false;
//     bool showConfirmPassword = false;
//
//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           backgroundColor: AppColors.cardBg,
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(isMobile ? 16 : 20)
//           ),
//           title: Text(
//             'Change Password',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//               fontSize: isMobile ? 18 : 20,
//             ),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Change password for $userName',
//                   style: TextStyle(
//                     color: AppColors.textSecondary,
//                     fontSize: isMobile ? 14 : 16,
//                   ),
//                 ),
//                 SizedBox(height: isMobile ? 16 : 20),
//
//                 // New Password Field with toggle
//                 TextField(
//                   controller: newPasswordController,
//                   obscureText: !showNewPassword,
//                   decoration: InputDecoration(
//                     labelText: 'New Password',
//                     labelStyle: TextStyle(color: AppColors.textSecondary),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(
//                         color: AppColors.focusBorderColor,
//                         width: 1.5,
//                       ),
//                     ),
//                     prefixIcon: Icon(
//                         Icons.lock_outline_rounded,
//                         color: AppColors.primary,
//                         size: isMobile ? 20 : 24
//                     ),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         showNewPassword
//                             ? Icons.visibility_rounded
//                             : Icons.visibility_off_rounded,
//                         color: AppColors.textSecondary,
//                         size: isMobile ? 18 : 20,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           showNewPassword = !showNewPassword;
//                         });
//                       },
//                     ),
//                     filled: true,
//                     fillColor: AppColors.bodyBg,
//                   ),
//                 ),
//                 SizedBox(height: isMobile ? 10 : 12),
//
//                 // Confirm Password Field with toggle
//                 TextField(
//                   controller: confirmPasswordController,
//                   obscureText: !showConfirmPassword,
//                   decoration: InputDecoration(
//                     labelText: 'Confirm Password',
//                     labelStyle: TextStyle(color: AppColors.textSecondary),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(color: AppColors.borderColor),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                       borderSide: BorderSide(
//                         color: AppColors.focusBorderColor,
//                         width: 1.5,
//                       ),
//                     ),
//                     prefixIcon: Icon(
//                         Icons.lock_outline_rounded,
//                         color: AppColors.primary,
//                         size: isMobile ? 20 : 24
//                     ),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         showConfirmPassword
//                             ? Icons.visibility_rounded
//                             : Icons.visibility_off_rounded,
//                         color: AppColors.textSecondary,
//                         size: isMobile ? 18 : 20,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           showConfirmPassword = !showConfirmPassword;
//                         });
//                       },
//                     ),
//                     filled: true,
//                     fillColor: AppColors.bodyBg,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: isLoading ? null : () => Navigator.pop(context),
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: AppColors.textSecondary,
//                   fontSize: isMobile ? 14 : 16,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: isLoading ? null : () async {
//                 if (newPasswordController.text.isEmpty) {
//                   _showErrorMessage("Please enter new password");
//                   return;
//                 }
//                 if (newPasswordController.text != confirmPasswordController.text) {
//                   _showErrorMessage("Passwords don't match");
//                   return;
//                 }
//                 if (newPasswordController.text.length < 6) {
//                   _showErrorMessage("Password must be at least 6 characters");
//                   return;
//                 }
//
//                 setState(() => isLoading = true);
//                 await _changePassword(userName, newPasswordController.text);
//                 setState(() => isLoading = false);
//
//                 if (context.mounted) {
//                   Navigator.pop(context);
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
//                 ),
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isMobile ? 16 : 20,
//                   vertical: isMobile ? 10 : 12,
//                 ),
//               ),
//               child: isLoading
//                   ? SizedBox(
//                 height: isMobile ? 18 : 20,
//                 width: isMobile ? 18 : 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               )
//                   : Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.lock_reset_rounded,
//                     size: isMobile ? 16 : 18,
//                   ),
//                   SizedBox(width: isMobile ? 4 : 6),
//                   Text(
//                     'Change Password',
//                     style: TextStyle(fontSize: isMobile ? 14 : 16),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _changePassword(String userName, String newPassword) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       final url = Uri.parse("http://192.168.1.3:3000/users/$userName");
//
//       final response = await http.patch(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({
//           "password": newPassword,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data["status"] == "success") {
//           _showSuccessMessage("Password changed successfully for $userName");
//         } else {
//           _showErrorMessage(data["message"] ?? "Failed to change password");
//         }
//       } else if (response.statusCode == 403) {
//         _showErrorMessage("⛔ You don't have permission to change this user's password");
//       } else if (response.statusCode == 404) {
//         _showErrorMessage("⛔ User not found");
//       } else if (response.statusCode == 401) {
//         _showErrorMessage("⛔ Unauthorized — Please log in again.");
//       } else {
//         _showErrorMessage("Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error changing password: $e");
//       _showErrorMessage("⚠️ Connection error");
//     }
//   }
//
//   Future<void> _fetchUserDetails(String userName, bool isMobile) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Center(
//         child: CircularProgressIndicator(
//           valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//         ),
//       ),
//     );
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token') ?? '';
//
//       final url = Uri.parse("http://192.168.1.3:3000/users/$userName");
//       final response = await http.get(url, headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       });
//
//       Navigator.pop(context);
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data["status"] == "success") {
//           final u = data["user"];
//
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               backgroundColor: AppColors.cardBg,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(isMobile ? 16 : 20)
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: isMobile ? 60 : 70,
//                     height: isMobile ? 60 : 70,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [AppColors.gradientStart, AppColors.gradientEnd],
//                       ),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.person,
//                       size: isMobile ? 30 : 36,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   SizedBox(height: isMobile ? 12 : 16),
//                   Text(
//                     u["name"] ?? "",
//                     style: TextStyle(
//                       fontSize: isMobile ? 16 : 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   SizedBox(height: isMobile ? 8 : 12),
//                   _buildProfileDetail(
//                       "Group",
//                       u["group"] ?? "Unknown",
//                       Icons.group_rounded,
//                       isMobile
//                   ),
//                   _buildProfileDetail(
//                       "Created At",
//                       _formatDate(u["createdAt"]),
//                       Icons.calendar_today_rounded,
//                       isMobile
//                   ),
//                   _buildProfileDetail(
//                       "Updated At",
//                       _formatDate(u["updatedAt"] ?? u["createdAt"]),
//                       Icons.update_rounded,
//                       isMobile
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(
//                     "Close",
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontSize: isMobile ? 14 : 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       } else {
//         _showErrorMessage("Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       _showErrorMessage("Connection Error: $e");
//     }
//   }
//
//   Widget _buildProfileDetail(String label, String value, IconData icon, bool isMobile) {
//     return Container(
//       margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
//       padding: EdgeInsets.all(isMobile ? 8 : 10),
//       decoration: BoxDecoration(
//         color: AppColors.bodyBg,
//         borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
//         border: Border.all(color: AppColors.borderColor),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: AppColors.primary,
//             size: isMobile ? 16 : 18,
//           ),
//           SizedBox(width: isMobile ? 8 : 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: isMobile ? 11 : 12,
//                     color: AppColors.textSecondary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: isMobile ? 12 : 14,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDate(String? iso) {
//     if (iso == null || iso.isEmpty) return "Unknown";
//     try {
//       final dt = DateTime.parse(iso);
//       return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
//     } catch (e) {
//       return iso;
//     }
//   }
//
//   Color _getRoleColor(String role) {
//     switch (role.toLowerCase()) {
//       case 'admin':
//         return AppColors.roleAdmin;
//       case 'user':
//         return AppColors.roleUser;
//       default:
//         return AppColors.textSecondary;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'user_model.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'users_search_filter.dart';
import 'user_card.dart';
import 'users_empty_state.dart';
import 'users_list_header.dart';

class ViewUsersPage extends StatefulWidget {
  const ViewUsersPage({super.key});

  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  final UsersApiService _apiService = UsersApiService();
  final List<User> _users = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _pageNumber = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchQuery.isEmpty &&
        _selectedFilter == 'all') {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _pageNumber = 1;
      _hasMore = true;
      _users.clear();
    });

    await _fetchUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await _fetchUsers();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await _apiService.fetchUsers(_pageNumber, _pageSize);

      if (data["status"] == "success") {
        List<User> fetchedUsers = [];

        for (var u in data["users"]) {
          fetchedUsers.add(User.fromJson(u));
        }

        setState(() {
          _users.addAll(fetchedUsers);

          final pageInfo = data["page"];
          if (pageInfo != null) {
            final currentPage = pageInfo["number"] ?? _pageNumber;
            final lastPage = pageInfo["last"] ?? 1;
            _hasMore = currentPage < lastPage;
            if (_hasMore) _pageNumber = currentPage + 1;
          } else {
            _hasMore = fetchedUsers.length == _pageSize;
            if (_hasMore) _pageNumber++;
          }
        });
      }
    } catch (e) {
      UsersHelpers.showErrorMessage(context, e.toString());
    }
  }

  List<User> get _filteredUsers {
    List<User> filtered = _users;

    // البحث المحلي
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // الفلتر المحلي حسب النوع
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((u) => u.group.toLowerCase() == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        title: Text(
          'Users Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          UsersSearchFilter(
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onFilterChanged: (value) => setState(() => _selectedFilter = value),
            isMobile: isMobile,
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : _filteredUsers.isEmpty
                ? UsersEmptyState(
              selectedFilter: _selectedFilter,
              hasUsers: _users.isNotEmpty,
              isMobile: isMobile,
            )
                : Column(
              children: [
                // Header with count
                UsersListHeader(
                  filteredUsersCount: _filteredUsers.length,
                  selectedFilter: _selectedFilter,
                  hasMore: _hasMore,
                  searchQuery: _searchQuery,
                  isMobile: isMobile,
                ),

                // Users List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    itemCount: _filteredUsers.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredUsers.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                            child: CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        );
                      }
                      final user = _filteredUsers[index];
                      return UserCard(
                        user: user,
                        apiService: _apiService,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}