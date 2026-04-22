import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:college_project/l10n/app_localizations.dart';

import '../../app_config.dart';
import '../../utils/app_error_handler.dart';
import '../../utils/storage_permission_helper.dart';

import '../../core/app_colors.dart';

class CourseApprovalRequestPage extends StatefulWidget {
  final String requestId;

  const CourseApprovalRequestPage({super.key, required this.requestId});

  @override
  State<CourseApprovalRequestPage> createState() => _CourseApprovalRequestPageState();
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class _CourseApprovalRequestPageState extends State<CourseApprovalRequestPage> {
  final String _baseUrl = AppConfig.baseUrl;
  String? _userToken;
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, bool> _downloadingFiles = {};
  Map<String, String> _downloadProgress = {};
  Map<String, String> _downloadedFilePaths = {};

  // ✅ متغيرات للملفات السابقة
  List<Map<String, dynamic>> _previousDocuments = [];
  bool _isLoadingPreviousDocs = false;

  // ✅ متغيرات الـ Forwards
  List<dynamic> _forwards = [];
  bool _isLoadingForwards = false;
  bool _isLoadingMoreForwards = false;
  bool _hasMoreForwards = true;
  int _currentForwardPage = 1;

  bool _isProcessing = false;
  int? _currentUserId;
  String? _userRole;

  // ✅ متغيرات الميزانية
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoadingBudgets = false;

  @override
  void initState() {
    super.initState();
    _getUserToken();
  }

  Future<void> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('user_id');
      final userRole = prefs.getString('user_role');
      setState(() {
        _userToken = token;
        _currentUserId = userId;
        _userRole = userRole;
      });
      await _fetchRequestData();
      await _fetchBudgets();
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('error_loading_data_msg');
        _isLoading = false;
      });
    }
  }

  // ✅ جلب تفاصيل الطلب
  Future<void> _fetchRequestData() async {
    if (_userToken == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('please_login_first');
        _isLoading = false;
      });
      return;
    }

    try {
      var response = await http.get(
        Uri.parse("$_baseUrl/transactions/${widget.requestId}"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 404) {
        response = await http.get(
          Uri.parse("$_baseUrl/transaction/${widget.requestId}"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_userToken',
          },
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactionData = (data is Map && data["status"] == "success")
            ? data["transaction"]
            : data;

        if (transactionData != null) {
          setState(() {
            _requestData = transactionData;
            _isLoading = false;
          });

          // ✅ جلب الـ Forwards والمستندات بعد نجاح جلب الطلب
          _fetchForwards();
          if (transactionData["documents"] != null) {
            _fetchDocumentsDetails(transactionData["documents"]);
          }
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.translate('no_request_details_msg');
            _isLoading = false;
          });
        }
      } else {
        // استخراج الـ key الحقيقية من response وترجمتها
        final errMsg = AppErrorHandler.extractAndTranslate(
          context,
          response.body,
          fallback: AppLocalizations.of(context)!.translate('failed_load_requests'),
        );
        setState(() {
          _errorMessage = errMsg;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppErrorHandler.translateException(context, e);
        _isLoading = false;
      });
    }
  }

  // ✅ جلب تفاصيل الملفات باستخدام /api/v0/documents/{id}
  Future<void> _fetchDocumentsDetails(List<dynamic> documents) async {
    if (_userToken == null) return;

    setState(() {
      _previousDocuments = [];
      _isLoadingPreviousDocs = true;
    });

    try {
      for (var doc in documents) {
        final docId = doc["id"];
        if (docId == null) continue;

        final response = await http.get(
          Uri.parse("$_baseUrl/documents/$docId"),
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $_userToken',
          },
        );

        if (response.statusCode == 200) {
          final docData = json.decode(response.body);
          setState(() {
            _previousDocuments.add(docData);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching document details: $e');
    } finally {
      setState(() {
        _isLoadingPreviousDocs = false;
      });
    }
  }

  // ✅ جلب الـ Forwards - صفحة واحدة
  Future<void> _fetchForwards() async {
    setState(() {
      _isLoadingForwards = true;
      _forwards = [];
      _currentForwardPage = 1;
      _hasMoreForwards = true;
    });

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/transaction/${widget.requestId}/forward?page=1&perPage=10"),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> forwards = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          forwards = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          forwards = responseData;
        }

        setState(() {
          _forwards = forwards;
          _currentForwardPage = pagination?['currentPage'] ?? 1;
          _hasMoreForwards = pagination?['next'] != null;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching forwards: $e');
    } finally {
      setState(() => _isLoadingForwards = false);
    }
  }

  // ✅ تحميل المزيد من الـ Forwards
  Future<void> _loadMoreForwards() async {
    if (_isLoadingMoreForwards || !_hasMoreForwards) return;

    setState(() => _isLoadingMoreForwards = true);

    try {
      final nextPage = _currentForwardPage + 1;
      final response = await http.get(
        Uri.parse("$_baseUrl/transaction/${widget.requestId}/forward?page=$nextPage&perPage=10"),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> forwards = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          forwards = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          forwards = responseData;
        }

        if (mounted) {
          setState(() {
            _forwards.addAll(forwards);
            _currentForwardPage = pagination?['currentPage'] ?? nextPage;
            _hasMoreForwards = pagination?['next'] != null;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading more forwards: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreForwards = false);
    }
  }

  // ✅ جلب فئات الميزانية
  Future<void> _fetchBudgets() async {
    if (_userToken == null) return;
    
    setState(() => _isLoadingBudgets = true);
    
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/budget-categories?page=1&perPage=100"),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> categories = [];
        if (data is List) {
          categories = data;
        } else if (data is Map) {
          categories = data['data'] ?? [];
        }
        
        setState(() {
          _budgets = categories.map((c) => {
            'name': c['name']?.toString() ?? '',
            'available': (c['available'] as num?)?.toDouble() ?? 0.0,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching budgets: $e');
    } finally {
      setState(() => _isLoadingBudgets = false);
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null || dateValue == "N/A" || dateValue.toString().isEmpty) {
        return AppLocalizations.of(context)!.translate('not_available');
      }

      String dateString = dateValue.toString();

      if (dateString.contains('T')) {
        final date = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy - HH:mm').format(date);
      }

      return dateString;
    } catch (e) {
      return AppLocalizations.of(context)!.translate('not_available');
    }
  }

  String _formatDateOnly(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<bool> _requestPermission() async {
    return await StoragePermissionHelper.requestStoragePermission();
  }

  // ✅ تحديث دالة التحميل لاستخدام downloadURI
  Future<void> _downloadFile(int documentId, String fileName) async {
    final hasPermission = await StoragePermissionHelper.checkAndRequestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('storage_permission_denied')),
            backgroundColor: AppColors.accentRed,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.translate('settings'),
              onPressed: () => StoragePermissionHelper.openSettings(),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _downloadingFiles[fileName] = true;
      _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('starting_download_msg');
    });

    Directory? downloadDir;
    try {
      downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        downloadDir = Directory((await getTemporaryDirectory()).path);
      }

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('❌ Error getting download directory: $e');
      setState(() {
        _downloadingFiles[fileName] = false;
        _downloadProgress.remove(fileName);
      });
      return;
    }

    final filePath = '${downloadDir.path}/$fileName';

    try {
      setState(() {
        _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('downloading_status');
      });

      final response = await http.get(
        Uri.parse("$_baseUrl/documents/$documentId/download"),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $_userToken',
        },
      ).timeout(
        const Duration(seconds: 40),
        onTimeout: () => throw TimeoutException('Download timeout'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('saving_file_msg');
        });

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (await file.exists()) {
          setState(() {
            _downloadingFiles[fileName] = false;
            _downloadProgress.remove(fileName);
            _downloadedFilePaths[fileName] = filePath;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.translate('download_complete_title')),
                backgroundColor: AppColors.accentGreen,
              ),
            );
          }
          return;
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      setState(() {
        _downloadingFiles[fileName] = false;
        _downloadProgress.remove(fileName);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('download_failed_title')),
            backgroundColor: AppColors.accentRed,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.translate('retry_button'),
              textColor: Colors.white,
              onPressed: () => _downloadFile(documentId, fileName),
            ),
          ),
        );
      }
    }
  }

  void _showFileDetails(String fileName) {
    final filePath = _downloadedFilePaths[fileName];
    if (filePath == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate('file_downloaded_success_title'),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.translate('open_folder_button')}:',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(filePath,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.translate('total')}: ${_getFileSize(filePath)}',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('close'), style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openFileLocation(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(AppLocalizations.of(context)!.translate('open_folder_button'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final sizeInBytes = file.lengthSync();
        if (sizeInBytes < 1024) {
          return '$sizeInBytes B';
        } else if (sizeInBytes < 1024 * 1024) {
          return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return AppLocalizations.of(context)!.translate('unknown');
  }

  void _openFileLocation(String filePath) async {
    try {
      final file = File(filePath);
      final directory = file.parent;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.translate('open_folder_button')}: ${directory.path}'),
          backgroundColor: AppColors.accentBlue,
        ),
      );
    } catch (e) {
      print('Error opening file location: $e');
    }
  }

  // ✅ دالة لتمييز المعاملة كمكتملة (Fulfilled) - تم تحديثها لتشمل الميزانية
  Future<void> _markAsFulfilled(String budgetName, double budgetAllocation) async {
    if (_userToken == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final body = {
        "title": _requestData?["title"] ?? "",
        "description": _requestData?["description"] ?? "",
        "typeName": _requestData?["typeName"] ?? "",
        "priority": _requestData?["priority"] ?? "LOW",
        "fulfilled": true,
        "budgetName": budgetName,
        "budgetAllocation": budgetAllocation,
      };

      final response = await http.patch(
        Uri.parse("$_baseUrl/transactions/${widget.requestId}"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('request_updated_success_details') ?? "Successfully updated"),
              backgroundColor: AppColors.accentGreen,
            ),
          );
          // إعادة جلب البيانات لتحديث واجهة المستخدم
          _fetchRequestData();
          _fetchBudgets();
        }
      } else {
        // استخراج الـ key مثل: RESTRICTED_FIELD_UPDATE, TRANSACTION_ALREADY_FULFILLED
        throw Exception(AppErrorHandler.extractKeyOrFallback(response.body, response.statusCode));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.translateException(context, e)),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ✅ نافذة اختيار الميزانية وتأكيد الإنجاز
  void _showFulfillmentDialog() {
    String? selectedBudget;
    final TextEditingController amountController = TextEditingController();
    
    // إذا لم يتم تحميل الميزانيات بعد، نحاول تحميلها
    if (_budgets.isEmpty && !_isLoadingBudgets) {
      _fetchBudgets();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final subTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50];
    final borderColor = isDarkMode ? Colors.white24 : Colors.grey[300];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black45 : Colors.black26, 
                      blurRadius: 10, 
                      offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.translate('confirm_completion') ?? 'تأكيد اكتمال الطلب',
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: textColor
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.translate('budget_used') ?? 'الميزانية المستخدمة',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600, 
                        color: subTextColor
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor!),
                      ),
                      child: _isLoadingBudgets
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, 
                                      color: isDarkMode ? AppColors.accentGreen : AppColors.primary
                                    )
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.translate('loading_budgets') ?? 'جاري تحميل الميزانيات...',
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBudget,
                                hint: Text(
                                  AppLocalizations.of(context)!.translate('select_budget') ?? 'اختر الميزانية',
                                  style: TextStyle(color: subTextColor),
                                ),
                                isExpanded: true,
                                dropdownColor: cardColor,
                                icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentGreen),
                                items: _budgets.map((budget) {
                                  return DropdownMenuItem<String>(
                                    value: budget['name'],
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          budget['name'], 
                                          style: TextStyle(fontSize: 14, color: textColor)
                                        ),
                                        Text(
                                          '${budget['available']} ${AppLocalizations.of(context)!.translate('remaining') ?? 'متبقي'}', 
                                          style: TextStyle(fontSize: 12, color: subTextColor)
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() => selectedBudget = value);
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.translate('amount_to_allocate') ?? 'المبلغ المراد تخصيصه',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600, 
                        color: subTextColor
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.translate('enter_amount_hint') ?? 'أدخل المبلغ هنا',
                        hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.monetization_on_outlined, color: AppColors.accentGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accentGreen)),
                        filled: true,
                        fillColor: inputFillColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.white12 : Colors.grey[200],
                              foregroundColor: textColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.borderColor, width: 1)),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('cancel') ?? 'إلغاء', 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedBudget == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.translate('please_select_budget') ?? 'يرجى اختيار الميزانية'), 
                                    backgroundColor: Colors.orange
                                  ),
                                );
                                return;
                              }
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.translate('please_enter_valid_amount') ?? 'يرجى إدخال مبلغ صحيح'), 
                                    backgroundColor: Colors.orange
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              _markAsFulfilled(selectedBudget!, amount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.borderColor, width: 1)),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('confirm_and_complete') ?? 'تأكيد واكمال', 
                              style: const TextStyle(fontWeight: FontWeight.bold)
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
  }

  Widget _buildFulfilledButton(bool isMobile) {
    if (_isLoading || _requestData == null) return const SizedBox.shrink();
    
    final data = _requestData!;
    final fulfilled = data["fulfilled"] == true;
    final dynamic rawCreatorId = data["creatorId"] ?? data["creator"]?["id"];
    final int? creatorId = rawCreatorId is int ? rawCreatorId : (rawCreatorId != null ? int.tryParse(rawCreatorId.toString()) : null);
    
    final bool isAdmin = _userRole?.toUpperCase() == 'ADMIN';
    final bool isAccountant = _userRole?.toUpperCase() == 'ACCOUNTANT';

    // يظهر الزر فقط للأدمن أو المحاسب إذا لم تكن مكتملة بعد
    if (!(isAdmin || isAccountant) || fulfilled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 20 : 24),
      child: Container(
        width: double.infinity,
        height: isMobile ? 50 : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), AppColors.accentGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _showFulfillmentDialog,
          icon: _isProcessing 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
          label: Text(
            AppLocalizations.of(context)!.translate('status_fulfilled') ?? "Fulfilled",
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('request_details_title'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: min(width * 0.04, 20),
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _fetchRequestData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _requestData == null
          ? _buildEmptyState()
          : _buildRequestDetails(isMobile, isTablet, isDesktop),
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
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_request_details'),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.accentRed),
          SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.accentRed, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchRequestData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.translate('retry_button')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('no_request_details_msg'),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(bool isMobile, bool isTablet, bool isDesktop) {
    final data = _requestData!;
    final title = data["title"] ?? AppLocalizations.of(context)!.translate('no_title');

    // ✅ تعديل: استخدام typeName مباشرة
    final type = data["typeName"] ?? AppLocalizations.of(context)!.translate('not_available');

    String priority = data["priority"] ?? AppLocalizations.of(context)!.translate('not_available');
    if (priority.toLowerCase() == 'high') {
      priority = AppLocalizations.of(context)!.translate('priority_high');
    } else if (priority.toLowerCase() == 'medium') {
      priority = AppLocalizations.of(context)!.translate('priority_medium');
    } else if (priority.toLowerCase() == 'low') {
      priority = AppLocalizations.of(context)!.translate('priority_low');
    }

    final description = data["description"] ?? AppLocalizations.of(context)!.translate('not_available');
    final createdAt = _formatDate(data["createdAt"]);
    final fulfilled = data["fulfilled"] == true;
    final status = fulfilled 
        ? AppLocalizations.of(context)!.translate('status_fulfilled') 
        : AppLocalizations.of(context)!.translate('waiting');
    
    // 🔥 تغيير اللون إلى الأزرق للحالة Waiting
    final statusColor = fulfilled ? AppColors.accentGreen : AppColors.accentBlue;

    // ✅ محاولة استخراج الاسم من كل المفاتيح الممكنة لضمان عدم ظهور Unknown
    final creator = data["creatorName"] ?? 
                    data["creator"]?["name"] ?? 
                    data["userName"] ?? 
                    data["name"] ?? 
                    data["user"]?["name"] ?? 
                    (data["creatorId"] != null ? "User #${data["creatorId"]}" : null) ??
                    AppLocalizations.of(context)!.translate('unknown');

    final documents = data["documents"] as List<dynamic>? ?? [];

    final content = SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? 16 :
        isTablet ? 20 :
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainInfoCard(title, status, statusColor, creator, createdAt, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          _buildDetailsCard(type, priority, description, data, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          if (documents.isNotEmpty) ...[
            _buildAttachmentsCard(documents, isMobile),
            SizedBox(height: isMobile ? 16 : 20),
          ],
          _buildAdditionalInfoCard(data, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          // ✅ قسم الـ Forwards
          _buildForwardsSection(isMobile),
          // ✅ زر Mark as Fulfilled في النهاية
          _buildFulfilledButton(isMobile),
          SizedBox(height: 40), // مساحة إضافية في النهاية
        ],
      ),
    );

    if (isDesktop) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildMainInfoCard(String title, String status, Color statusColor, String creator, String createdAt, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardBg,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Row(
              children: [
                Icon(Icons.person_rounded, size: isMobile ? 14 : 16, color: AppColors.textSecondary),
                SizedBox(width: isMobile ? 4 : 6),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.translate('created_by_label')}: $creator',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today_rounded, size: isMobile ? 14 : 16, color: AppColors.textSecondary),
                SizedBox(width: isMobile ? 4 : 6),
                Flexible(
                  child: Text(
                    createdAt,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String type, String priority, String description, Map<String, dynamic> data, bool isMobile) {
    final priorityColor = _getPriorityColor(priority);
    final priorityIcon = _getPriorityIcon(priority);

    // ✅ التحقق من وجود ميزانية بأكثر من مفتاح محتمل وصلاحية المستخدم
    final bName = data["budgetName"] ?? data["budget_name"];
    final bAlloc = data["budgetAllocation"] ?? data["budget_allocation"];
    final bool isAdminOrAccountant = _userRole?.toUpperCase() == 'ADMIN' || _userRole?.toUpperCase() == 'ACCOUNTANT';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardBg,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('request_details_title'),
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
              Wrap(
              spacing: isMobile ? 8 : 12,
              runSpacing: isMobile ? 8 : 12,
              children: [
                _buildDetailChip('${AppLocalizations.of(context)!.translate('type')}: $type', Icons.category_rounded, AppColors.primary, isMobile),
                _buildDetailChip('${AppLocalizations.of(context)!.translate('priority')}: $priority', priorityIcon, priorityColor, isMobile),
              ],
            ),
            // ✅ عرض بيانات الميزانية للأدمن والمحاسب فقط

            if (isAdminOrAccountant && ((bName != null && bName.toString().isNotEmpty) || (bAlloc != null && bAlloc != 0))) ...[
              SizedBox(height: isMobile ? 12 : 16),
              Wrap(
                spacing: isMobile ? 8 : 12,
                runSpacing: isMobile ? 8 : 12,
                children: [
                   if (bName != null && bName.toString().isNotEmpty)
                     _buildDetailChip('${AppLocalizations.of(context)!.translate('budget_name')}: $bName', Icons.account_balance_wallet_rounded, AppColors.accentBlue, isMobile),
                   if (bAlloc != null && bAlloc != 0)
                     _buildDetailChip('${AppLocalizations.of(context)!.translate('budget_allocation')}: $bAlloc', Icons.attach_money_rounded, AppColors.accentGreen, isMobile),
                ],
              ),
            ],
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              AppLocalizations.of(context)!.translate('description_label'),
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(List<dynamic> documents, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardBg,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file_rounded, color: AppColors.primary, size: isMobile ? 18 : 20),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  '${AppLocalizations.of(context)!.translate('attachments_label')} (${documents.length})',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            ...documents.map((doc) => _buildAttachmentItem(doc, isMobile)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(Map<String, dynamic> document, bool isMobile) {
    final fileName = document["title"]?.toString() ?? "document.pdf";
    final uploaderName = document["uploaderName"]?.toString() ?? "Admin";
    final fileId = document["id"];
    final isDownloading = _downloadingFiles[fileName] == true;
    final downloadStatus = _downloadProgress[fileName];
    final isDownloaded = _downloadedFilePaths.containsKey(fileName);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: isMobile
          ? _buildMobileAttachmentItem(
          fileName, uploaderName, fileId, isDownloading,
          downloadStatus, isDownloaded, fileId, isMobile)
          : _buildDesktopAttachmentItem(
          fileName, uploaderName, fileId, isDownloading,
          downloadStatus, isDownloaded, fileId, isMobile),
    );
  }

  Widget _buildMobileAttachmentItem(
      String fileName, String uploaderName, dynamic fileId,
      bool isDownloading, String? downloadStatus, bool isDownloaded,
      dynamic documentId, bool isMobile) {
    return ListTile(
      leading: _getFileIcon(fileName),
      title: Text(
        fileName,
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Container(
        constraints: BoxConstraints(maxHeight: 40),
        child: _buildFileSubtitle(
            uploaderName, fileId.toString(), isDownloading, downloadStatus, isDownloaded, fileName, isMobile),
      ),
      trailing: _buildDownloadButton(isDownloading, isDownloaded, documentId, fileName, isMobile),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isThreeLine: false,
    );
  }

  Widget _buildDesktopAttachmentItem(
      String fileName, String uploaderName, dynamic fileId,
      bool isDownloading, String? downloadStatus, bool isDownloaded,
      dynamic documentId, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: _getFileIcon(fileName),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.translate('by')}: $uploaderName',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (fileId != null) ...[
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.translate('file_id_label')}: $fileId',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (isDownloading && downloadStatus != null) ...[
                  SizedBox(height: 6),
                  _buildDownloadProgress(downloadStatus, false),
                ],
                if (isDownloaded) ...[
                  SizedBox(height: 6),
                  _buildDownloadedStatus(fileName, false),
                ],
              ],
            ),
          ),
          SizedBox(width: 12),
          _buildDownloadButton(isDownloading, isDownloaded, documentId, fileName, false),
        ],
      ),
    );
  }

  Widget _buildFileSubtitle(
      String uploaderName, String fileId, bool isDownloading,
      String? downloadStatus, bool isDownloaded, String fileName, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${AppLocalizations.of(context)!.translate('by')}: $uploaderName',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              if (fileId.isNotEmpty) ...[
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                Text('${AppLocalizations.of(context)!.translate('file_id_label')}: $fileId',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (isDownloading && downloadStatus != null)
          _buildDownloadProgress(downloadStatus, isMobile),
        if (isDownloaded)
          _buildDownloadedStatus(fileName, isMobile),
      ],
    );
  }

  Widget _buildDownloadProgress(String downloadStatus, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Text(
          downloadStatus,
          style: TextStyle(fontSize: isMobile ? 10 : 11, color: AppColors.accentYellow),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: AppColors.borderColor,
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildDownloadedStatus(String fileName, bool isMobile) {
    return Tooltip(
      message: AppLocalizations.of(context)!.translate('view_details'),
      child: GestureDetector(
        onTap: () => _showFileDetails(fileName),
        child: Container(
          margin: EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: isMobile ? 12 : 14, color: AppColors.accentGreen),
              SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.translate('fulfilled'),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  color: AppColors.accentGreen,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(bool isDownloading, bool isDownloaded, dynamic documentId, String fileName, bool isMobile) {
    if (isDownloading) {
      return Container(
        width: isMobile ? 32 : 40,
        height: isMobile ? 32 : 40,
        padding: EdgeInsets.all(isMobile ? 6 : 8),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (isDownloaded) {
      return GestureDetector(
        onTap: () => _showFileDetails(fileName),
        child: Tooltip(
          message: AppLocalizations.of(context)!.translate('view_details'),
          child: Container(
            width: isMobile ? 32 : 40,
            height: isMobile ? 32 : 40,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGreen),
            ),
            child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: isMobile ? 16 : 18
            ),
          ),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: _isProcessing,
      child: Container(
        width: isMobile ? 40 : 48,
        height: isMobile ? 40 : 48,
        child: IconButton(
          icon: Icon(
            Icons.download_rounded,
            color: _isProcessing ? AppColors.textMuted : AppColors.primary,
            size: isMobile ? 20 : 24,
          ),
          onPressed: () async {
            if (_isProcessing) return;
            setState(() => _isProcessing = true);
            final int? id = documentId is int ? documentId : int.tryParse(documentId.toString());
            if (id != null) {
              await _downloadFile(id, fileName);
            } else {
              debugPrint('❌ Invalid document ID type: ${documentId.runtimeType}');
            }
            setState(() => _isProcessing = false);
          },
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(Map<String, dynamic> data, bool isMobile) {
    final creator = data["creatorName"] ?? 
                    data["creator"]?["name"] ?? 
                    data["userName"] ?? 
                    data["name"] ?? 
                    data["user"]?["name"] ?? 
                    (data["creatorId"] != null ? "User #${data["creatorId"]}" : null) ??
                    AppLocalizations.of(context)!.translate('unknown');
                    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardBg,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('additional_info_label'),
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildInfoRow(AppLocalizations.of(context)!.translate('request_id_label'), data["id"]?.toString() ?? AppLocalizations.of(context)!.translate('not_available'), isMobile),
            _buildInfoRow(AppLocalizations.of(context)!.translate('created_at'), _formatDate(data["createdAt"]), isMobile),
            if (data["updatedAt"] != null)
              _buildInfoRow(AppLocalizations.of(context)!.translate('updated_at'), _formatDate(data["updatedAt"]), isMobile),

            if (creator != AppLocalizations.of(context)!.translate('unknown'))
              _buildInfoRow(AppLocalizations.of(context)!.translate('created_by_label'), creator, isMobile),
          ],
        ),
      ),
    );
  }

  // ✅ قسم الـ Forwards - بسيط ومباشر
  Widget _buildForwardsSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.cardBg,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.forward_rounded,
                  color: AppColors.primary,
                  size: isMobile ? 18 : 20,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  AppLocalizations.of(context)!.translate('forwards_label') ?? 'Forwards',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_forwards.isNotEmpty) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_forwards.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // المحتوى
            _isLoadingForwards
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _forwards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 32,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('no_forwards_yet') ?? 'No forwards yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _forwards.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 24,
                              thickness: 1,
                              color: AppColors.borderColor,
                            ),
                            itemBuilder: (context, index) {
                              return _buildForwardItem(_forwards[index], isMobile);
                            },
                          ),
                          // مؤشر تحميل المزيد
                          if (_isLoadingMoreForwards)
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          // زر تحميل المزيد
                          if (_hasMoreForwards && !_isLoadingMoreForwards)
                            TextButton.icon(
                              onPressed: _loadMoreForwards,
                              icon: Icon(Icons.expand_more_rounded, color: AppColors.primary),
                              label: Text(
                                AppLocalizations.of(context)!.translate('load_more') ?? 'Load More',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  // ✅ عنصر Forward واحد - بسيط
  Widget _buildForwardItem(dynamic forward, bool isMobile) {
    final senderName = forward['sender']?['name'] ?? '?';
    final receiverName = forward['receiver']?['name'] ?? '?';
    final status = (forward['status'] ?? 'WAITING').toString().toUpperCase();
    final senderComment = forward['senderComment'];
    final receiverComment = forward['receiverComment'];
    final senderSeen = forward['senderSeen'] == true;
    final receiverSeen = forward['receiverSeen'] == true;
    final forwardedAt = _formatDateOnly(forward['forwardedAt']);

    // ألوان الحالة
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'APPROVED':
        statusColor = AppColors.accentGreen;
        statusText = AppLocalizations.of(context)!.translate('status_approved');
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = AppColors.accentRed;
        statusText = AppLocalizations.of(context)!.translate('status_rejected');
        statusIcon = Icons.cancel_rounded;
        break;
      case 'NEEDS_EDITING':
        statusColor = AppColors.accentYellow;
        statusText = AppLocalizations.of(context)!.translate('status_needs_editing');
        statusIcon = Icons.edit_note_rounded;
        break;
      default:
        statusColor = AppColors.accentBlue; // 🔥 التأكد من أن الانتظار لونه أزرق
        statusText = AppLocalizations.of(context)!.translate('status_waiting');
        statusIcon = Icons.hourglass_empty_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // المرسل ➔ المستقبل + التاريخ (محمي من القلب في العربية)
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr, // 🔥 إجبار الترتيب من اليسار لليمين للمسار المنطقي
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: isMobile ? 14 : 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded, 
                        size: 14, 
                        color: AppColors.primary.withOpacity(0.5)
                      ),
                    ),
                    Flexible(
                      child: Text(
                        receiverName,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              forwardedAt,
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // الحالة + Seen
        Row(
          children: [
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Sender seen
            _buildSeenBadge(
              label: AppLocalizations.of(context)!.translate('sender') ?? 'Sender',
              seen: senderSeen,
              color: AppColors.accentBlue,
              isMobile: isMobile,
            ),
            SizedBox(width: 6),
            // Receiver seen
            _buildSeenBadge(
              label: AppLocalizations.of(context)!.translate('receiver') ?? 'Receiver',
              seen: receiverSeen,
              color: AppColors.accentGreen,
              isMobile: isMobile,
            ),
          ],
        ),

        // تعليق المرسل
        if (senderComment != null && senderComment.toString().isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentBlue.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.accentBlue),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    senderComment.toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // تعليق المستقبل
        if (receiverComment != null && receiverComment.toString().isNotEmpty) ...[
          SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.reply_rounded, size: 12, color: AppColors.accentGreen),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    receiverComment.toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ✅ Seen badge بسيط
  Widget _buildSeenBadge({required String label, required bool seen, required Color color, required bool isMobile}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          seen ? Icons.done_all_rounded : Icons.done_rounded,
          size: isMobile ? 12 : 14,
          color: seen ? color : AppColors.textMuted,
        ),
        SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 9 : 10,
            color: seen ? color : AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: color),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf_rounded, color: AppColors.filePdf);
    } else if (fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx')) {
      return Icon(Icons.description_rounded, color: AppColors.fileDoc);
    } else if (fileName.toLowerCase().endsWith('.xls') || fileName.toLowerCase().endsWith('.xlsx')) {
      return Icon(Icons.table_chart_rounded, color: AppColors.fileExcel);
    } else if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png')) {
      return Icon(Icons.image_rounded, color: AppColors.fileImage);
    } else {
      return Icon(Icons.insert_drive_file_rounded, color: AppColors.fileGeneric);
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Icons.warning_amber_rounded;
      case 'medium': return Icons.info_rounded;
      case 'low': return Icons.flag_rounded;
      default: return Icons.flag_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.accentRed;
      case 'medium': return AppColors.accentYellow;
      case 'low': return AppColors.accentGreen;
      default: return AppColors.textMuted;
    }
  }
}