import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/utils/app_error_handler.dart';
import 'package:college_project/core/app_colors.dart';
import '../request/Ditalis_Request/ditalis_request.dart';
import '../request/editerequest.dart';
import 'inbox_api.dart';
import 'inbox_colors.dart';
import 'inbox_desktop_card.dart';
import 'inbox_desktop_filters.dart';
import 'inbox_empty_state.dart';
import 'inbox_header.dart';
import 'inbox_helpers.dart';
import 'inbox_mobile_card.dart';
import 'inbox_mobile_filters.dart';
import 'inbox_mobile_stats.dart';
import 'inbox_stats_widget.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final InboxApi _apiService = InboxApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode(); // ✅ للتحكم في بقاء التركيز على البحث
  Timer? _searchTimer;

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _userName;
  String? _userToken;
  String? _userId;

  // ✅ Pagination
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isFetchingMoreGuard = false; // حارس فوري لمنع التكرار
  int _lastRequestedPage = 0; // لمنع طلب نفس الصفحة مرتين

  // ✅ Summary من الـ API
  Map<String, int> _apiSummary = {
    'WAITING': 0,
    'NEEDS_EDITING': 0,
    'REJECTED': 0,
    'APPROVED': 0,
  };
  int _totalRequests = 0;

  // الفلاتر
  String _selectedStatus = "All";
  String _selectedType = "All Types";
  String _selectedPriority = "All";
  bool _showBackToTop = false;

  // أنواع الطلبات
  List<String> typeNames = ['All Types'];
  List<String> priorities = ['All', 'High', 'Medium', 'Low'];
  List<String> statuses = [
    'All',
    'Waiting',
    'Approved',
    'Rejected',
    'Needs Change',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  void _onScroll() {
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
    _scrollController.dispose();
    _searchTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose(); // ✅ تنظيف الـ FocusNode
    super.dispose();
  }

  Future<void> _initializeData() async {
    print('🔄 Initializing InboxPage...');

    final userInfo = await _apiService.getUserInfo();
    setState(() {
      _userName = userInfo['userName'];
      _userToken = userInfo['token'];
      _userId = userInfo['userId'];
    });

    print('👤 User Info - Name: $_userName, Token: ${_userToken != null ? "Exists" : "NULL"}');

    if (_userName != null && _userToken != null) {
      await _fetchTypes();
      await _fetchInboxRequests();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.translate('unable_load_user_info');
      });
      print('❌ User info missing: $_errorMessage');
    }
  }

  Future<void> _fetchTypes() async {
    try {
      final types = await _apiService.fetchTypes(_userToken);
      setState(() {
        typeNames = ['All Types', ...types.where((type) => type != 'All Types')];
      });
    } catch (e) {
      print("⚠️ Error fetching types: $e");
    }
  }

  Future<void> _fetchInboxRequests({bool fullLoad = true}) async {
    if (_isRefreshing) {
      print('⏸️ fetchInboxRequests already in progress');
      return;
    }

    if (_userToken == null || _userName == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('please_login_first');
        _isLoading = false;
      });
      return;
    }

    print('🔄 fetchInboxRequests started');

    setState(() {
      if (fullLoad) _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMorePages = true;
      _isFetchingMoreGuard = false;
      _lastRequestedPage = 0;
    });

    try {
      final result = await _apiService.fetchInboxRequestsPage(
        _userToken,
        page: 1,
        perPage: 10,
        priority: _selectedPriority != 'All' ? _selectedPriority : null,
        typeName: _selectedType != 'All Types' ? _selectedType : null,
        search: _searchController.text.trim(),
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );
      final pageRequests = result['data'] as List<dynamic>;
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final summary = result['summary'] as Map<String, dynamic>?;

      // تحديث الـ summary
      if (summary != null) {
        _apiSummary = {
          'WAITING': (summary['WAITING'] ?? 0) as int,
          'NEEDS_EDITING': (summary['NEEDS_EDITING'] ?? 0) as int,
          'REJECTED': (summary['REJECTED'] ?? 0) as int,
          'APPROVED': (summary['APPROVED'] ?? 0) as int,
        };
      }

      _totalRequests = pagination?['total'] ?? pageRequests.length;
      _hasMorePages = pagination?['next'] != null;
      _currentPage = pagination?['currentPage'] ?? 1;

      // تحديث البيانات المساعدة لكل طلب بشكل سريع (دون طلبات API إضافية في حلقة)
      final updatedRequests = pageRequests.map((req) {
        final request = Map<String, dynamic>.from(req);
        
        // استخدام الحالة القادمة من السيرفر مباشرة وتوحيدها
        String status = (request["lastForwardStatus"] ?? "waiting").toString().toLowerCase();
        
        // توحيد المسميات لتتوافق مع الـ UI
        if (status == 'needs_editing' || status == 'needs-editing') {
          status = 'needs_change';
        } else if (status == 'pending') {
          status = 'waiting';
        }

        if (request["fulfilled"] == true) {
          status = "fulfilled";
        }
        
        request['yourCurrentStatus'] = status;
        request['lastForwardStatus'] = status;
        
        // المحاولة الذكية للحصول على اسم المرسل (استخدام المنشئ كاحتياط)
        request['lastSenderName'] = request['lastForwardSenderName'] ?? 
                                   request['creatorName'] ?? 
                                   request['creator']?['name'] ?? 'Unknown';
                                   
        // نبدأ بـ false ونحسبها بدقة من الـ forward API
        request['hasForwarded'] = false;
        request['lastForwardSentTo'] = null;
        request['isForwardChecking'] = true; // علامة: لسه بيتحقق من الـ forward

        // توحيد هيكل النوع (Fix n/a issue)
        request['type'] = {
          'name': request['typeName'] ?? (request['type'] is Map ? request['type']['name'] : 'N/A')
        };
        
        return request;
      }).toList();

      setState(() {
        _requests = updatedRequests;
        _applyFilters();
        _isLoading = false;
        _isRefreshing = false;
      });

      // ✅ التحقق الدقيق من حالة الـ forward لكل طلب بشكل متوازي
      _loadForwardStatusForAllRequests(updatedRequests);

      print('✅ fetchInboxRequests completed - ${_requests.length} requests (total: $_totalRequests)');

    } catch (e) {
      print("❌ Network error: $e");
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = AppErrorHandler.translateException(context, e);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppErrorHandler.translateException(context, e)),
              backgroundColor: InboxColors.accentRed,
            ),
          );
        }
      });
    }
  }

  Future<void> _loadMoreRequests() async {
    if (_isFetchingMoreGuard || _isLoadingMore || !_hasMorePages) return;

    final nextPage = _currentPage + 1;
    if (nextPage <= _lastRequestedPage) return;
    _lastRequestedPage = nextPage;
    _isFetchingMoreGuard = true;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _apiService.fetchInboxRequestsPage(
        _userToken,
        page: nextPage,
        perPage: 10,
        priority: _selectedPriority != 'All' ? _selectedPriority : null,
        typeName: _selectedType != 'All Types' ? _selectedType : null,
        search: _searchController.text.trim(),
        status: _selectedStatus != 'All' ? _selectedStatus : null,
      );
      final pageRequests = result['data'] as List<dynamic>;
      final pagination = result['pagination'] as Map<String, dynamic>?;

      final updatedRequests = pageRequests.map((req) {
        final request = Map<String, dynamic>.from(req);
        
        String status = (request["lastForwardStatus"] ?? "waiting").toString().toLowerCase();
        
        // توحيد المسميات
        if (status == 'needs_editing' || status == 'needs-editing') {
          status = 'needs_change';
        } else if (status == 'pending') {
          status = 'waiting';
        }

        if (request["fulfilled"] == true) {
          status = "fulfilled";
        }
        
        request['yourCurrentStatus'] = status;
        request['lastForwardStatus'] = status;
        request['lastSenderName'] = request['lastForwardSenderName'] ?? 
                                   request['creatorName'] ?? 
                                   request['creator']?['name'] ?? 'Unknown';
        request['hasForwarded'] = false;
        request['lastForwardSentTo'] = null;
        request['isForwardChecking'] = true; // علامة: لسه بيتحقق من الـ forward
        
        // توحيد هيكل النوع (Fix n/a issue)
        request['type'] = {
          'name': request['typeName'] ?? (request['type'] is Map ? request['type']['name'] : 'N/A')
        };

        return request;
      }).toList();

      if (mounted) {
        setState(() {
          // منع التكرار
          final existingIds = _requests.map((r) => r['id'].toString()).toSet();
          final List<dynamic> newItems = [];
          for (var r in updatedRequests) {
            final id = r['id']?.toString() ?? "";
            if (id.isNotEmpty && !existingIds.contains(id)) {
              newItems.add(r);
              existingIds.add(id);
            }
          }

          _requests.addAll(newItems);
          _currentPage = pagination?['currentPage'] ?? nextPage;
          _hasMorePages = pagination?['next'] != null;
          _applyFilters();
        });

        // ✅ التحقق من حالة الـ forward للطلبات الجديدة بشكل متوازي
        _loadForwardStatusForAllRequests(updatedRequests);
      }
    } catch (e) {
      print('❌ Error loading more: $e');
      _lastRequestedPage = _currentPage;
    } finally {
      _isFetchingMoreGuard = false;
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _requests;
    });
    print('🔍 Filtered requests set - Showing ${_filteredRequests.length} requests');
  }

  // ✅ جلب حالة الـ forward لكل الطلبات بشكل تسلسلي (لتفادي إغراق السيرفر)
  Future<void> _loadForwardStatusForAllRequests(List<dynamic> requests) async {
    // نشغّل الطلبات في مجموعات صغيرة (2 في وقت واحد) مع تأخير بسيط بين كل مجموعة
    // هذا يمنع مشكلة "Connection closed before full header was received"
    const int batchSize = 2;
    const Duration delayBetweenBatches = Duration(milliseconds: 300);

    for (int i = 0; i < requests.length; i += batchSize) {
      if (!mounted) return;

      final batch = requests.skip(i).take(batchSize).toList();

      // نشغّل المجموعة الحالية بشكل متوازي مع بعض
      await Future.wait(
        batch.map((req) => _loadForwardStatusForRequest(req['id'].toString())),
      );

      // تأخير بسيط قبل المجموعة التالية لتخفيف الضغط على السيرفر
      if (i + batchSize < requests.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
  }

  Future<void> _loadForwardStatusForRequest(String requestId) async {
    try {
      // ✅ المنطق الصحيح:
      // نشوف آخر تفاعل ليا في الـ forward list (sender أو receiver)
      // لو آخر تفاعل كنت فيه receiver → المفروض تظهر أزرار الموافقة/الرفض (hasForwarded = false)
      // لو آخر تفاعل كنت فيه sender → أنا بعتها لحد (hasForwarded = true)
      // checkIfCanForward بيعمل بالظبط ده:
      //   ترجع true  → أنا الـ receiver الحالي → يظهر الأزرار
      //   ترجع false → أنا آخر sender → يظهر مستطيل الاسم
      final canForward = await _apiService.checkIfCanForward(
        requestId,
        _userToken,
        _userName,
      );

      if (!mounted) return;

      // لو مش قادر يعمل forward (أنا آخر sender) → نجيب اسم المستقبل
      Map<String, dynamic>? lastForward;
      if (!canForward) {
        lastForward = await _apiService.getLastForwardSentByYou(
          {'id': requestId},
          _userToken,
          _userName,
        );
      }

      if (!mounted) return;

      final index = _requests.indexWhere((r) => r['id'].toString() == requestId);
      if (index == -1) return;

      setState(() {
        final updatedRequest = Map<String, dynamic>.from(_requests[index]);
        if (!canForward && lastForward != null) {
          // أنا آخر sender → اعرض مستطيل "Forwarded to: اسم"
          updatedRequest['hasForwarded'] = true;
          updatedRequest['lastForwardSentTo'] = lastForward;
        } else {
          // أنا الـ receiver الحالي (حتى لو كنت sender قبل كده)
          // → اعرض أزرار الموافقة/الرفض كأنك شايفها أول مرة
          updatedRequest['hasForwarded'] = false;
          updatedRequest['lastForwardSentTo'] = null;
        }
        updatedRequest['isForwardChecking'] = false;
        _requests[index] = updatedRequest;
        _applyFilters();
      });
    } catch (e) {
      print('⚠️ Error loading forward status for request $requestId: $e');
      // في حالة الخطأ، خلي الكارد يظهر طبيعي مش متجمد
      final index = _requests.indexWhere((r) => r['id'].toString() == requestId);
      if (index != -1 && mounted) {
        setState(() {
          final updatedRequest = Map<String, dynamic>.from(_requests[index]);
          updatedRequest['isForwardChecking'] = false;
          _requests[index] = updatedRequest;
          _applyFilters();
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchInboxRequests(fullLoad: false);
    });
  }

  // 🔹 دالة لتحديث حالة طلب محدد في القائمة
  void _updateRequestInList(String requestId, Map<String, dynamic> updates) {
    final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
    if (index != -1) {
      setState(() {
        // تحديث الطلب الموجود
        final updatedRequest = Map<String, dynamic>.from(_requests[index]);
        updatedRequest.addAll(updates);
        _requests[index] = updatedRequest;

        // تطبيق الفلاتر مجدداً
        _applyFilters();
      });
      print('✅ Updated request $requestId in UI');
    } else {
      print('⚠️ Request $requestId not found in list');
    }
  }

  // 🔹 إعادة حساب البيانات المساعدة للطلب
  Future<void> _recalculateRequestData(String requestId) async {
    final index = _requests.indexWhere((req) => req["id"].toString() == requestId);
    if (index == -1) return;

    try {
      final request = _requests[index];

      // تحديث حالة الـ forward للمستخدم الحالي
      final newStatus = await _apiService.getYourForwardStatusForRequestUpdated(
        request, _userToken, _userName,
      );

      // تحديث اسم المرسل
      final lastSender = await _apiService.getLastSenderNameForYou(
        request, _userToken, _userName,
      );

      // تحديث معلومات الـ forward الأخير
      final lastForward = await _apiService.getLastForwardSentByYou(
        request, _userToken, _userName,
      );

      // 🔹 إعادة حساب حالة canForward
      final canForward = await _apiService.checkIfCanForward(
        request['id'].toString(),
        _userToken,
        _userName,
      );

      _updateRequestInList(requestId, {
        'yourCurrentStatus': newStatus,
        'lastSenderName': lastSender,
        'lastForwardSentTo': lastForward,
        'hasForwarded': !canForward, // حفظ القيمة العكسية للحفاظ على التوافق
      });

      print('✅ Recalculated data for request $requestId');
    } catch (e) {
      print('⚠️ Error recalculating request data for $requestId: $e');
    }
  }

  void _handleApiError(http.Response response, String fallbackKey) {
    // استخراج الـ key من الباك أند وترجمتها
    final errorMsg = AppErrorHandler.extractAndTranslate(
      context,
      response.body,
      fallback: AppLocalizations.of(context)?.translate(fallbackKey) ?? fallbackKey,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: InboxColors.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _performAction(
      Map<String, dynamic> request,
      String action,
      Color snackBarColor, {
        String? comment,
      }) async {
    if (_isLoading) return;

    final requestId = request["id"].toString();

    // تحويل اسم الإجراء إلى الصيغة المستخدمة في الـ UI
    String uiStatus;
    switch (action) {
      case 'Approve':
        uiStatus = 'approved';
        break;
      case 'Reject':
        uiStatus = 'rejected';
        break;
      case 'Needs Change':
        uiStatus = 'needs_change';
        break;
      default:
        uiStatus = action.toLowerCase();
    }

    print('🎯 Performing $action on request $requestId');

    // تحديث حالة الطلب فوراً في الـ UI (قبل استجابة السيرفر)
    _updateRequestInList(requestId, {
      'yourCurrentStatus': uiStatus,
      'isUpdating': true, // علامة للتحديث
    });

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final response = await _apiService.performActionUpdated(
        requestId,
        action,
        _userToken,
        _userName,
        comment: comment,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // إزالة علامة التحديث
        _updateRequestInList(requestId, {'isUpdating': null});

        // إعادة جلب البيانات الحقيقية من السيرفر بعد 500 مللي ثانية
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _recalculateRequestData(requestId);
          }
        });

        String successMessage = uiStatus == 'approved'
            ? AppLocalizations.of(context)!.translate('action_approved_success')
            : (uiStatus == 'rejected'
            ? AppLocalizations.of(context)!.translate('action_rejected_success')
            : AppLocalizations.of(context)!.translate('change_request_sent_success'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: snackBarColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        print('✅ $action successful for request $requestId');
      } else {
        // في حالة الفشل، إرجاع الحالة الأصلية
        _updateRequestInList(requestId, {
          'yourCurrentStatus': request['yourCurrentStatus'],
          'isUpdating': null,
        });

        _handleApiError(response, 'failed_to_perform_action');
        print('❌ $action failed for request $requestId with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in _performAction: $e');
      if (mounted) {
        _updateRequestInList(requestId, {
          'yourCurrentStatus': request['yourCurrentStatus'],
          'isUpdating': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔹 دالة موحدة لإظهار dialog للإجراءات (موافقة/رفض/طلب تعديل) مع تعليق
  Future<void> _showActionDialog(Map<String, dynamic> request, String action, Color color, IconData icon) async {
    String comment = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                action == 'Approve'
                    ? (AppLocalizations.of(context)!.translate('approve'))
                    : action == 'Reject'
                        ? (AppLocalizations.of(context)!.translate('reject'))
                        : (AppLocalizations.of(context)!.translate('need_change')),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action == 'Approve'
                    ? AppLocalizations.of(context)!.translate('approve_comment_hint') ?? 'Add a comment for approval (optional):'
                    : action == 'Reject'
                        ? AppLocalizations.of(context)!.translate('reject_reason_hint')
                        : AppLocalizations.of(context)!.translate('specify_changes_hint'),
                style: TextStyle(
                  fontSize: 14,
                  color: InboxColors.textSecondary,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('enter_comments'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                onChanged: (value) => comment = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(icon, size: 18),
              label: Text(
                action == 'Approve'
                    ? (AppLocalizations.of(context)!.translate('approve'))
                    : action == 'Reject'
                        ? (AppLocalizations.of(context)!.translate('reject'))
                        : (AppLocalizations.of(context)!.translate('need_change')),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _performAction(
        request,
        action,
        color,
        comment: comment.isNotEmpty ? comment : null,
      );
    }
  }

  // 🔹 دالة لإظهار dialog لطلب التعديل
  Future<void> _showNeedChangeDialog(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('request_changes')),
          content: Text(AppLocalizations.of(context)!.translate('request_changes_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(AppLocalizations.of(context)!.translate('request_changes')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    String comment = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.translate('specify_changes')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.translate('specify_changes_hint')),
                  SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_comments'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        comment = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: comment.trim().isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    _sendNeedChangeRequest(request, comment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('submit_changes_request')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 دالة لإرسال طلب التعديل
  Future<void> _sendNeedChangeRequest(
      Map<String, dynamic> request, String comment) async {
    final requestId = request["id"].toString();

    // تحديث حالة الطلب فوراً في الـ UI
    _updateRequestInList(requestId, {
      'yourCurrentStatus': 'needs_change',
      'isUpdating': true,
    });

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // استخدام _performAction بدلاً من الكود المكرر
      await _performAction(request, 'Needs Change', Colors.orange, comment: comment);
      bool success = true; // _performAction handles the snackbar and UI update

      if (!mounted) return;

      if (success) {
        // إزالة علامة التحديث
        _updateRequestInList(requestId, {'isUpdating': null});

        // إعادة جلب البيانات الحقيقية
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _recalculateRequestData(requestId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('change_request_sent_success')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        print('✅ Need change request sent for request $requestId');
        return; // Already handled by _performAction
      } else {
        // في حالة الفشل، إرجاع الحالة الأصلية
        _updateRequestInList(requestId, {
          'yourCurrentStatus': request['yourCurrentStatus'],
          'isUpdating': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_send_change_request')),
            backgroundColor: InboxColors.accentRed,
          ),
        );

        print('❌ Need change request failed for request $requestId');
      }
    } catch (e) {
      print('❌ Exception in _sendNeedChangeRequest: $e');
      if (mounted) {
        _updateRequestInList(requestId, {
          'yourCurrentStatus': request['yourCurrentStatus'],
          'isUpdating': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔹 دالة لإظهار dialog لسبب الرفض
  Future<void> _showRejectWithCommentDialog(Map<String, dynamic> request) async {
    String reason = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.translate('reject_request_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.translate('reject_reason_hint')),
                  SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_rejection_reason'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        reason = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: reason.trim().isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    _rejectWithComment(request, reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InboxColors.accentRed,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('reject')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 دالة للرفض مع التعليق
  Future<void> _rejectWithComment(
      Map<String, dynamic> request, String reason) async {
    await _performAction(request, 'Reject', InboxColors.accentRed, comment: reason);
  }

  // 🔹 دالة للتنقل إلى صفحة التعديل
  void _navigateToEditRequest(Map<String, dynamic> request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRequestPage(
          requestId: request["id"].toString(),
        ),
      ),
    ).then((_) {
      // بعد العودة، قم بتحديث قائمة الطلبات
      _fetchInboxRequests();
    });
  }

  Future<void> _forwardTransaction(
      String transactionId,
      Map<String, dynamic> request,
      ) async {
    try {
      if (!mounted) return;

      String? selectedUser;
      String forwardComment = '';

      List<dynamic> users = [];
      bool isLoadingUsers = true;
      bool isLoadingMoreUsers = false;
      bool hasMoreUsers = true;
      int usersPage = 1;
      String currentSearchQuery = '';
      TextEditingController searchController = TextEditingController();
      Timer? searchDebounce;
      bool initialLoadCalled = false;

      Future<void> fetchUsersPage(
        int page,
        void Function(void Function()) setDialogState, {
        String searchQuery = '',
        bool reset = false,
      }) async {
        try {
          final result = await _apiService.fetchUsersPaginated(
            _userToken,
            page: page,
            perPage: 10,
            name: searchQuery,
          );
          
          final rawUsers = result['users'] as List<dynamic>;
          final filteredNewUsers = rawUsers.where((u) {
            final id = u['id']?.toString();
            final name = u['name']?.toString().toLowerCase();
            return !((id != null && _userId != null && id == _userId) ||
                     (name != null && _userName != null && name == _userName?.toLowerCase()));
          }).toList();
          
          setDialogState(() {
            if (reset) {
              users = filteredNewUsers;
            } else {
              users.addAll(filteredNewUsers);
            }
            usersPage = page;
            hasMoreUsers = (result['next'] != null || result['pagination']?['next'] != null);
            isLoadingUsers = false;
            isLoadingMoreUsers = false;
          });

          // ✅ Auto-load logic: if the page is empty because of filtering but more pages exist
          if (filteredNewUsers.isEmpty && hasMoreUsers) {
             setDialogState(() => isLoadingMoreUsers = true);
             fetchUsersPage(page + 1, setDialogState, searchQuery: searchQuery, reset: false);
          }
        } catch (e) {
          setDialogState(() {
            isLoadingUsers = false;
            isLoadingMoreUsers = false;
            hasMoreUsers = false;
          });
        }
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              if (!initialLoadCalled) {
                initialLoadCalled = true;
                fetchUsersPage(1, setStateDialog, reset: true);
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(maxHeight: 600),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان الديلوج
                      Row(
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.translate('select_user_hint'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // شريط البحث
                      TextField(
                        controller: searchController,
                        focusNode: _searchFocusNode, // ✅ ربط الـ FocusNode
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('search_users'),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                          suffixIcon: isLoadingUsers && users.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          searchDebounce?.cancel();
                          searchDebounce = Timer(const Duration(milliseconds: 400), () {
                            currentSearchQuery = value.trim();
                            setStateDialog(() {
                              isLoadingUsers = true;
                              hasMoreUsers = false;
                            });
                            fetchUsersPage(
                              1,
                              setStateDialog,
                              searchQuery: currentSearchQuery,
                              reset: true,
                            );
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      if (isLoadingUsers && users.isEmpty)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 20),
                           child: Center(
                             child: Column(
                               children: [
                                 CircularProgressIndicator(color: AppColors.primary),
                                 SizedBox(height: 12),
                                 Text(
                                   AppLocalizations.of(context)!.translate('searching'),
                                   style: TextStyle(color: AppColors.textSecondary),
                                 ),
                               ],
                             ),
                           ),
                         )
                      else if (!isLoadingUsers && users.isEmpty)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 20),
                           child: Center(
                             child: Text(
                               AppLocalizations.of(context)!.translate('no_users_found'),
                               style: TextStyle(color: AppColors.textSecondary),
                             ),
                           ),
                         ),

                      // قائمة المستخدمين
                      if (users.isNotEmpty)
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                                onNotification: (scrollInfo) {
                                  if (scrollInfo.metrics.pixels >=
                                          scrollInfo.metrics.maxScrollExtent - 100 &&
                                      !isLoadingMoreUsers &&
                                      hasMoreUsers) {
                                    setStateDialog(() => isLoadingMoreUsers = true);
                                    fetchUsersPage(
                                      usersPage + 1,
                                      setStateDialog,
                                      searchQuery: currentSearchQuery,
                                      reset: false,
                                    );
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: users.length + (hasMoreUsers ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= users.length) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Center(
                                          child: isLoadingMoreUsers
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: AppColors.primary,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  AppLocalizations.of(context)!.translate('scroll_for_more'),
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                        ),
                                      );
                                    }

                                    final user = users[index];
                                    final userName = user['name']?.toString() ?? "Unknown";
                                    final isSelected = userName == selectedUser;

                                    return ListTile(
                                      leading: Icon(
                                        Icons.person_rounded,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                      title: Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_rounded,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                      onTap: () {
                                        setStateDialog(() => selectedUser = userName);
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),

                      SizedBox(height: 16),

                      // حقل التعليق
                      TextField(
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('enter_comments'),
                          prefixIcon: Icon(Icons.comment_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          forwardComment = value;
                        },
                      ),
                      SizedBox(height: 16),

                      // أزرار الإجراء
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                searchDebounce?.cancel();
                                searchController.clear();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('cancel')),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedUser == null
                                  ? null
                                  : () {
                                      searchDebounce?.cancel();
                                      Navigator.pop(context);
                                      searchController.clear();
                                      _performForwardAction(
                                        transactionId,
                                        selectedUser!,
                                        request,
                                        comment: forwardComment.isNotEmpty ? forwardComment : null,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate('forward'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('error_forwarding')}: $e'),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _performForwardAction(
      String transactionId,
      String selectedUser,
      Map<String, dynamic> request, {
        String? comment,
      }) async {
    final requestId = transactionId;

    // تحديث حالة الطلب فوراً في الـ UI
    _updateRequestInList(requestId, {
      'isUpdating': true,
      'lastForwardSentTo': {
        'receiverName': selectedUser,
        'status': 'pending',
      },
      'hasForwarded': true,
    });

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final success = await _apiService.forwardTransaction(
        transactionId,
        selectedUser,
        _userToken,
        comment: comment,
      );

      if (!mounted) return;

      if (success) {
        // إزالة علامة التحديث
        _updateRequestInList(requestId, {'isUpdating': null});

        // إعادة جلب البيانات الحقيقية
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _recalculateRequestData(requestId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('transaction_forwarded_success')),
            backgroundColor: InboxColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        print('✅ Forward successful for request $requestId');
      } else {
        // في حالة الفشل، إرجاع الحالة الأصلية
        _updateRequestInList(requestId, {
          'isUpdating': null,
          'lastForwardSentTo': request['lastForwardSentTo'],
          'hasForwarded': request['hasForwarded'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_forward')),
            backgroundColor: InboxColors.accentRed,
          ),
        );

        print('❌ Forward failed for request $requestId');
      }
    } catch (e) {
      print('❌ Exception in _performForwardAction: $e');
      if (mounted) {
        _updateRequestInList(requestId, {
          'isUpdating': null,
          'lastForwardSentTo': request['lastForwardSentTo'],
          'hasForwarded': request['hasForwarded'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelForward(
      String transactionId,
      dynamic forwardId,
      Map<String, dynamic> request,
      ) async {
    if (forwardId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('cancel_forward_title')),
          content: Text(AppLocalizations.of(context)!.translate('cancel_forward_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.translate('no')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.translate('yes'), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final requestId = transactionId;

    // تحديث حالة الطلب فوراً في الـ UI
    _updateRequestInList(requestId, {
      'isUpdating': true,
      'lastForwardSentTo': null,
      'hasForwarded': false,
    });

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final response = await _apiService.cancelForward(transactionId, forwardId, _userToken);

      if (!mounted) return;

      final success = response.statusCode >= 200 && response.statusCode < 300;

      if (success) {
        // إزالة علامة التحديث
        _updateRequestInList(requestId, {'isUpdating': null});

        // إعادة جلب البيانات الحقيقية
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _recalculateRequestData(requestId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_success')),
            backgroundColor: InboxColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        print('✅ Cancel forward successful for request $requestId');
      } else {
        // في حالة الفشل، إرجاع الحالة الأصلية
        _updateRequestInList(requestId, {
          'isUpdating': null,
          'lastForwardSentTo': request['lastForwardSentTo'],
          'hasForwarded': request['hasForwarded'],
        });

        // استخراج رسالة الخطأ المترجمة (مثل FORWARD_ALREADY_SEEN)
        final errMsg = AppErrorHandler.extractAndTranslate(
          context,
          response.body,
          fallback: AppLocalizations.of(context)!.translate('failed_to_cancel_forward'),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: InboxColors.accentRed,
          ),
        );

        print('❌ Cancel forward failed for request $requestId: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in _cancelForward: $e');
      if (mounted) {
        _updateRequestInList(requestId, {
          'isUpdating': null,
          'lastForwardSentTo': request['lastForwardSentTo'],
          'hasForwarded': request['hasForwarded'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetFilters() {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    setState(() {
      _selectedPriority = 'All';
      _selectedType = 'All Types';
      _selectedStatus = 'All';
      _searchController.clear();
      _isLoading = true;
    });
    _fetchInboxRequests();
  }

  void _viewDetails(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseApprovalRequestPage(requestId: requestId),
      ),
    );
  }

  void _handleTokenExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('session_expired')),
        backgroundColor: InboxColors.accentRed,
        action: SnackBarAction(label: AppLocalizations.of(context)!.translate('login'), onPressed: _logout),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showMobileFilterDialog(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: InboxColors.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
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
                    color: InboxColors.primary,
                  ),
                ),
              ),
              ...options.map((option) => ListTile(
                leading: Icon(
                  Icons.check_rounded,
                  color: option == currentValue ? InboxColors.primary : Colors.transparent,
                ),
                title: Text(AppLocalizations.of(context)?.translate(option.toLowerCase().replaceAll(' ', '_')) ?? option, style: TextStyle(color: InboxColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(option);
                },
              )),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_your_inbox'),
            style: TextStyle(
              fontSize: 16,
              color: InboxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: InboxColors.accentRed,
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate('error_loading_requests'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: InboxColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.translate('unknown_error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: InboxColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchInboxRequests,
              icon: Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.translate('retry_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: InboxColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOptimizedBody() {
    if (_errorMessage != null && _requests.isEmpty) {
      return _buildErrorState();
    }

    return Column(
      children: [
        InboxMobileStats(
          total: _totalRequests,
          waiting: _apiSummary['WAITING'] ?? 0,
          approved: _apiSummary['APPROVED'] ?? 0,
          rejected: _apiSummary['REJECTED'] ?? 0,
          needsChange: _apiSummary['NEEDS_EDITING'] ?? 0,
        ),

        InboxMobileFilters(
          selectedPriority: _selectedPriority,
          selectedType: _selectedType,
          selectedStatus: _selectedStatus,
          priorities: priorities,
          typeNames: typeNames,
          statuses: statuses,
          searchController: _searchController,
          onPriorityChanged: (value) {
            setState(() => _selectedPriority = value);
            _fetchInboxRequests();
          },
          onTypeChanged: (value) {
            setState(() => _selectedType = value);
            _fetchInboxRequests();
          },
          onStatusChanged: (value) {
            setState(() => _selectedStatus = value);
            _fetchInboxRequests();
          },
          onSearchChanged: _onSearchChanged,
          onShowMobileFilterDialog: _showMobileFilterDialog,
          fetchTypePage: (page) => _apiService.fetchTypesPage(_userToken, page: page),
        ),

        Expanded(
          child: _buildMobileRequestsList(),
        ),
      ],
    );
  }

  Widget _buildMobileRequestsList() {
    if (_filteredRequests.isEmpty) {
      return InboxEmptyState(onResetFilters: _resetFilters);
    }

    return RefreshIndicator(
      onRefresh: _fetchInboxRequests,
      color: InboxColors.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
              !_isLoadingMore && _hasMorePages) {
            _loadMoreRequests();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _filteredRequests.length + (_hasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator في الأسفل
            if (index == _filteredRequests.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _isLoadingMore
                      ? CircularProgressIndicator(color: InboxColors.primary, strokeWidth: 2)
                      : TextButton.icon(
                          onPressed: _loadMoreRequests,
                          icon: Icon(Icons.expand_more, color: InboxColors.primary),
                          label: Text(
                            AppLocalizations.of(context)!.translate('load_more'),
                            style: TextStyle(color: InboxColors.primary),
                          ),
                        ),
                ),
              );
            }

            final req = _filteredRequests[index];
            final hasForwarded = req['hasForwarded'] ?? false;
            final isForwardChecking = req['isForwardChecking'] ?? false;
            final lastForwardSentTo = req['lastForwardSentTo'];
            final isUpdating = req['isUpdating'] == true;

            return Opacity(
              opacity: isUpdating ? 0.7 : 1.0,
              child: InboxMobileCard(
                request: req,
                onViewDetails: () => _viewDetails(req["id"].toString()),
                onApprove: () => _showActionDialog(req, 'Approve', InboxColors.accentGreen, Icons.check_circle_rounded),
                onReject: () => _showActionDialog(req, 'Reject', InboxColors.accentRed, Icons.cancel_rounded),
                onForward: () => _forwardTransaction(req["id"].toString(), req),
                onCancelForward: () => _cancelForward(
                  req["id"].toString(),
                  lastForwardSentTo?['id'],
                  req,
                ),
                onNeedChange: () => _showActionDialog(req, 'Needs Change', Colors.orange, Icons.edit_note_rounded),
                onEditRequest: () => _navigateToEditRequest(req),
                onEditResponse: () => _showEditResponseDialog(req),
                hasForwarded: hasForwarded,
                isForwardChecking: isForwardChecking,
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ دالة لعرض dialog تعديل الرد
  Future<void> _showEditResponseDialog(Map<String, dynamic> request) async {
    String? selectedAction;
    String comment = '';
    final forwardStatus = (request['yourCurrentStatus'] ?? 'not-assigned').toString().toLowerCase();
    final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned' || forwardStatus == 'pending';
    final isApproved = forwardStatus == 'approved';
    final isRejected = forwardStatus == 'rejected';
    final needsChange = forwardStatus == 'needs_change' || forwardStatus == 'needs_editing' || forwardStatus == 'needs-editing';

    // تحديد الحالة الحالية
    if (isApproved) selectedAction = 'Approve';
    else if (isRejected) selectedAction = 'Reject';
    else if (needsChange) selectedAction = 'Needs Change';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit_rounded, color: InboxColors.primary),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.translate('edit_response')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('select_new_status'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  // أزرار الحالة
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildResponseChip(
                        'Approve',
                        Icons.check_circle_rounded,
                        InboxColors.accentGreen,
                        selectedAction == 'Approve',
                        () => setStateDialog(() => selectedAction = 'Approve'),
                      ),
                      _buildResponseChip(
                        'Reject',
                        Icons.cancel_rounded,
                        InboxColors.accentRed,
                        selectedAction == 'Reject',
                        () => setStateDialog(() => selectedAction = 'Reject'),
                      ),
                      _buildResponseChip(
                        'Needs Change',
                        Icons.edit_note_rounded,
                        Colors.orange,
                        selectedAction == 'Needs Change',
                        () => setStateDialog(() => selectedAction = 'Needs Change'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_comments'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => comment = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: selectedAction == null ? null : () async {
                    Navigator.pop(context);
                    await _editResponse(request, selectedAction!, comment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InboxColors.primary,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('update_response'),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResponseChip(String label, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تعديل الرد الحالي
  Future<void> _editResponse(Map<String, dynamic> request, String action, String comment) async {
    final requestId = request['id'].toString();

    _updateRequestInList(requestId, {'isUpdating': true});

    try {
      if (mounted) setState(() => _isLoading = true);

      final response = await _apiService.editMyResponse(
        requestId,
        action,
        _userToken,
        _userName,
        comment: comment.isNotEmpty ? comment : null,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _updateRequestInList(requestId, {'isUpdating': null});

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _recalculateRequestData(requestId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('response_updated_success') ?? 'Response updated successfully'),
            backgroundColor: InboxColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _updateRequestInList(requestId, {'isUpdating': null});
        _handleApiError(response, 'failed_to_update_response');
      }
    } catch (e) {
      if (mounted) {
        _updateRequestInList(requestId, {'isUpdating': null});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: InboxColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDesktopBody() {
    if (_errorMessage != null && _requests.isEmpty) {
      return _buildErrorState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore && _hasMorePages) {
          _loadMoreRequests();
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
              InboxStatsWidget(
                requests: _requests,
                apiSummary: _apiSummary,
                totalRequests: _totalRequests,
              ),
              SizedBox(height: 16),

              InboxDesktopFilters(
                selectedPriority: _selectedPriority,
                selectedType: _selectedType,
                selectedStatus: _selectedStatus,
                priorities: priorities,
                typeNames: typeNames,
                statuses: statuses,
                searchController: _searchController,
                onPriorityChanged: (value) {
                  setState(() => _selectedPriority = value);
                  _fetchInboxRequests();
                },
                onTypeChanged: (value) {
                  setState(() => _selectedType = value);
                  _fetchInboxRequests();
                },
                onStatusChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _fetchInboxRequests();
                },
                onSearchChanged: _onSearchChanged,
                fetchTypePage: (page) => _apiService.fetchTypesPage(_userToken, page: page),
              ),
              SizedBox(height: 20),

              InboxHeader(
                isMobile: false,
                itemCount: _filteredRequests.length,
              ),
              SizedBox(height: 16),

              _buildDesktopRequestsList(),

              // Loading more indicator
              if (_hasMorePages)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _isLoadingMore
                        ? CircularProgressIndicator(color: InboxColors.primary, strokeWidth: 2)
                        : TextButton.icon(
                            onPressed: _loadMoreRequests,
                            icon: Icon(Icons.expand_more, color: InboxColors.primary),
                            label: Text(
                              AppLocalizations.of(context)!.translate('load_more') ?? 'Load More',
                              style: TextStyle(color: InboxColors.primary),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRequestsList() {
    if (_filteredRequests.isEmpty) {
      return InboxEmptyState(onResetFilters: _resetFilters);
    }

    return Column(
      children: _filteredRequests.map((req) {
        final hasForwarded = req['hasForwarded'] ?? false;
        final isForwardChecking = req['isForwardChecking'] ?? false;
        final lastForwardSentTo = req['lastForwardSentTo'];
        final isUpdating = req['isUpdating'] == true;

        return Opacity(
          opacity: isUpdating ? 0.7 : 1.0,
          child: InboxDesktopCard(
            request: req,
            onViewDetails: () => _viewDetails(req["id"].toString()),
            onApprove: () => _showActionDialog(req, 'Approve', InboxColors.accentGreen, Icons.check_circle_rounded),
            onReject: () => _showActionDialog(req, 'Reject', InboxColors.accentRed, Icons.cancel_rounded),
            onForward: () => _forwardTransaction(req["id"].toString(), req),
            onCancelForward: () => _cancelForward(
              req["id"].toString(),
              lastForwardSentTo?['id'],
              req,
            ),
            onNeedChange: () => _showActionDialog(req, 'Needs Change', Colors.orange, Icons.edit_note_rounded),
            onEditRequest: () => _navigateToEditRequest(req),
            onEditResponse: () => _showEditResponseDialog(req),
            hasForwarded: hasForwarded,
            isForwardChecking: isForwardChecking,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: InboxColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('inbox_title'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: min(width * 0.04, 20),
            color: Colors.white,
          ),
        ),
        backgroundColor: InboxColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchInboxRequests,
            tooltip: AppLocalizations.of(context)!.translate('refresh'),
          ),
          if (_isLoading || _isRefreshing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : isMobile
          ? _buildMobileOptimizedBody()
          : _buildDesktopBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              heroTag: 'inbox_scroll_top',
              mini: true,
              onPressed: _scrollToTop,
              backgroundColor: InboxColors.primary.withOpacity(0.8),
              child: Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}
