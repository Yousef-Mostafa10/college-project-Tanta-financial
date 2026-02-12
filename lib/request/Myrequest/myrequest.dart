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

        final createdAt = req["createdAt"] ?? req["created_at"];
        final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

        final userForwardStatus = req["userForwardStatus"];
        final fulfilled = req["fulfilled"] == true;

        final documents = req["documents"] as List?;
        final documentsCount = documents?.length ?? 0;

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
          documentsCount: documentsCount,  // ✅ إضافة ده
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

          final createdAt = req["createdAt"] ?? req["created_at"];
          final formattedDate = MyRequestsHelpers.formatDate(context, createdAt);

          final userForwardStatus = req["userForwardStatus"];
          final fulfilled = req["fulfilled"] == true;

          final documents = req["documents"] as List?;
          final documentsCount = documents?.length ?? 0;

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
            documentsCount: documentsCount,
            onDelete: _deleteRequest,
            context: context,
          );
        }).toList(),
      ],
    );
  }
}