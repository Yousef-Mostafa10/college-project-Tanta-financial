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
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _errorMessage;
  String? _userName;
  String? _userToken;

  // إحصائيات من الـ API Summary
  int _totalCount = 0;
  int _waitingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _needsEditingCount = 0;

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
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
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

  // 🔹 جلب الطلبات - صفحة واحدة
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
      _requests = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await _api.fetchMyRequests(page: 1, perPage: 10);

      if (result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final summary = result['summary'] as Map<String, dynamic>?;
        final rawData = result['data'] as List<dynamic>? ?? [];

        // استخدام الحالات القادمة من السيرفر مباشرة لتحسين الأداء
        final updatedRequests = rawData.map((req) {
          final request = Map<String, dynamic>.from(req);
          String status = (request["lastForwardStatus"] ?? "waiting").toString().toLowerCase();
          
          if (request["fulfilled"] == true) {
            status = "fulfilled";
          }
          
          request["status"] = status; // توحيد الحقل المستخدم في العرض
          return request;
        }).toList();

        setState(() {
          _requests = updatedRequests;
          _currentPage = pagination?['currentPage'] ?? 1;
          _hasMore = pagination?['next'] != null;
          _totalCount = pagination?['total'] ?? _requests.length;

          // إحصائيات من الـ Summary
          if (summary != null) {
            _waitingCount = summary['WAITING'] ?? 0;
            _approvedCount = summary['APPROVED'] ?? 0;
            _rejectedCount = summary['REJECTED'] ?? 0;
            _needsEditingCount = summary['NEEDS_EDITING'] ?? 0;
          }

          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? AppLocalizations.of(context)!.translate('failed_load_requests');
        });
      }
    } catch (e) {
      print("❌ Error fetching requests: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.translate('failed_load_requests');
      });
    }
  }

  // 🔹 تحميل المزيد عند الـ scroll
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _api.fetchMyRequests(page: nextPage, perPage: 10);

      if (mounted && result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final newRawRequests = result['data'] as List<dynamic>? ?? [];

        // استخدام الحالات القادمة من السيرفر مباشرة
        final updatedNewRequests = newRawRequests.map((req) {
          final request = Map<String, dynamic>.from(req);
          String status = (request["lastForwardStatus"] ?? "waiting").toString().toLowerCase();
          
          if (request["fulfilled"] == true) {
            status = "fulfilled";
          }
          
          request["status"] = status;
          return request;
        }).toList();

        setState(() {
          _requests.addAll(updatedNewRequests);
          _currentPage = pagination?['currentPage'] ?? nextPage;
          _hasMore = pagination?['next'] != null;
          _applyFilters();
        });
      }
    } catch (e) {
      print("❌ Error loading more: $e");
    }

    if (mounted) setState(() => _isLoadingMore = false);
  }

  // 🔹 تطبيق الفلاتر محلياً
  void _applyFilters() {
    List<dynamic> filtered = _requests;

    // فلترة النوع
    if (_selectedType != "All Types") {
      filtered = filtered.where((request) {
        final type = request["typeName"] ?? request["type"]?["name"] ?? "";
        return type == _selectedType;
      }).toList();
    }

    // فلترة الأولوية
    if (_selectedPriority != "All") {
      filtered = filtered.where((request) {
        final priority = request["priority"] ?? "";
        return priority.toUpperCase() == _selectedPriority.toUpperCase();
      }).toList();
    }

    // فلترة الحالة
    if (_selectedStatus != "All") {
      filtered = filtered.where((request) {
        final lastForwardStatus = (request["lastForwardStatus"] ?? "").toString().toUpperCase();
        final fulfilled = request["fulfilled"] == true;

        switch (_selectedStatus) {
          case "Approved":
            return lastForwardStatus == "APPROVED";
          case "Rejected":
            return lastForwardStatus == "REJECTED";
          case "Waiting":
            return lastForwardStatus == "WAITING";
          case "Needs Change":
            return lastForwardStatus == "NEEDS_EDITING";
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
        _fetchMyRequests(); // إعادة جلب البيانات من السيرفر

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

  // 🔹 إلغاء التوجيه
  Future<void> _cancelForward(String transactionId, dynamic forwardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('cancel_forward_confirm_title') ?? 'Cancel Forward'),
          content: Text(AppLocalizations.of(context)!.translate('cancel_forward_confirm_content') ?? 'Are you sure you want to cancel this forward?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.translate('no_button') ?? 'No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context)!.translate('yes_button') ?? 'Yes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true; // إظهار حالة التحميل أثناء الإلغاء
    });

    try {
      final success = await _api.cancelForward(transactionId, forwardId);

      if (success) {
        await _fetchMyRequests(); // إعادة جلب البيانات لتحديث المستند

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_success') ?? 'Forward cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_cancel_forward') ?? 'Failed to cancel forward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Error cancelling forward: $e");
    }
  }

  // 🔹 فتح نافذة التوجيه (Forward)
  Future<void> _forwardTransaction(String transactionId) async {
    try {
      if (!mounted) return;

      Map<String, dynamic>? selectedUser;
      String forwardComment = '';
      List<Map<String, dynamic>> allUsers = [];
      int userPage = 1;
      bool hasMoreUsers = true;
      bool isLoadingUsers = false;
      
      TextEditingController searchController = TextEditingController();
      ScrollController dialogScrollController = ScrollController();

      // دالة لجلب المستخدمين داخل الديالوج
      Future<void> loadMoreUsers(Function setStateDialog) async {
        if (isLoadingUsers || !hasMoreUsers) return;

        setStateDialog(() => isLoadingUsers = true);
        try {
          final result = await _api.fetchUsers(page: userPage, perPage: 10);
          final List<Map<String, dynamic>> newUsers = List<Map<String, dynamic>>.from(result['users']);
          
          setStateDialog(() {
            allUsers.addAll(newUsers);
            hasMoreUsers = result['hasMore'];
            userPage++;
            isLoadingUsers = false;
          });
        } catch (e) {
          print("❌ Error loading more users: $e");
          setStateDialog(() => isLoadingUsers = false);
        }
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              // إعداد الـ ScrollListener عند أول مرة
              if (allUsers.isEmpty && !isLoadingUsers && userPage == 1) {
                loadMoreUsers(setStateDialog);
                dialogScrollController.addListener(() {
                  if (dialogScrollController.position.pixels >= 
                      dialogScrollController.position.maxScrollExtent - 50) {
                    loadMoreUsers(setStateDialog);
                  }
                });
              }

              List<Map<String, dynamic>> filteredUsers = searchController.text.isEmpty 
                ? allUsers 
                : allUsers.where((u) => (u["name"]?.toString() ?? "").toLowerCase().contains(searchController.text.toLowerCase())).toList();

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(maxHeight: 500),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان الديلوج
                      Row(
                        children: [
                          Icon(Icons.person_search_rounded, color: MyRequestsColors.primary, size: 24),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.translate('select_user_hint') ?? 'Select User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MyRequestsColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // شريط البحث
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('search_users') ?? 'Search users...',
                          prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {}); // إعادة بناء القائمة للفلترة المحلية
                        },
                      ),
                      SizedBox(height: 16),

                      // قائمة المستخدمين
                      Expanded(
                        child: ListView.builder(
                          controller: dialogScrollController,
                          itemCount: filteredUsers.length + (hasMoreUsers ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredUsers.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: MyRequestsColors.primary),
                                ),
                              );
                            }

                            final user = filteredUsers[index];
                            final isSelected = selectedUser != null && selectedUser!["id"] == user["id"];

                            return ListTile(
                              leading: Icon(
                                Icons.person_rounded,
                                color: isSelected ? MyRequestsColors.primary : MyRequestsColors.textSecondary,
                              ),
                              title: Text(
                                user["name"] ?? "Unknown",
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? MyRequestsColors.primary : MyRequestsColors.textPrimary,
                                ),
                              ),
                              trailing: isSelected ? Icon(Icons.check_rounded, color: MyRequestsColors.primary) : null,
                              onTap: () => setStateDialog(() => selectedUser = user),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // حقل التعليق
                      TextField(
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('enter_comments') ?? 'Add a comment (optional)',
                          prefixIcon: Icon(Icons.comment_rounded, color: MyRequestsColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => forwardComment = value,
                      ),
                      SizedBox(height: 16),

                      // أزرار الإجراء
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MyRequestsColors.primary,
                                side: BorderSide(color: MyRequestsColors.primary),
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('no') ?? 'Cancel'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedUser == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _performForwardAction(transactionId, selectedUser!["id"], forwardComment);
                                    },
                              style: ElevatedButton.styleFrom(backgroundColor: MyRequestsColors.primary),
                              child: Text(
                                AppLocalizations.of(context)!.translate('forward') ?? 'Forward',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      print("❌ Error in _forwardTransaction: $e");
    }
  }

  // 🔹 تنفيذ عملية التوجيه فعلياً
  Future<void> _performForwardAction(String transactionId, dynamic receiverId, String comment) async {
    setState(() => _isLoading = true);
    try {
      final success = await _api.forwardTransaction(
        transactionId,
        receiverId is int ? receiverId : int.parse(receiverId.toString()),
        comment: comment.isNotEmpty ? comment : null,
      );

      if (success) {
        await _fetchMyRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('transaction_forwarded_success') ?? 'Forwarded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_forward') ?? 'Failed to forward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Error in _performForwardAction: $e");
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
          : Stack(
              children: [
                isMobile ? _buildMobileBody() : _buildDesktopBody(),
                if (_isLoadingMore)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(MyRequestsColors.primary),
                    ),
                  ),
              ],
            ),
    );
  }

  // ⭐ تصميم الجوال
  Widget _buildMobileBody() {
    final fulfilledForwards = _requests.where((req) => req["fulfilled"] == true).length;

    return Column(
      children: [
        // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات من الـ Summary
        buildMobileStatsSection(context, _totalCount, _approvedCount, _rejectedCount, _waitingCount, _needsEditingCount, fulfilledForwards),

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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filteredRequests.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredRequests.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(MyRequestsColors.primary),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final req = _filteredRequests[index];
        final id = req["id"].toString();
        final title = req["title"] ?? "No Title";
        final type = req["typeName"] ?? req["type"]?["name"] ?? AppLocalizations.of(context)!.translate('not_available');
        String priority = req["priority"] ?? AppLocalizations.of(context)!.translate('not_available');
        if (priority.toUpperCase() == 'HIGH') priority = AppLocalizations.of(context)!.translate('priority_high');
        else if (priority.toUpperCase() == 'MEDIUM') priority = AppLocalizations.of(context)!.translate('priority_medium');
        else if (priority.toUpperCase() == 'LOW') priority = AppLocalizations.of(context)!.translate('priority_low');

        final createdAt = req["createdAt"] ?? req["created_at"];
        final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

        final lastForwardStatus = (req["lastForwardStatus"] ?? "").toString().toUpperCase();
        final fulfilled = req["fulfilled"] == true;

        final documentsCount = req["documentsCount"] ?? (req["documents"] as List?)?.length ?? 0;

        final String status;
        final Color statusColor;
        final IconData statusIcon;

        if (fulfilled) {
          status = AppLocalizations.of(context)!.translate('status_fulfilled');
          statusColor = MyRequestsColors.statusFulfilled;
          statusIcon = Icons.task_alt_rounded;
        } else {
          switch (lastForwardStatus) {
            case "APPROVED":
              status = AppLocalizations.of(context)!.translate('status_approved');
              statusColor = MyRequestsColors.statusApproved;
              statusIcon = Icons.check_circle_rounded;
              break;
            case "REJECTED":
              status = AppLocalizations.of(context)!.translate('status_rejected');
              statusColor = MyRequestsColors.statusRejected;
              statusIcon = Icons.cancel_rounded;
              break;
            case "NEEDS_EDITING":
              status = AppLocalizations.of(context)!.translate('status_needs_editing');
              statusColor = MyRequestsColors.statusNeedsChange;
              statusIcon = Icons.edit_note_rounded;
              break;
            case "WAITING":
            default:
              status = AppLocalizations.of(context)!.translate('status_waiting');
              statusColor = MyRequestsColors.statusWaiting;
              statusIcon = Icons.hourglass_empty_rounded;
          }
        }

        final lastForwardSentTo = req["lastForwardSentTo"];

        return buildMobileRequestCard(
          id: id,
          title: title,
          type: type,
          priority: priority,
          date: formattedDate,
          statusText: status,
          statusColor: statusColor,
          statusIcon: statusIcon,
          documentsCount: documentsCount,
          context: context,
          lastForwardSentTo: lastForwardSentTo,
          onCancelForward: lastForwardSentTo != null
              ? () => _cancelForward(id, lastForwardSentTo['id'])
              : null,
          onForward: lastForwardSentTo == null
              ? () => _forwardTransaction(id)
              : null,
          onDelete: _deleteRequest,
        );
      },
    );
  }

  // ⭐ تصميم الديسكتوب
  Widget _buildDesktopBody() {
    return SingleChildScrollView(
      controller: _scrollController,
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
            _buildDesktopHeader(_totalCount),
            SizedBox(height: 16),
            _buildDesktopRequestsList(),

            // مؤشر تحميل المزيد
            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(MyRequestsColors.primary),
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatsRow() {
    final fulfilledForwards = _requests.where((req) => req["fulfilled"] == true).length;

    return buildDesktopStatsRow(
        context,
        _totalCount,
        _approvedCount,
        _rejectedCount,
        _waitingCount,
        _needsEditingCount,
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
          final type = req["typeName"] ?? req["type"]?["name"] ?? AppLocalizations.of(context)!.translate('not_available');
          String priority = req["priority"] ?? AppLocalizations.of(context)!.translate('not_available');
          if (priority.toUpperCase() == 'HIGH') priority = AppLocalizations.of(context)!.translate('priority_high');
          else if (priority.toUpperCase() == 'MEDIUM') priority = AppLocalizations.of(context)!.translate('priority_medium');
          else if (priority.toUpperCase() == 'LOW') priority = AppLocalizations.of(context)!.translate('priority_low');

          final createdAt = req["createdAt"] ?? req["created_at"];
          final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

          final fulfilled = req["fulfilled"] == true;

          final documentsCount = req["documentsCount"] ?? (req["documents"] as List?)?.length ?? 0;

          final String status;
          final Color statusColor;
          final IconData statusIcon;

          final String lastForwardStatus = (req["status"] ?? "waiting").toString().toLowerCase();

          if (fulfilled) {
            status = AppLocalizations.of(context)!.translate('status_fulfilled');
            statusColor = MyRequestsColors.statusFulfilled;
            statusIcon = Icons.task_alt_rounded;
          } else {
            switch (lastForwardStatus) {
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
              case "needs_editing":
              case "needs-editing":
              case "needs change":
                status = AppLocalizations.of(context)!.translate('status_needs_editing');
                statusColor = MyRequestsColors.statusNeedsChange;
                statusIcon = Icons.edit_note_rounded;
                break;
              case "waiting":
              case "pending":
              default:
                status = AppLocalizations.of(context)!.translate('status_waiting');
                statusColor = MyRequestsColors.statusWaiting;
                statusIcon = Icons.hourglass_empty_rounded;
            }
          }

          final lastForwardSentTo = req["lastForwardSentTo"];

          return buildDesktopRequestCard(
            id: id,
            title: title,
            type: type,
            priority: priority,
            date: formattedDate,
            statusText: status,
            statusColor: statusColor,
            statusIcon: statusIcon,
            documentsCount: documentsCount,
            onDelete: _deleteRequest,
            context: context,
            lastForwardSentTo: lastForwardSentTo,
            onCancelForward: lastForwardSentTo != null
                ? () => _cancelForward(id, lastForwardSentTo['id'])
                : null,
            onForward: lastForwardSentTo == null
                ? () => _forwardTransaction(id)
                : null,
          );
        }).toList(),
      ],
    );
  }
}