import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:college_project/providers/theme_provider.dart';
import 'package:college_project/core/app_theme_color.dart';

import '../Auth/login.dart';
import '../notifications/notifications_page.dart';
import '../notifications/notifications_provider.dart';
import '../drawer.dart';
import '../request/Ditalis_Request/ditalis_request.dart' hide AppColors;
import '../request/RequestTracking/request_tracking.dart' hide AppColors;
import '../request/editerequest.dart';
import 'dashboard_api.dart';
import 'dashboard_colors.dart';
import 'stats_widget.dart';
import 'filters_widget.dart';
import 'header_widget.dart';
import 'empty_state.dart';
import 'desktop_request_card.dart';
import 'mobile_request_card.dart';
import '../shared/paginated_type_picker.dart';
import '../utils/app_error_handler.dart';
import '../l10n/app_localizations.dart';
import 'dashboard_helpers.dart';
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode(); // ✅ للتحكم في بقاء التركيز على البحث

  List<dynamic> requests = [];
  List<dynamic> filteredRequests = [];
  List<dynamic> paginatedRequests = [];
  bool isLoading = false;
  bool isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isFetchingMoreGuard = false; // حارس فوري لمنع التكرار
  bool _hasMorePages = true;
  int _lastRequestedPage = 0; // لمنع طلب نفس الصفحة مرتين
  Timer? _searchDebounce;

  // ✅ Pagination (للـ API)
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;

  // إحصائيات
  int total = 0;
  int approved = 0;
  int rejected = 0;
  int waiting = 0;
  int needsChange = 0;

  // فلاتر
  String selectedPriority = 'All';
  String selectedType = 'All Types';
  String selectedStatus = 'All';
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> typeNames = ['All Types'];
  List<String> statuses = ['All', 'Waiting', 'Approved', 'Rejected', 'Fulfilled', 'Needs Change'];
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    fetchTypes();
    fetchRequests(fullLoad: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // فقط للـ back-to-top button - لا تستدعي _loadMore هنا لأن NotificationListener يتولى ذلك
    if (_scrollController.position.pixels >= 200) {
      if (!_showBackToTop) setState(() => _showBackToTop = true);
    } else {
      if (_showBackToTop) setState(() => _showBackToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose(); // ✅ تنظيف الـ FocusNode
    super.dispose();
  }

  Future<void> fetchTypes() async {
    try {
      final result = await _api.fetchTypesPage(page: 1, perPage: 100);
      setState(() {
        typeNames = ['All Types', ...result['types']];
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
        if (mounted) {
          setState(() {
            paginatedRequests.removeWhere((r) => r['id'].toString() == requestId);
            requests.removeWhere((r) => r['id'].toString() == requestId);
            filteredRequests.removeWhere((r) => r['id'].toString() == requestId);
            // تحديث العدد الإجمالي تقريبياً
            if (total > 0) total--;
          });
          
          fetchRequests(page: currentPage, fullLoad: false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('request_deleted_success')),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
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
          content: Text(AppErrorHandler.translateException(context, e)),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> fetchRequests({int page = 1, bool fullLoad = false}) async {
    if (fullLoad) {
      setState(() => isLoading = true);
    } else {
      setState(() => isRefreshing = true);
    }
    // عند جلب من الصفحة الأولى (فلتر/بحث/refresh)، أعد ضبط الحارس
    if (page == 1) {
      _isFetchingMoreGuard = false;
      _lastRequestedPage = 0;
    }
    try {
      final result = await _api.fetchAllRequests(
        page: page,
        perPage: itemsPerPage,
        priority: selectedPriority != 'All' ? selectedPriority : null,
        typeName: selectedType != 'All Types' ? selectedType : null,
        status: selectedStatus != 'All' ? selectedStatus : null,
        search: _searchController.text.trim(),
      );

      final List<dynamic> fetchedTransactions = result['data'] ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final summary = result['summary'] as Map<String, dynamic>?;

      _updateStatsFromSummary(summary);

      setState(() {
        // لو page = 1 (refresh أو فلتر جديد) → امسح القديم
        if (page == 1) {
          requests = List.from(fetchedTransactions);
          filteredRequests = List.from(fetchedTransactions);
          paginatedRequests = List.from(fetchedTransactions);
        }
        currentPage = pagination?['currentPage'] ?? page;
        totalPages = pagination?['lastPage'] ?? 1;
        if (totalPages == 0) totalPages = 1;
        total = pagination?['total'] ?? fetchedTransactions.length;
        _hasMorePages = pagination?['next'] != null;
      });

      debugPrint("✅ Loaded page $currentPage/$totalPages - ${fetchedTransactions.length} items");
    } catch (e) {
      debugPrint("❌ Exception while fetching data: $e");
      if (mounted) {
        final errorMsg = AppErrorHandler.translateException(context, e);
        
        // Handle token expiration specifically if needed
        if (e.toString().contains('Unauthorized')) {
          _handleTokenExpired();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    }
    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  // ✅ Infinite scroll: تحميل الصفحة الي بعدها
  Future<void> _loadMore() async {
    if (_isFetchingMoreGuard || _isLoadingMore || !_hasMorePages) return;

    final nextPage = currentPage + 1;
    if (nextPage <= _lastRequestedPage) return;
    _lastRequestedPage = nextPage;
    _isFetchingMoreGuard = true;

    setState(() => _isLoadingMore = true);
    try {
      final result = await _api.fetchAllRequests(
        page: nextPage,
        perPage: itemsPerPage,
        priority: selectedPriority != 'All' ? selectedPriority : null,
        typeName: selectedType != 'All Types' ? selectedType : null,
        status: selectedStatus != 'All' ? selectedStatus : null,
        search: _searchController.text.trim(),
      );

      final List<dynamic> fetchedTransactions = result['data'] ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          // منع التكرار: تخطي أي عنصر موجود IDه سبقاً، وأي مكرر في نفس الدفعة
          final existingIds = paginatedRequests.map((r) => r['id'].toString()).toSet();
          final List<dynamic> newItems = [];
          for (var r in fetchedTransactions) {
            final id = r['id']?.toString() ?? "";
            if (id.isNotEmpty && !existingIds.contains(id)) {
              newItems.add(r);
              existingIds.add(id);
            }
          }

          requests.addAll(newItems);
          filteredRequests = List.from(requests);
          paginatedRequests = List.from(requests);
          currentPage = pagination?['currentPage'] ?? nextPage;
          totalPages = pagination?['lastPage'] ?? totalPages;
          _hasMorePages = pagination?['next'] != null;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more: $e');
      _lastRequestedPage = currentPage;
      if (mounted) {
        setState(() {
          _hasMorePages = false;
        });
      }
      if (e.toString().contains('Unauthorized')) {
        _handleTokenExpired();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppErrorHandler.translateException(context, e)),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } finally {
      _isFetchingMoreGuard = false;
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }


  // البحث مع Debounce
  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      // ✅ نستخدم fullLoad: false هنا حتى لا تختفى الواجهة أثناء البحث ويفقد التركيز
      fetchRequests(page: 1, fullLoad: false);
    });
  }

  void _clearAllFilters() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    setState(() {
      selectedPriority = 'All';
      selectedType = 'All Types';
      selectedStatus = 'All';
      _searchController.clear();
      isLoading = true;
    });
    fetchRequests(page: 1, fullLoad: true);
  }


  void _handleTokenExpired() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
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
  }

  void _updateStatsFromSummary(Map<String, dynamic>? summary) {
    if (summary != null) {
      waiting = summary['WAITING'] ?? 0;
      needsChange = summary['NEEDS_EDITING'] ?? 0;
      rejected = summary['REJECTED'] ?? 0;
      approved = summary['APPROVED'] ?? 0;
      total = waiting + needsChange + rejected + approved;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Close SSE connection and clear notifications before logging out
    if (context.mounted) {
      context.read<NotificationProvider>().logout();
    }
    
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('loading_transactions'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark
                  // ── Dark Mode (أزرق + بنفسجي خفيف) ──
                  ? [
                      AppColors.bodyBg,
                      AppColors.primary.withOpacity(0.12),
                      AppColors.bodyBg,
                      AppColors.primary.withOpacity(0.08),
                    ]
                  : AppColors.themeColor == AppThemeColor.purple
                      // ── Light Purple Theme (لافندر إلى موف) ──
                      ? [
                          const Color(0xFFD8C8FF), // لافندر فاتح - أعلى يسار
                          const Color(0xFFF8F4FF), // أبيض ببنفسجي خفيف
                          const Color(0xFFF3EEFF), // أبيض بموف خفيف
                          const Color(0xFFC4AEF0), // بنفسجي هادئ - أسفل يمين
                        ]
                      // ── Light Blue Theme (أزرق سماوي) ──
                      : [
                          const Color(0xFFC8E0FF), // أزرق سماوي - أعلى يسار
                          const Color(0xFFF4F8FF), // أبيض مزرق خفيف
                          const Color(0xFFEDF5FF), // أبيض بأزرق خفيف
                          const Color(0xFFBDD5F8), // أزرق هادئ - أسفل يمين
                        ],
              stops: const [0.0, 0.38, 0.62, 1.0],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.isDark
                                ? Colors.white.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            title: Text(
              AppLocalizations.of(context)!.translate('administrative_dashboard'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: min(width * 0.04, 20),
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: fetchRequests,
                tooltip: AppLocalizations.of(context)!.translate('refresh'),
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage(isAdmin: true)),
                        ),
                        tooltip: AppLocalizations.of(context)!.translate('notifications'),
                      ),
                      if (provider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _showBackToTop
              ? FloatingActionButton(
                  heroTag: 'dashboard_scroll_top',
                  mini: true,
                  onPressed: _scrollToTop,
                  backgroundColor: AppColors.primary.withOpacity(0.8),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                )
              : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopBodyWithScroll() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore && _hasMorePages) {
          _loadMore();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
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
              // ✅ Loading indicator للـ infinite scroll
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
            ],
          ),
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
        color: AppColors.cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.translate('search_transactions'),
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.search_rounded, color: AppColors.primary),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isMobile ? 14 : 16,
          ),
        ),
        onChanged: _onSearchChanged,
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
      onSearchChanged: _onSearchChanged,
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
        fetchRequests(page: 1);
      },
      fetchTypePage: (page) => _api.fetchTypesPage(page: page),
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
      return EmptyState(onResetFilters: _clearAllFilters);
    }

    return Column(
      children: [
        ...paginatedRequests.map((req) {
          final id = req["id"].toString();
          final title = req["title"] ?? AppLocalizations.of(context)!.translate('no_title');
          final type = req["type"]?["name"] ?? req["typeName"] ?? AppLocalizations.of(context)!.translate('n_a');
          final priority = req["priority"] ?? AppLocalizations.of(context)!.translate('n_a');
          final creator = req["creator"]?["name"] ?? req["creatorName"] ?? AppLocalizations.of(context)!.translate('unknown');
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
        "color": AppColors.primary,
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
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.statBgLight,
                  AppColors.statBgLight.withOpacity(AppColors.isDark ? 0.45 : 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.borderColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statItems.map((stat) =>
                  Expanded(
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, val, _) => Text(
            val.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: AppColors.isDark
                  ? [
                      Shadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)?.translate(label.toLowerCase().replaceAll(' ', '_')) ?? label,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white.withOpacity(0.2)
              : AppColors.borderColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Pill-shaped search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.bodyBg,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('search_transactions'),
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 10),
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
                child: PaginatedTypePicker(
                  selectedType: selectedType,
                  onTypeChanged: (value) {
                    setState(() => selectedType = value!);
                    fetchRequests(page: 1);
                  },
                  fetchPage: (page) => _api.fetchTypesPage(page: page),
                  isMobile: true,
                  primaryColor: AppColors.primary,
                  borderColor: AppColors.primary.withOpacity(0.2),
                  textColor: AppColors.textPrimary,
                  cardBg: AppColors.cardBg,
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
                      fetchRequests(page: 1);
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
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');
      
      if (isStatus) {
        switch (value.toLowerCase()) {
          case 'waiting': return AppColors.statusWaiting;
          case 'approved': return AppColors.statusApproved;
          case 'rejected': return AppColors.statusRejected;
          case 'needs change': return AppColors.statusNeedsChange;
          case 'fulfilled': return AppColors.statusFulfilled;
          default: return AppColors.primary;
        }
      } else if (isPriority) {
        switch (value.toLowerCase()) {
          case 'high': return AppColors.statusError;
          case 'medium': return AppColors.statusPending;
          case 'low': return AppColors.statusApproved;
          default: return AppColors.primary;
        }
      }
      return AppColors.textPrimary;
    }

    IconData getStatusIcon() {
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');

      if (isStatus) {
        switch (value.toLowerCase()) {
          case "approved": return Icons.check_circle_rounded;
          case "rejected": return Icons.cancel_rounded;
          case "waiting": return Icons.hourglass_empty_rounded;
          case "needs change": return Icons.edit_note_rounded;
          case "fulfilled": return Icons.task_alt_rounded;
          case "all": return Icons.filter_list_rounded;
          default: return icon;
        }
      } else if (isPriority) {
        switch (value.toLowerCase()) {
          case "high": return Icons.priority_high_rounded;
          case "medium": return Icons.low_priority_rounded;
          case "low": return Icons.flag_rounded;
          case "all": return Icons.filter_list_rounded;
          default: return icon;
        }
      }
      return icon;
    }

    Color getIconColor() {
      final isStatus = label == AppLocalizations.of(context)!.translate('status');
      final isPriority = label == AppLocalizations.of(context)!.translate('priority');
      if (isStatus || isPriority) {
        return getTextColor();
      }
      return AppColors.primary;
    }

    String displayValue = value;
    if (value != 'All' && value != 'All Types') {
      displayValue = AppLocalizations.of(context)?.translate(value.toLowerCase().replaceAll(' ', '_')) ?? value;
    }

    final bool isActive = value != 'All' && value != 'All Types';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? getIconColor().withOpacity(0.15)
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? getIconColor().withOpacity(0.5)
                : AppColors.primary.withOpacity(0.15),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive 
              ? [
                  BoxShadow(
                    color: getIconColor().withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getStatusIcon(),
              size: isActive ? 16 : 14,
              color: getIconColor(),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? getIconColor() : AppColors.primary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isActive)
              Text(
                displayValue.length > 8 ? displayValue.substring(0, 8) + '...' : displayValue,
                style: TextStyle(
                  fontSize: 8,
                  color: getTextColor(),
                  fontWeight: FontWeight.w700,
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
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? AppColors.cardBg.withOpacity(0.85)
                    : AppColors.cardBg.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: AppColors.isDark
                        ? Colors.white.withOpacity(0.15)
                        : AppColors.borderColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: AppColors.dividerColor.withOpacity(0.5), thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: options.map((option) {
                        bool isSelected = option == currentValue;
                        Color itemColor = AppColors.textPrimary;
                        IconData itemIcon = Icons.circle_outlined;

                        if (title == AppLocalizations.of(context)!.translate('select_status')) {
                          itemColor = _getStatusColor(option);
                          itemIcon = _getStatusFilterIcon(option);
                        } else if (title == AppLocalizations.of(context)!.translate('select_priority')) {
                          itemColor = _getPriorityColor(option);
                          itemIcon = _getPriorityIcon(option);
                        }

                        if (option == 'All' || option == 'All Types') {
                          itemColor = AppColors.primary;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              onSelected(option);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? itemColor.withOpacity(0.1) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? itemColor.withOpacity(0.3) 
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(itemIcon, color: itemColor, size: 22),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)?.translate(option.toLowerCase().replaceAll(' ', '_')) ?? option,
                                      style: TextStyle(
                                        color: isSelected ? itemColor : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: itemColor, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRequestsList() {
    if (filteredRequests.isEmpty) {
      return EmptyState(onResetFilters: _clearAllFilters);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore && _hasMorePages) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // +1 عشان نضيف loading indicator في الأسفل
        itemCount: paginatedRequests.length + (_hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          // آخر عنصر = loading indicator
          if (index == paginatedRequests.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _isLoadingMore
                    ? CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final req = paginatedRequests[index];
          final id = req["id"].toString();
          final title = req["title"] ?? AppLocalizations.of(context)!.translate('no_title');
          final type = req["type"]?["name"] ?? req["typeName"] ?? AppLocalizations.of(context)!.translate('n_a');
          final priority = req["priority"] ?? AppLocalizations.of(context)!.translate('n_a');
          final creator = req["creator"]?["name"] ?? req["creatorName"] ?? AppLocalizations.of(context)!.translate('unknown');
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
                  builder: (context) => TransactionTrackingPage(transactionId: id),
                ),
              );
            },
            onEditRequest: () => _editRequest(id),
            onDeleteRequest: () => _deleteRequest(id),
          );
        },
      ),
    );
  }

  // دالة إرجاع لون الحالة
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return AppColors.primary; // أزرق
      case 'waiting':
        return AppColors.statusWaiting; // أصفر
      case 'approved':
        return AppColors.statusApproved; // أخضر
      case 'rejected':
        return AppColors.statusRejected; // أحمر
      case 'fulfilled':
        return AppColors.statusFulfilled; // بنفسجي
      case 'needs change':
        return AppColors.statusNeedsChange; // برتقالي
      default:
        return AppColors.textPrimary; // رمادي
    }
  }

  // دالة إرجاع أيقونة الحالة
  IconData _getStatusFilterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.filter_list_rounded;
      case 'waiting':
        return Icons.hourglass_empty_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'fulfilled':
        return Icons.task_alt_rounded;
      case 'needs change':
        return Icons.edit_note_rounded;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  // دالة إرجاع لون الأولوية
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.statusError; // أحمر
      case 'medium':
        return AppColors.statusPending; // برتقالي
      case 'low':
        return AppColors.statusApproved; // أخضر
      case 'all':
        return AppColors.primary;
      default:
        return AppColors.textPrimary;
    }
  }

  // دالة إرجاع أيقونة الأولوية
  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.low_priority_rounded;
      case 'low':
        return Icons.flag_rounded;
      case 'all':
        return Icons.filter_list_rounded;
      default:
        return Icons.flag_outlined;
    }
  }
}

