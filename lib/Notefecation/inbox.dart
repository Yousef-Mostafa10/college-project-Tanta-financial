import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../request/Ditalis_Request/ditalis_request.dart';
import '../request/creatrequest.dart';
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
  Timer? _searchTimer;

  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
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
  List<String> statuses = [
    'All',
    'Waiting',
    'Approved',
    'Rejected',
    'Fulfilled',
    'Needs Change',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    print('🔄 Initializing InboxPage...');

    final userInfo = await _apiService.getUserInfo();
    setState(() {
      _userName = userInfo['userName'];
      _userToken = userInfo['token'];
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

  Future<void> _fetchInboxRequests() async {
    if (_isRefreshing) {
      print('⏸️ fetchInboxRequests already in progress');
      return;
    }

    if (_userToken == null || _userName == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('please_login_first');
        _isLoading = false;
      });
      print('❌ Missing token or userName');
      return;
    }

    print('🔄 fetchInboxRequests started');

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final allRequests = await _apiService.fetchInboxRequests(_userName!, _userToken!);

      // تحديث البيانات المساعدة لكل طلب
      final updatedRequests = <dynamic>[];
      for (var req in allRequests) {
        try {
          final request = Map<String, dynamic>.from(req);

          // جلب البيانات الإضافية
          request['yourCurrentStatus'] = await _apiService.getYourForwardStatusForRequestUpdated(
            request, _userToken, _userName,
          );

          request['lastSenderName'] = await _apiService.getLastSenderNameForYou(
            request, _userToken, _userName,
          );

          request['lastForwardSentTo'] = await _apiService.getLastForwardSentByYou(
            request, _userToken, _userName,
          );

          // 🔹 إضافة: التحقق مما إذا كان يمكن التوجيه (حسب منطق Angular الجديد)
          final canForward = await _apiService.checkIfCanForward(
            request['id'].toString(),
            _userToken,
            _userName,
          );
          request['hasForwarded'] = !canForward; // حفظ القيمة العكسية للحفاظ على التوافق

          updatedRequests.add(request);
        } catch (e) {
          print('⚠️ Error processing request ${req['id']}: $e');
          updatedRequests.add(req);
        }
      }

      setState(() {
        _requests = updatedRequests;
        _applyFilters();
        _isLoading = false;
        _isRefreshing = false;
      });

      print('✅ fetchInboxRequests completed - ${_requests.length} requests');

    } catch (e) {
      print("❌ Network error: $e");
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = "${AppLocalizations.of(context)!.translate('failed_load_requests')}: ${e.toString()}";
      });

      // إظهار رسالة خطأ للمستخدم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.translate('network_error')}: ${e.toString()}'),
              backgroundColor: InboxColors.accentRed,
            ),
          );
        }
      });
    }
  }

  void _applyFilters() {
    final filtered = InboxHelpers.applyFilters(
      allRequests: _requests,
      selectedType: _selectedType,
      selectedPriority: _selectedPriority,
      selectedStatus: _selectedStatus,
      searchTerm: _searchController.text.toLowerCase(),
    );

    setState(() {
      _filteredRequests = filtered;
    });

    print('🔍 Filters applied - Showing ${_filteredRequests.length} of ${_requests.length} requests');
  }

  void _onSearchChanged(String value) {
    // استخدام debounce لمنع تحديث الفلاتر مع كل حرف
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
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

  Future<void> _performAction(
      Map<String, dynamic> request,
      String action,
      Color snackBarColor, {
        String? comment,
      }) async {
    if (_isLoading) return;

    final requestId = request["id"].toString();
    final actionLower = action.toLowerCase();

    print('🎯 Performing $action on request $requestId');

    // تحديث حالة الطلب فوراً في الـ UI (قبل استجابة السيرفر)
    _updateRequestInList(requestId, {
      'yourCurrentStatus': actionLower,
      'isUpdating': true, // علامة للتحديث
    });

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final success = await _apiService.performActionUpdated(
        requestId,
        action,
        _userToken,
        _userName,
        comment: comment,
      );

      if (!mounted) return;

      if (success) {
        // إزالة علامة التحديث
        _updateRequestInList(requestId, {'isUpdating': null});

        // إعادة جلب البيانات الحقيقية من السيرفر بعد 500 مللي ثانية
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _recalculateRequestData(requestId);
          }
        });

        String successMessage = actionLower == 'approve'
            ? AppLocalizations.of(context)!.translate('action_approved_success')
            : (actionLower == 'reject'
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_perform_action')),
            backgroundColor: InboxColors.accentRed,
          ),
        );

        print('❌ $action failed for request $requestId');
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
            content: Text('${AppLocalizations.of(context)!.translate('failed_to_perform_action')}: ${e.toString()}'),
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
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_comments'),
                      border: const OutlineInputBorder(),
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
            content: Text('${AppLocalizations.of(context)!.translate('failed_to_send_change_request')}: ${e.toString()}'),
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
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_rejection_reason'),
                      border: const OutlineInputBorder(),
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
      final users = await _apiService.fetchUsers(_userToken);

      if (users.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('no_users_available')),
              backgroundColor: InboxColors.accentRed,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      String? selectedUser;
      List<String> userNames = users.map<String>((user) => user["name"]?.toString() ?? "Unknown").toList(); List<String> filteredUsers = List.from(userNames);
      TextEditingController searchController = TextEditingController();

      void filterUsers(String query) {
        if (query.isEmpty) {
          filteredUsers = List.from(userNames);
        } else {
          filteredUsers = userNames
              .where((user) => user.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                          Icon(
                            Icons.person_search_rounded,
                            color: CreateRequestColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.translate('select_user_hint'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CreateRequestColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // شريط البحث
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.translate('search_users'),
                          prefixIcon: Icon(Icons.search_rounded, color: CreateRequestColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            filterUsers(value);
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // عدد النتائج
                      Text(
                        '${filteredUsers.length} ${AppLocalizations.of(context)!.translate('users_count_label')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: CreateRequestColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),

                      // قائمة المستخدمين
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isSelected = user == selectedUser;

                            return ListTile(
                              leading: Icon(
                                Icons.person_rounded,
                                color: isSelected
                                    ? CreateRequestColors.primary
                                    : CreateRequestColors.textSecondary,
                              ),
                              title: Text(
                                user,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? CreateRequestColors.primary
                                      : CreateRequestColors.textPrimary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                Icons.check_rounded,
                                color: CreateRequestColors.primary,
                              )
                                  : null,
                              onTap: () {
                                setStateDialog(() => selectedUser = user);
                              },
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 16),

                      // أزرار الإجراء
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                searchController.clear();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CreateRequestColors.primary,
                                side: BorderSide(color: CreateRequestColors.primary),
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
                                Navigator.pop(context);
                                searchController.clear();
                                _performForwardAction(transactionId, selectedUser!, request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CreateRequestColors.primary,
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
      Map<String, dynamic> request,
      ) async {
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
            content: Text('${AppLocalizations.of(context)!.translate('failed_to_forward')}: ${e.toString()}'),
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
              child: Text(AppLocalizations.of(context)!.translate('yes'), style: const TextStyle(color: Colors.red)),
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

      final success = await _apiService.cancelForward(transactionId, forwardId, _userToken);

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('failed_to_cancel_forward')),
            backgroundColor: InboxColors.accentRed,
          ),
        );

        print('❌ Cancel forward failed for request $requestId');
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
            content: Text('${AppLocalizations.of(context)!.translate('failed_to_cancel_forward')}: ${e.toString()}'),
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
    setState(() {
      _selectedPriority = 'All';
      _selectedType = 'All Types';
      _selectedStatus = 'All';
      _searchController.clear();
    });
    _applyFilters();
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
              const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate('error_loading_requests'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: InboxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.translate('unknown_error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: InboxColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchInboxRequests,
              icon: const Icon(Icons.refresh_rounded),
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

    // استخدام الدوال المساعدة لحساب الإحصائيات
    final stats = {
      'total': _requests.length,
      'waiting': _requests.where((req) => InboxHelpers.isRequestPending(req)).length,
      'approved': _requests.where((req) => InboxHelpers.isRequestApproved(req)).length,
      'rejected': _requests.where((req) => InboxHelpers.isRequestRejected(req)).length,
      'needs_change': _requests.where((req) => InboxHelpers.isRequestNeedsChange(req)).length,
      'fulfilled': _requests.where((req) => req["fulfilled"] == true).length,
    };

    return Column(
      children: [
        InboxMobileStats(
          total: stats['total']!,
          waiting: stats['waiting']!,
          approved: stats['approved']!,
          rejected: stats['rejected']!,
          fulfilled: stats['fulfilled']!,
          needsChange: stats['needs_change']!,
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
            _applyFilters();
          },
          onTypeChanged: (value) {
            setState(() => _selectedType = value);
            _applyFilters();
          },
          onStatusChanged: (value) {
            setState(() => _selectedStatus = value);
            _applyFilters();
          },
          onSearchChanged: _onSearchChanged,
          onShowMobileFilterDialog: _showMobileFilterDialog,
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final req = _filteredRequests[index];
          final hasForwarded = req['hasForwarded'] ?? false;
          final lastForwardSentTo = req['lastForwardSentTo'];
          final isUpdating = req['isUpdating'] == true;

          return Opacity(
            opacity: isUpdating ? 0.7 : 1.0,
            child: InboxMobileCard(
              request: req,
              onViewDetails: () => _viewDetails(req["id"].toString()),
              onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
              onReject: () => _showRejectWithCommentDialog(req),
              onForward: () => _forwardTransaction(req["id"].toString(), req),
              onCancelForward: () => _cancelForward(
                req["id"].toString(),
                lastForwardSentTo?['id'],
                req,
              ),
              onNeedChange: () => _showNeedChangeDialog(req),
              onEditRequest: () => _navigateToEditRequest(req),
              hasForwarded: hasForwarded,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopBody() {
    if (_errorMessage != null && _requests.isEmpty) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InboxStatsWidget(requests: _requests),
            const SizedBox(height: 16),

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
                _applyFilters();
              },
              onTypeChanged: (value) {
                setState(() => _selectedType = value);
                _applyFilters();
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value);
                _applyFilters();
              },
              onSearchChanged: _onSearchChanged,
            ),
            const SizedBox(height: 20),

            InboxHeader(
              isMobile: false,
              itemCount: _filteredRequests.length,
            ),
            const SizedBox(height: 16),

            _buildDesktopRequestsList(),
          ],
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
        final lastForwardSentTo = req['lastForwardSentTo'];
        final isUpdating = req['isUpdating'] == true;

        return Opacity(
          opacity: isUpdating ? 0.7 : 1.0,
          child: InboxDesktopCard(
            request: req,
            onViewDetails: () => _viewDetails(req["id"].toString()),
            onApprove: () => _performAction(req, 'Approve', InboxColors.accentGreen),
            onReject: () => _showRejectWithCommentDialog(req),
            onForward: () => _forwardTransaction(req["id"].toString(), req),
            onCancelForward: () => _cancelForward(
              req["id"].toString(),
              lastForwardSentTo?['id'],
              req,
            ),
            onNeedChange: () => _showNeedChangeDialog(req),
            onEditRequest: () => _navigateToEditRequest(req),
            hasForwarded: hasForwarded,
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
            color: InboxColors.sidebarText,
          ),
        ),
        backgroundColor: InboxColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: InboxColors.sidebarText),
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
                  valueColor: AlwaysStoppedAnimation<Color>(InboxColors.sidebarText),
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
    );
  }
}