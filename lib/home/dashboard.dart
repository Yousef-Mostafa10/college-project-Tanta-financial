import 'package:college_project/l10n/app_localizations.dart';
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
                  title: Text(AppLocalizations.of(context)!.translate(option.toLowerCase().replaceAll(' ', '_')),
                      style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    onSelected(option); // تحديث القيمة
                    Navigator.pop(context); // إغلاق القائمة
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

