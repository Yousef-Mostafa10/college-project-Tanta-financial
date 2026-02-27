import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dart:async';

import '../app_config.dart';
import 'archive_colors.dart';
import 'archive_api.dart';
import 'archive_mobile_card.dart';
import 'archive_desktop_card.dart';

// نستخدم نفس widgets الإحصائيات والفلاتر من MyRequests
import '../request/Myrequest/my_requests_mobile_stats.dart';
import '../request/Myrequest/my_requests_stats_widget.dart';
import '../request/Myrequest/my_requests_mobile_filters.dart';
import '../request/Myrequest/my_requests_desktop_filters.dart';
import '../request/Myrequest/my_requests_empty_state.dart';
import '../request/Myrequest/my_requests_header.dart';
import '../request/Myrequest/my_requests_helpers.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final String baseUrl = AppConfig.baseUrl;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  String? _userToken;
  Timer? _searchDebounce;

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
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Needs Change'];

  late ArchiveApi _api;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // 🔹 تهيئة البيانات
  Future<void> _initializeData() async {
    await _getUserInfo();
    if (_userToken != null) {
      _api = ArchiveApi(
        baseUrl: baseUrl,
        userToken: _userToken,
      );
      await _fetchTypes();
      await _fetchArchiveRequests();
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
      final userInfo = await ArchiveApi.getUserInfo();
      setState(() {
        _userToken = userInfo['token'];
      });
    } catch (e) {
      print("❌ Error getting user info: $e");
      setState(() {
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

  // 🔹 جلب العمليات
  Future<void> _fetchArchiveRequests() async {
    if (_userToken == null) {
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
      final result = await _api.fetchArchiveRequests(
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

        setState(() {
          _requests = result['data'] ?? [];
          _currentPage = pagination?['currentPage'] ?? 1;
          _hasMore = pagination?['next'] != null;
          _totalCount = pagination?['total'] ?? _requests.length;

          // إحصائيات من الـ Summary
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
      print("❌ Error fetching archive requests: $e");
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
      final result = await _api.fetchArchiveRequests(
        page: nextPage,
        perPage: 10,
        priority: _selectedPriority != 'All' ? _selectedPriority : null,
        typeName: _selectedType != 'All Types' ? _selectedType : null,
        search: _searchController.text.trim(),
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );

      if (mounted && result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final newRequests = result['data'] as List<dynamic>? ?? [];

        setState(() {
          _requests.addAll(newRequests);
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

  // 🔹 تحديث القائمة (النتائج قادمة من السيرفر جاهزة)
  void _applyFilters() {
    setState(() {
      _filteredRequests = _requests;
    });
  }

  // 🔹 البحث مع Debounce
  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchArchiveRequests();
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
              color: ArchiveColors.cardBg,
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
                        color: ArchiveColors.primary,
                      ),
                    ),
                  ),
                ...options.map((option) {
                    String displayText = option;
                    if (option == 'All') displayText = AppLocalizations.of(context)!.translate('all_filter');
                    if (option == 'All Types') displayText = AppLocalizations.of(context)!.translate('all_types_filter');
                    if (option == 'Waiting') displayText = AppLocalizations.of(context)!.translate('waiting');
                    if (option == 'Approved') displayText = AppLocalizations.of(context)!.translate('approved');
                    if (option == 'Rejected') displayText = AppLocalizations.of(context)!.translate('rejected');
                    if (option == 'Needs Change') displayText = AppLocalizations.of(context)!.translate('needs_change');
                    if (option == 'Fulfilled') displayText = AppLocalizations.of(context)!.translate('fulfilled');
                    if (option == 'High') displayText = AppLocalizations.of(context)!.translate('priority_high');
                    if (option == 'Medium') displayText = AppLocalizations.of(context)!.translate('priority_medium');
                    if (option == 'Low') displayText = AppLocalizations.of(context)!.translate('priority_low');

                    return ListTile(
                      leading: Icon(
                        Icons.check_rounded,
                        color: option == currentValue ? ArchiveColors.primary : Colors.transparent,
                      ),
                      title: Text(displayText, style: TextStyle(color: ArchiveColors.textPrimary)),
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

  Widget _buildLoadingState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ArchiveColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_requests'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: ArchiveColors.textSecondary,
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
      backgroundColor: ArchiveColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('archive') ?? 'Archive',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ArchiveColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 20 : 24),
            onPressed: _fetchArchiveRequests,
            tooltip: AppLocalizations.of(context)!.translate('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(isMobile)
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
                      valueColor: AlwaysStoppedAnimation<Color>(ArchiveColors.primary),
                    ),
                  ),
              ],
            ),
    );
  }

  // ⭐ تصميم الجوال
  Widget _buildMobileBody() {
    return Column(
      children: [
        // 1️⃣ الإحصائيات
        buildMobileStatsSection(context, _totalCount, _approvedCount, _rejectedCount, _waitingCount, _needsEditingCount),

        // 2️⃣ البحث والفلترة
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
              _fetchArchiveRequests();
            },
          ),
          onTypeTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_type'),
            typeNames,
            _selectedType,
                (value) {
              setState(() => _selectedType = value);
              _fetchArchiveRequests();
            },
          ),
          onStatusTap: () => _showMobileFilterDialog(
            AppLocalizations.of(context)!.translate('select_status'),
            statuses,
            _selectedStatus,
                (value) {
              setState(() => _selectedStatus = value);
              _fetchArchiveRequests();
            },
          ),
        ),

        // 3️⃣ قائمة الطلبات
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
        _fetchArchiveRequests();
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
                valueColor: AlwaysStoppedAnimation<Color>(ArchiveColors.primary),
                strokeWidth: 2,
              ),
            ),
          );
        }

        return _buildRequestCard(_filteredRequests[index], isMobile: true);
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
                _fetchArchiveRequests();
              },
              onTypeChanged: (value) {
                setState(() => _selectedType = value!);
                _fetchArchiveRequests();
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value!);
                _fetchArchiveRequests();
              },
              onSearchChanged: _onSearchChanged,
            ),

            SizedBox(height: 20),
            buildDesktopHeader(context, _totalCount),
            SizedBox(height: 16),
            _buildDesktopRequestsList(),

            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ArchiveColors.primary),
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
          return _buildRequestCard(req, isMobile: false);
        }).toList(),
      ],
    );
  }

  // 🔹 بناء كارد العملية (مشترك بين الموبايل والديسكتوب)
  Widget _buildRequestCard(dynamic req, {required bool isMobile}) {
    final id = req["id"].toString();
    final title = req["title"] ?? AppLocalizations.of(context)!.translate('no_title');
    final type = req["typeName"] ?? req["type"]?["name"] ?? AppLocalizations.of(context)!.translate('n_a');
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
      statusColor = ArchiveColors.statusFulfilled;
      statusIcon = Icons.task_alt_rounded;
    } else {
      switch (lastForwardStatus.toLowerCase()) {
        case "approved":
          status = AppLocalizations.of(context)!.translate('status_approved');
          statusColor = ArchiveColors.statusApproved;
          statusIcon = Icons.check_circle_rounded;
          break;
        case "rejected":
          status = AppLocalizations.of(context)!.translate('status_rejected');
          statusColor = ArchiveColors.statusRejected;
          statusIcon = Icons.cancel_rounded;
          break;
        case "needs_editing":
        case "needs-editing":
        case "needs change":
          status = AppLocalizations.of(context)!.translate('status_needs_editing');
          statusColor = ArchiveColors.statusNeedsChange;
          statusIcon = Icons.edit_note_rounded;
          break;
        case "waiting":
        case "pending":
        default:
          status = AppLocalizations.of(context)!.translate('waiting');
          statusColor = ArchiveColors.statusWaiting;
          statusIcon = Icons.hourglass_empty_rounded;
      }
    }

    if (isMobile) {
      return buildArchiveMobileCard(
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
      );
    } else {
      return buildArchiveDesktopCard(
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
      );
    }
  }
}
