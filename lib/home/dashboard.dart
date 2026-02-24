import 'package:college_project/l10n/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/login.dart';
import '../Notefecation/inbox.dart';
import '../drawer.dart' hide AppColors; // إخفاء AppColors من drawer
import '../request/Ditalis_Request/ditalis_request.dart' hide AppColors; // إخفاء AppColors من ditalis_request
import '../request/RequestTracking/request_tracking.dart' hide AppColors; // إخفاء AppColors من request_tracking
import '../request/editerequest.dart' hide AppColors; // إخفاء AppColors من editerequest
import 'dashboard_api.dart';
import 'dashboard_colors.dart'; // ✅ استخدام AppColors من هنا
import 'dashboard_helpers.dart';
import 'stats_widget.dart';
import 'filters_widget.dart';
import 'header_widget.dart';
import 'empty_state.dart';
import 'desktop_request_card.dart';
import 'mobile_request_card.dart';
import 'pagination_widget.dart';

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
  List<dynamic> paginatedRequests = [];
  bool isLoading = false;
  bool isRefreshing = false; // loading خفيف للفلاتر وتغيير الصفحات

  // ✅ Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;

  // إحصائيات
  int total = 0;
  int approved = 0;
  int rejected = 0;
  int waiting = 0;
  int needsChange = 0;
  int fulfilled = 0;

  // فلاتر
  String selectedPriority = 'All';
  String selectedType = 'All Types';
  String selectedStatus = 'All';
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> typeNames = ['All Types'];
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Fulfilled', 'Needs Change'];

  @override
  void initState() {
    super.initState();
    fetchTypes();
    fetchRequests(fullLoad: true);
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

  // ✅ تعديل طلب
  void _editRequest(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRequestPage(requestId: requestId),
      ),
    ).then((edited) {
      if (edited == true) {
        fetchRequests();
      }
    });
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
        fetchRequests(page: currentPage);

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

  Future<void> fetchRequests({int page = 1, bool fullLoad = false}) async {
    if (fullLoad || requests.isEmpty) {
      setState(() => isLoading = true);
    } else {
      setState(() => isRefreshing = true);
    }
    try {
      final result = await _api.fetchAllRequests(
        page: page,
        perPage: itemsPerPage,
        priority: selectedPriority != 'All' ? selectedPriority : null,
        typeName: selectedType != 'All Types' ? selectedType : null,
      );

      final List<dynamic> fetchedTransactions = result['data'] ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final summary = result['summary'] as Map<String, dynamic>?;

      // تحديث الإحصائيات من الـ summary
      _updateStatsFromSummary(summary);

      setState(() {
        requests = fetchedTransactions;
        currentPage = pagination?['currentPage'] ?? page;
        totalPages = pagination?['lastPage'] ?? 1;
        if (totalPages == 0) totalPages = 1;
        total = pagination?['total'] ?? fetchedTransactions.length;
      });

      // تطبيق الفلاتر المحلية (البحث والاستيتس)
      _applyLocalFilters();

      debugPrint("✅ Loaded page $currentPage/$totalPages - ${fetchedTransactions.length} items");
    } catch (e) {
      debugPrint("❌ Exception while fetching data: $e");
      if (e.toString().contains('Unauthorized')) {
        _handleTokenExpired();
      }
    }
    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  // فلاتر محلية (بحث + ستاتس) على البيانات الحالية
  void _applyLocalFilters() {
    List<dynamic> filtered = requests;

    if (selectedStatus != "All") {
      filtered = filtered.where((request) {
        final lastForwardStatus = request["lastForwardStatus"];

        switch (selectedStatus) {
          case "Approved":
            return lastForwardStatus == "approved";
          case "Rejected":
            return lastForwardStatus == "rejected";
          case "Waiting":
            return lastForwardStatus == "waiting" || lastForwardStatus == "pending";
          case "Fulfilled":
            return lastForwardStatus == "fulfilled";
          case "Needs Change":
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
        final creator = (request["creator"]?["name"] ?? request["creatorName"] ?? "").toLowerCase();
        return title.contains(searchTerm) || creator.contains(searchTerm);
      }).toList();
    }

    setState(() {
      filteredRequests = filtered;
      paginatedRequests = filtered; // الداتا جاية من السيرفر مـ paginated أصلاً
    });
  }

  void _applyFilters(List<dynamic> allRequests) {
    // لما الفلاتر تتغير، نجيب الداتا من السيرفر تاني
    fetchRequests(page: 1);
  }

  void _updatePaginatedRequests() {
    // الداتا جاية من السيرفر مـ paginated أصلاً
    setState(() {
      paginatedRequests = filteredRequests;
    });
  }

  void _goToPage(int page) {
    fetchRequests(page: page);
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

  void _updateStatsFromSummary(Map<String, dynamic>? summary) {
    if (summary != null) {
      waiting = summary['WAITING'] ?? 0;
      needsChange = summary['NEEDS_EDITING'] ?? 0;
      rejected = summary['REJECTED'] ?? 0;
      approved = summary['APPROVED'] ?? 0;
      fulfilled = summary['FULFILLED'] ?? 0;
      total = waiting + needsChange + rejected + approved + fulfilled;
    }
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
            tooltip: AppLocalizations.of(context)!.translate('refresh'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: AppColors.sidebarText),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InboxPage())),
            tooltip: AppLocalizations.of(context)!.translate('notifications'),
          ),
        ],
      ),
      drawer: CustomDrawer(onLogout: logout),
      body: isLoading
          ? _buildLoadingState()
          : Stack(
              children: [
                isMobile
                    ? _buildMobileOptimizedBody()
                    : _buildDesktopBodyWithScroll(),
                if (isRefreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
              ],
            ),
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
              needsChange: needsChange,
              fulfilled: fulfilled,
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
            if (filteredRequests.isNotEmpty) ...[
              const SizedBox(height: 24),
              PaginationWidget(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: _goToPage,
                isMobile: false,
              ),
            ],
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
          child: Column(
            children: [
              Expanded(
                child: _buildMobileRequestsList(),
              ),
              if (filteredRequests.isNotEmpty)
                PaginationWidget(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPageChanged: _goToPage,
                  isMobile: true,
                ),
            ],
          ),
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
          hintText: AppLocalizations.of(context)!.translate('search_transactions'),
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
        onChanged: (value) => _applyLocalFilters(),
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
      onSearchChanged: (value) => _applyLocalFilters(),
      onPriorityChanged: (value) {
        setState(() => selectedPriority = value!);
        fetchRequests(page: 1);
      },
      onTypeChanged: (value) {
        setState(() => selectedType = value!);
        fetchRequests(page: 1);
      },
      onStatusChanged: (value) {
        setState(() => selectedStatus = value!);
        _applyLocalFilters();
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return HeaderWidget(
      itemCount: total,
      isMobile: isMobile,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
    );
  }

  Widget _buildRequestsListForDesktop() {
    if (filteredRequests.isEmpty) {
      return const EmptyState();
    }

    return Column(
      children: [
        ...paginatedRequests.map((req) {
          final id = req["id"].toString();
          final title = req["title"] ?? "No Title";
          final type = req["type"]?["name"] ?? req["typeName"] ?? "N/A";
          final priority = req["priority"] ?? "N/A";
          final creator = req["creator"]?["name"] ?? req["creatorName"] ?? "Unknown";
          final lastForwardStatus = req["lastForwardStatus"];
          final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);
          final documentsCount = req["documentsCount"] ?? 0;
          final createdDate = req["createdDate"] ?? req["createdAt"];

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
              documentsCount: documentsCount,
              createdAt: createdDate,
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
              onEditRequest: () => _editRequest(id),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: statItems.map((stat) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildMobileStatItem(
                  label: stat["label"] as String,
                  value: stat["value"] as int,
                  color: stat["color"] as Color,
                  icon: stat["icon"] as IconData,
                ),
              )
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileStatItem({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
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
            onChanged: (value) => _applyLocalFilters(),
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
                      fetchRequests(page: 1);
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
                      fetchRequests(page: 1);
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
                      _applyLocalFilters();
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
    Color getTextColor() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        switch (value.toLowerCase()) {
          case 'waiting':
            return AppColors.statusWaiting;
          case 'approved':
            return AppColors.statusApproved;
          case 'rejected':
            return AppColors.statusRejected;
          case 'needs change':
            return AppColors.statusNeedsChange;
          case 'fulfilled':
            return AppColors.statusFulfilled;
          default:
            return AppColors.textPrimary;
        }
      }
      return AppColors.textPrimary;
    }

    IconData getStatusIcon() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        switch (value.toLowerCase()) {
          case "approved":
            return Icons.check_circle_rounded;
          case "rejected":
            return Icons.cancel_rounded;
          case "waiting":
            return Icons.hourglass_empty_rounded;
          case "needs change":
            return Icons.edit_note_rounded;
          case "fulfilled":
            return Icons.task_alt_rounded;
          case "all":
            return Icons.filter_list_rounded;
          default:
            return icon;
        }
      }
      return icon;
    }

    Color getIconColor() {
      if (label == AppLocalizations.of(context)!.translate('status')) {
        return getTextColor();
      }
      return AppColors.primary;
    }

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
            Icon(
              getStatusIcon(),
              size: 14,
              color: getIconColor(),
            ),
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
                  color: getTextColor(),
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
                  title: Text(
                      AppLocalizations.of(context)!.translate(option.toLowerCase().replaceAll(' ', '_')),
                      style: TextStyle(color: AppColors.textPrimary)
                  ),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
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
      itemCount: paginatedRequests.length,
      itemBuilder: (context, index) {
        final req = paginatedRequests[index];
        final id = req["id"].toString();
        final title = req["title"] ?? "No Title";
        final type = req["type"]?["name"] ?? req["typeName"] ?? "N/A";
        final priority = req["priority"] ?? "N/A";
        final creator = req["creator"]?["name"] ?? req["creatorName"] ?? "Unknown";
        final lastForwardStatus = req["lastForwardStatus"];
        final statusInfo = DashboardHelpers.getStatusInfo(lastForwardStatus);
        final documentsCount = req["documentsCount"] ?? 0;
        final createdDate = req["createdDate"] ?? req["createdAt"];

        return MobileRequestCard(
          id: id,
          title: title,
          type: type,
          priority: priority,
          creator: creator,
          statusText: statusInfo['text'],
          statusColor: statusInfo['color'],
          statusIcon: statusInfo['icon'],
          documentsCount: documentsCount,
          createdAt: createdDate,
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
          onEditRequest: () => _editRequest(id),
          onDeleteRequest: () => _deleteRequest(id),
        );
      },
    );
  }
}