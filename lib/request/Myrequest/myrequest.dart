import 'package:flutter/material.dart';
import 'dart:async';
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

import '../editerequest.dart';
import '../creatrequest.dart';
import '../../drawer.dart';
import '../../Auth/login.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final String baseUrl = AppConfig.baseUrl;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _errorMessage;
  bool _showBackToTop = false;
  String? _userName;
  String? _userToken;
  String? _userRole;
  String? _userId;

  // إحصائيات من الـ API Summary
  int _totalCount = 0;
  int _waitingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _needsEditingCount = 0;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // الفلاتر
  String _selectedStatus = "All";
  String _selectedType = "All Types";
  String _selectedPriority = "All";

  // أنواع الطلبات
  List<String> typeNames = ['All Types'];
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Needs Change'];

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
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200) {
      if (!_showBackToTop) setState(() => _showBackToTop = true);
    } else {
      if (_showBackToTop) setState(() => _showBackToTop = false);
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
        _userRole = userInfo['role'];
        _userId = userInfo['userId'];
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
      final result = await _api.fetchMyRequests(
        page: 1,
        perPage: 10,
        priority: _selectedPriority != 'All' ? _selectedPriority : null,
        typeName: _selectedType != 'All Types' ? _selectedType : null,
        search: _searchController.text.trim(),
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );

      if (result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final summary = result['summary'] as Map<String, dynamic>?;
        final rawData = result['data'] as List<dynamic>? ?? [];

        final updatedRequests = rawData.map((req) {
          final request = Map<String, dynamic>.from(req);
          
          String status = (request["lastForwardStatus"] ?? "waiting").toString().toLowerCase();
          if (request["fulfilled"] == true) {
            status = "fulfilled";
          }
          request["status"] = status;

          return request;
        }).toList();

        setState(() {
          _requests = updatedRequests;
          _currentPage = pagination?['currentPage'] ?? 1;
          _hasMore = pagination?['next'] != null;
          _totalCount = pagination?['total'] ?? _requests.length;

          if (summary != null) {
            _waitingCount = summary['WAITING'] ?? 0;
            _approvedCount = summary['APPROVED'] ?? 0;
            _rejectedCount = summary['REJECTED'] ?? 0;
            _needsEditingCount = summary['NEEDS_EDITING'] ?? 0;
            _totalCount = _waitingCount + _approvedCount + _rejectedCount + _needsEditingCount;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.translate('failed_load_requests');
        });
      }
    }
  }

  // 🔹 تحميل المزيد عند الـ scroll
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _api.fetchMyRequests(
        page: nextPage,
        perPage: 10,
        priority: _selectedPriority != 'All' ? _selectedPriority : null,
        typeName: _selectedType != 'All Types' ? _selectedType : null,
        search: _searchController.text.trim(),
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );

      if (mounted && result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final newRawRequests = result['data'] as List<dynamic>? ?? [];

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

  // 🆕 تحديث كارت واحد فقط
  void _updateRequestInList(String requestId, Map<String, dynamic> updates) {
    if (!mounted) return;
    setState(() {
      int index = _requests.indexWhere((r) => r['id'].toString() == requestId);
      if (index != -1) {
        _requests[index] = {..._requests[index], ...updates};
        _applyFilters();
      }
    });
  }


  // 🔹 تطبيق الفلاتر
  void _applyFilters() {
    setState(() {
      _filteredRequests = _requests;
    });
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMyRequests();
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


  Future<void> _forwardTransaction(String transactionId, Map<String, dynamic> request) async {
    if (!mounted) return;

    String? selectedUser;
    String forwardComment = '';
    TextEditingController searchController = TextEditingController();
    ScrollController dialogScrollController = ScrollController();
    
    List<dynamic> allLoadedUsers = [];
    int currentUserPage = 1;
    bool hasMoreUsers = true;
    bool isDialogLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> loadMoreUsers() async {
              if (isDialogLoading || !hasMoreUsers) return;
              
              setStateDialog(() => isDialogLoading = true);
              try {
                final result = await _api.fetchUsers(page: currentUserPage, perPage: 10);
                setStateDialog(() {
                  allLoadedUsers.addAll(result['users'] ?? []);
                  hasMoreUsers = result['hasMore'] ?? false;
                  currentUserPage++;
                  isDialogLoading = false;
                });
              } catch (e) {
                setStateDialog(() => isDialogLoading = false);
              }
            }

            // Initial load
            if (allLoadedUsers.isEmpty && hasMoreUsers && !isDialogLoading) {
              loadMoreUsers();
            }

            dialogScrollController.addListener(() {
              if (dialogScrollController.position.pixels >= dialogScrollController.position.maxScrollExtent - 50) {
                loadMoreUsers();
              }
            });

            final query = searchController.text.toLowerCase();
            final filteredUsers = allLoadedUsers.where((user) {
              final name = (user['name'] ?? "").toString().toLowerCase();
              final id = user['id']?.toString();
              final isCurrentUser = (id != null && _userId != null && id == _userId) || (name == _userName?.toLowerCase());
              return name.contains(query) && !isCurrentUser;
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_search_rounded, color: MyRequestsColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.translate('select_user_hint') ?? 'Select User',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyRequestsColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.translate('search_users') ?? 'Search users...',
                        prefixIcon: Icon(Icons.search_rounded, color: MyRequestsColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredUsers.isEmpty && isDialogLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: dialogScrollController,
                              shrinkWrap: true,
                              itemCount: filteredUsers.length + (hasMoreUsers ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredUsers.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }
                                final user = filteredUsers[index];
                                final userName = user["name"]?.toString() ?? "Unknown";
                                final isSelected = userName == selectedUser;
                                return ListTile(
                                  leading: Icon(Icons.person_rounded, color: isSelected ? MyRequestsColors.primary : MyRequestsColors.textSecondary),
                                  title: Text(userName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? MyRequestsColors.primary : MyRequestsColors.textPrimary)),
                                  trailing: isSelected ? Icon(Icons.check_rounded, color: MyRequestsColors.primary) : null,
                                  onTap: () => setStateDialog(() => selectedUser = userName),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.translate('enter_comments') ?? 'Enter comments...',
                        prefixIcon: Icon(Icons.comment_rounded, color: MyRequestsColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) => forwardComment = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.translate('cancel_button') ?? 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedUser == null ? null : () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: MyRequestsColors.primary),
                            child: Text(AppLocalizations.of(context)!.translate('forward') ?? 'Forward', style: const TextStyle(color: Colors.white)),
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
    ).then((confirmed) async {
      if (confirmed == true && selectedUser != null) {
        final success = await _api.forwardTransaction(transactionId, selectedUser!, comment: forwardComment);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.translate('transaction_forwarded_success') ?? 'Forwarded successfully'), backgroundColor: Colors.green),
            );
            _fetchMyRequests();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.translate('failed_to_forward') ?? 'Failed to forward'), backgroundColor: Colors.red),
            );
          }
        }
      }
      dialogScrollController.dispose();
    });
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
      drawer: (_userRole?.toLowerCase() != 'admin') ? CustomDrawer(onLogout: _logout) : null,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            // زر إضافة طلب - أصبح الآن في جهة اليمين مع مسافة بسيطة عن الحافة
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: FloatingActionButton(
                  heroTag: 'add_request_btn',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateRequestPage()),
                    );
                  },
                  backgroundColor: MyRequestsColors.primary,
                  tooltip: AppLocalizations.of(context)!.translate('create_request') ?? 'Create Request',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
            // زر الصعود للأعلى - أصبح الآن في المنتصف ويظهر عند السكرول
            if (_showBackToTop)
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingActionButton(
                  heroTag: 'scroll_to_top_btn',
                  mini: true,
                  onPressed: _scrollToTop,
                  backgroundColor: MyRequestsColors.primary.withOpacity(0.8),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ⭐ تصميم الجوال
  Widget _buildMobileBody() {
    return Column(
      children: [
        // 1️⃣ الجزء الثابت عند الأعلى - الإحصائيات من الـ Summary
        buildMobileStatsSection(context, _totalCount, _approvedCount, _rejectedCount, _waitingCount, _needsEditingCount),
        buildMobileFilterSection(
          context: context,
          searchController: _searchController,
          selectedPriority: _selectedPriority,
          selectedType: _selectedType,
          selectedStatus: _selectedStatus,
          priorities: priorities,
          typeNames: typeNames,
          statuses: statuses,
          onSearchChanged: _onSearchChanged,
          onPriorityTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_priority'),
            priorities,
            _selectedPriority,
                (value) {
              setState(() => _selectedPriority = value);
              _fetchMyRequests();
            },
          ),
          onTypeTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_type'),
            typeNames,
            _selectedType,
                (value) {
              setState(() => _selectedType = value);
              _fetchMyRequests();
            },
          ),
          onStatusTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_status'),
            statuses,
            _selectedStatus,
                (value) {
              setState(() => _selectedStatus = value);
              _fetchMyRequests();
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
        _fetchMyRequests();
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
        final title = req["title"] ?? AppLocalizations.of(context)!.translate('no_title');
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
          onDelete: _deleteRequest,
          api: _api,
          onForward: () => _forwardTransaction(id, req),
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
                _fetchMyRequests();
              },
              onTypeChanged: (value) {
                setState(() => _selectedType = value!);
                _fetchMyRequests();
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value!);
                _fetchMyRequests();
              },
              onSearchChanged: _onSearchChanged,
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
    return buildDesktopStatsRow(
        context,
        _totalCount,
        _approvedCount,
        _rejectedCount,
        _waitingCount,
        _needsEditingCount
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
        _fetchMyRequests();
      });
    }

    return Column(
      children: [
        ..._filteredRequests.map((req) {
          final id = req["id"].toString();
          final title = req["title"] ?? AppLocalizations.of(context)!.translate('no_title');
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
            api: _api,
            onForward: () => _forwardTransaction(id, req),
          );
        }).toList(),
      ],
    );
  }
}