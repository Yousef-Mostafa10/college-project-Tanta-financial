import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:college_project/l10n/app_localizations.dart';
import '../app_config.dart';
import 'transaction_type_model.dart';

// 🎨 COLOR PALETTE - Consistent with the whole application
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);

  // Background Colors
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);

  // Accent Colors
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentYellow = Color(0xFFFFB74D);

  // Status Colors
  static const Color statusPending = Color(0xFFFFB74D);
  static const Color statusFulfilled = Color(0xFF27AE60);
  static const Color statusError = Color(0xFFE74C3C);
  static const Color statusInfo = Color(0xFF1E88E5);

  // File Icon Colors
  static const Color filePdf = Color(0xFFE74C3C);
  static const Color fileDoc = Color(0xFF1E88E5);
  static const Color fileExcel = Color(0xFF27AE60);
  static const Color fileImage = Color(0xFF9C27B0);
  static const Color fileGeneric = Color(0xFF00695C);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor = Color(0xFF00695C);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF00695C);
  static const Color buttonPrimaryHover = Color(0xFF00796B);
  static const Color buttonSecondary = Color(0xFF2C3E50);
}

class EditRequestPage extends StatefulWidget {
  final String requestId;

  const EditRequestPage({Key? key, required this.requestId}) : super(key: key);

  @override
  _EditRequestPageState createState() => _EditRequestPageState();
}

class _EditRequestPageState extends State<EditRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _senderCommentController = TextEditingController();

  String? _userToken;
  String? _userName;
  int? _userId; // 🔥 معرف المستخدم
  String _selectedRequestType = 'Request Type';
  String _selectedPriority = 'Medium';

  List<TransactionType> _requestTypesData = [];
  List<String> _requestTypes = ['Request Type'];

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isUploadingFile = false;
  bool _isLoadingTypes = true;
  bool _isLoadingMoreTypes = false;
  bool _typesHasMore = true;
  int _typesCurrentPage = 1;
  bool _isCreator = false; // 🔥 الافتراضي هو false للبدء بفصح الصلاحيات

  final String _baseUrl = AppConfig.baseUrl;
  final String _documentApiUrl = AppConfig.baseUrl;

  List<dynamic> _documents = [];

  // ✅ متغيرات الملفات - بنفس طريقة CreateRequestPage
  List<PlatformFile> _selectedFiles = []; // ملفات جديدة من الجهاز
  List<Map<String, dynamic>> _previousDocuments = []; // ملفات المستخدم السابقة
  bool _isLoadingPreviousDocs = false;
  bool _isLoadingMoreDocs = false;
  bool _hasMoreDocs = true;
  int _docsCurrentPage = 1;
  List<Map<String, dynamic>> _selectedPreviousDocuments = []; // ملفات قديمة تم اختيارها

  // 🔥 متغير لتتبع الملفات المرفوعة حديثاً
  List<String> _recentlyLinkedFiles = [];

  // ✅ متغيرات الـ Forward Comment
  int? _forwardId;
  bool _isLoadingForward = false;
  bool _isUpdatingComment = false;

  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.focusBorderColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _loadUserInfo();
      if (_userToken == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('auth_token_not_found'));
        return;
      }
      await Future.wait([
        _fetchRequestTypes(),
        _fetchRequestDetails(),
      ]);
      // جلب بيانات الـ Forward بعد تحميل تفاصيل الطلب
      await _fetchForwardData();
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userToken = prefs.getString('token');
      _userName = prefs.getString('userName') ?? prefs.getString('username');
      _userId = prefs.getInt('user_id');
      
      debugPrint('👤 User Info Loaded: Name=$_userName, ID=$_userId');
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _fetchRequestTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _requestTypesData = [];
      _typesCurrentPage = 1;
      _typesHasMore = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types?page=1&perPage=10'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          List<dynamic> typesList = [];
          Map<String, dynamic>? pagination;

          if (data is Map) {
            typesList = data['data'] ?? data['transactionTypes'] ?? [];
            pagination = data['pagination'];
          } else if (data is List) {
            typesList = data;
          }

          List<TransactionType> types = typesList.map((item) => TransactionType.fromJson(item)).toList();

          setState(() {
            _requestTypesData = types;
            _requestTypes = ['Request Type', ...types.map((t) => t.name)];
            
            _typesCurrentPage = pagination?['currentPage'] ?? 1;
            _typesHasMore = pagination?['next'] != null;
            _isLoadingTypes = false;
          });
        } else {
          setState(() {
            _isLoadingTypes = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching types: $e');
      if (mounted) {
        setState(() {
          _isLoadingTypes = false;
        });
      }
    }
  }

  Future<void> _loadMoreTypes({void Function(void Function())? setStateDialog}) async {
    if (_isLoadingMoreTypes || !_typesHasMore) return;

    setState(() => _isLoadingMoreTypes = true);
    setStateDialog?.call(() {});

    try {
      final nextPage = _typesCurrentPage + 1;

      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types?page=$nextPage&perPage=10'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> typesList = [];
        Map<String, dynamic>? pagination;

        if (data is Map) {
          typesList = data['data'] ?? data['transactionTypes'] ?? [];
          pagination = data['pagination'];
        } else if (data is List) {
          typesList = data;
        }

        final newTypes = typesList.map((item) => TransactionType.fromJson(item)).toList();
        
        setState(() {
          _requestTypesData.addAll(newTypes);
          _requestTypes.addAll(newTypes.map((t) => t.name));
          
          _typesCurrentPage = pagination?['currentPage'] ?? nextPage;
          _typesHasMore = pagination?['next'] != null;
          _isLoadingMoreTypes = false;
        });
        setStateDialog?.call(() {});
      } else {
        setState(() => _isLoadingMoreTypes = false);
        setStateDialog?.call(() {});
      }
    } catch (e) {
      debugPrint('Error loading more types: $e');
      if (mounted) {
        setState(() => _isLoadingMoreTypes = false);
        setStateDialog?.call(() {});
      }
    }
  }

  Future<void> _createNewRequestType(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_documentApiUrl/transactions/types'),
        headers: {
          "Authorization": "Bearer $_userToken",
          "Content-Type": "application/json",
        },
        body: json.encode({"name": name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchRequestTypes();
        _showSuccessSnackBar(AppLocalizations.of(context)!.translate('request_type_created'));
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('request_type_create_failed').replaceFirst('{error}', response.statusCode.toString()));
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteRequestType(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.delete(
        Uri.parse('$_documentApiUrl/transactions/types/$name'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchRequestTypes();
        _showSuccessSnackBar(AppLocalizations.of(context)!.translate('request_type_deleted'));
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('request_type_delete_failed').replaceFirst('{error}', response.statusCode.toString()));
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showTypeSelectionDialog() {
    showDialog(
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
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.translate('select_request_type') ?? 'Select Request Type',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingTypes
                          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : NotificationListener<ScrollNotification>(
                              onNotification: (scrollInfo) {
                                if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 &&
                                    !_isLoadingMoreTypes && _typesHasMore) {
                                  _loadMoreTypes(setStateDialog: setStateDialog);
                                }
                                return false;
                              },
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _requestTypesData.length + (_typesHasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _requestTypesData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: _isLoadingMoreTypes
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: AppColors.primary,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                AppLocalizations.of(context)!.translate('scroll_for_more') ?? 'Scroll for more...',
                                                style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final type = _requestTypesData[index];
                                  final isSelected = type.name == _selectedRequestType;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? AppColors.primary.withOpacity(0.2)
                                          : AppColors.primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: (type.creatorName != 'System' && type.creatorName != '')
                                        ? Text(
                                            AppLocalizations.of(context)!.translate('created_by').replaceFirst('{name}', type.creatorName),
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedRequestType = type.name;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
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

  void _showManageTypesDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('manage_request_types')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(hintText: AppLocalizations.of(context)!.translate('new_type_name_hint')),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        _createNewRequestType(nameController.text.trim());
                        nameController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              Divider(),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _requestTypesData.length,
                  itemBuilder: (context, index) {
                    final type = _requestTypesData[index];
                    return ListTile(
                      title: Text(type.name),
                      subtitle: Text(AppLocalizations.of(context)!.translate('type_by').replaceFirst('{name}', type.creatorName), style: TextStyle(fontSize: 10)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
                        onPressed: () {
                          _deleteRequestType(type.name);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.translate('close'))),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRequestDetails() async {
    try {
      var response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/${widget.requestId}'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      if (response.statusCode == 404) {
        response = await http.get(
          Uri.parse('$_documentApiUrl/transaction/${widget.requestId}'),
          headers: {'Authorization': 'Bearer $_userToken'},
        );
      }

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = (rawData is Map && rawData["status"] == "success")
            ? rawData["transaction"]
            : rawData;

        debugPrint('📄 Transaction details: ${response.body}');

        if (data == null) {
          _showErrorSnackBar(AppLocalizations.of(context)!.translate('no_transaction_data'));
          return;
        }

        setState(() {
          _titleController.text = data["title"] ?? '';
          _descriptionController.text = data["description"] ?? '';

          final typeName = data["typeName"];
          if (typeName != null && _requestTypes.contains(typeName)) {
            _selectedRequestType = typeName;
          }

          final priority = data["priority"] ?? 'Medium';
          _selectedPriority = _normalizePriority(priority);

          _documents = data["documents"] ?? [];
          debugPrint('📋 Loaded ${_documents.length} documents');

          // 🔥 فحص الصلاحيات الأكثر دقة
          _checkPermissions(data);
        });
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('failed_load_request_details').replaceFirst('{error}', response.statusCode.toString()));
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
    }
  }

  // 🔥 دالة فحص الصلاحيات
  void _checkPermissions(dynamic data) {
    if (data == null) return;

    // 1. محاولة الفحص بواسطة الـ IDs (الأكثر دقة)
    final dynamic creatorIdRaw = data["creatorId"] ?? data["creator"]?["id"];
    if (creatorIdRaw != null && _userId != null) {
      final int cId = creatorIdRaw is int ? creatorIdRaw : int.tryParse(creatorIdRaw.toString()) ?? -1;
      if (cId != -1 && cId == _userId) {
        _isCreator = true;
        debugPrint('✅ Permission Granted: Match by ID ($cId)');
        return;
      }
    }

    // 2. محاولة الفحص بواسطة الأسماء (كحل احتياطي)
    final String? creatorName = (data["creatorName"] ?? data["creator"]?["name"])?.toString();
    if (creatorName != null && _userName != null) {
      if (creatorName.trim().toLowerCase() == _userName!.trim().toLowerCase()) {
        _isCreator = true;
        debugPrint('✅ Permission Granted: Match by Name ($creatorName)');
        return;
      }
    }

    // 3. إذا لم يتطابق شيء، نعتبره ليس صاحب الطلب
    _isCreator = false;
    debugPrint('🚫 Permission Denied: User is not the creator (User: $_userName/$_userId, Creator: $creatorName/$creatorIdRaw)');
  }

  // ✅ جلب بيانات الـ Forward (أول forward) للحصول على senderComment
  Future<void> _fetchForwardData() async {
    setState(() => _isLoadingForward = true);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/${widget.requestId}/forward?page=1&perPage=10'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> forwards = [];

        if (responseData is Map) {
          forwards = responseData['data'] ?? [];
        } else if (responseData is List) {
          forwards = responseData;
        }

        if (forwards.isNotEmpty) {
          // 🔥 البحث عن الـ Forward الذي قمت أنا بإرساله
          final myForward = forwards.firstWhere(
            (f) {
              final sender = f['sender'];
              if (sender == null) return false;
              
              // مطابقة بالـ ID أو بالاسم كحل احتياطي
              final sId = sender['id'];
              final sName = sender['name']?.toString().toLowerCase();
              
              bool matchId = (sId != null && _userId != null && sId == _userId);
              bool matchName = (sName != null && _userName != null && sName == _userName!.toLowerCase());
              
              return matchId || matchName;
            },
            orElse: () => null,
          );

          if (myForward != null) {
            setState(() {
              _forwardId = myForward['id'];
              _senderCommentController.text = myForward['senderComment'] ?? '';
            });
            debugPrint('✅ Found my forward: id=$_forwardId, comment=${_senderCommentController.text}');
          } else {
            debugPrint('ℹ️ No forward sent by current user found in this page');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching forward data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingForward = false);
    }
  }

  // ✅ تحديث تعليق المرسل
  Future<void> _updateSenderComment() async {
    if (_forwardId == null) return;

    setState(() => _isUpdatingComment = true);

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/transaction/${widget.requestId}/forward/$_forwardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
        body: json.encode({
          'comment': _senderCommentController.text,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Sender comment updated successfully');
      } else {
        debugPrint('❌ Failed to update comment: ${response.statusCode}');
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('sender_comment_update_failed').replaceFirst('{error}', response.statusCode.toString()));
      }
    } catch (e) {
      debugPrint('❌ Error updating comment: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingComment = false);
    }
  }

  String _normalizePriority(String priority) {
    if (priority.isEmpty) return 'Medium';
    return priority[0].toUpperCase() + priority.substring(1).toLowerCase();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentRed,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _sanitizeFileName(String originalName) {
    String cleanedName = originalName
        .replaceAll(RegExp(r'[^\w\s\.-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .trim();
    return cleanedName;
  }

  String _generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString();
    final extension = originalName.split('.').last;
    final nameWithoutExtension =
    originalName.substring(0, originalName.lastIndexOf('.'));
    final cleanedName = _sanitizeFileName(nameWithoutExtension);
    final uniqueName = '${cleanedName}_${timestamp}_$randomSuffix.$extension';
    return uniqueName;
  }

  // ✅ جلب الملفات التي رفعها المستخدم سابقاً
    Future<void> _fetchPreviousDocuments() async {
    setState(() {
      _isLoadingPreviousDocs = true;
      _previousDocuments = [];
      _docsCurrentPage = 1;
      _hasMoreDocs = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_documentApiUrl/documents/uploaded?page=1&perPage=10'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          List<dynamic> docs = [];
          Map<String, dynamic>? pagination;

          if (responseData is Map) {
            docs = responseData['data'] ?? [];
            pagination = responseData['pagination'];
          } else if (responseData is List) {
            docs = responseData;
          }

          setState(() {
            _previousDocuments = List<Map<String, dynamic>>.from(docs);
            _docsCurrentPage = pagination?['currentPage'] ?? 1;
            _hasMoreDocs = pagination?['next'] != null;
            _isLoadingPreviousDocs = false;
          });
        } else {
          setState(() {
            _previousDocuments = [];
            _isLoadingPreviousDocs = false;
            _hasMoreDocs = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previousDocuments = [];
          _isLoadingPreviousDocs = false;
          _hasMoreDocs = false;
        });
      }
    }
  }

  Future<void> _loadMorePreviousDocuments({void Function(void Function())? setStateSheet}) async {
    if (_isLoadingMoreDocs || !_hasMoreDocs) return;

    setState(() => _isLoadingMoreDocs = true);
    setStateSheet?.call(() {});

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final nextPage = _docsCurrentPage + 1;

      final response = await http.get(
        Uri.parse('$_documentApiUrl/documents/uploaded?page=$nextPage&perPage=10'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted && response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> docs = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          docs = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          docs = responseData;
        }

        final newDocs = List<Map<String, dynamic>>.from(docs);
        setState(() {
          _previousDocuments.addAll(newDocs);
          _docsCurrentPage = pagination?['currentPage'] ?? nextPage;
          _hasMoreDocs = pagination?['next'] != null;
          _isLoadingMoreDocs = false;
        });
        setStateSheet?.call(() {});
      } else {
        setState(() => _isLoadingMoreDocs = false);
        setStateSheet?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMoreDocs = false);
        setStateSheet?.call(() {});
      }
    }
  }
  // ✅ إضافة ملف قديم
  void _addPreviousDocument(Map<String, dynamic> document) {
    setState(() {
      final alreadyAdded = _selectedPreviousDocuments.any((doc) => doc['id'] == document['id']);
      if (!alreadyAdded) {
        _selectedPreviousDocuments.add(document);
      }
    });
  }

  // ✅ إزالة ملف قديم
  void _removePreviousDocument(Map<String, dynamic> document) {
    setState(() {
      _selectedPreviousDocuments.removeWhere((doc) => doc['id'] == document['id']);
    });
  }

  // ✅ ✅ ✅ قائمة المنسدلة للملفات (القديمة + رفع جديد)
  void _showFileSelectionMenu() async {
    await _fetchPreviousDocuments();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('select_files'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(height: 1, thickness: 1),
                  SizedBox(height: 16),

                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.cloud_upload_rounded, color: AppColors.accentBlue),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.translate('upload_new_files'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.translate('select_pdf_hint'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final List<PlatformFile> uniqueFiles = [];
                          for (var file in result.files) {
                            final uniqueFileName = _generateUniqueFileName(file.name);
                            final uniqueFile = PlatformFile(
                              name: uniqueFileName,
                              size: file.size,
                              path: file.path,
                              bytes: file.bytes,
                            );
                            uniqueFiles.add(uniqueFile);
                          }

                          setState(() {
                            _selectedFiles.addAll(uniqueFiles);
                          });
                        }
                      } catch (e) {}
                    },
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('previously_uploaded_files'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Expanded(
                    child: _isLoadingPreviousDocs
                        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : _previousDocuments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 32, color: AppColors.textMuted),
                                SizedBox(height: 8),
                                Text(AppLocalizations.of(context)!.translate('no_previous_files'), style: TextStyle(color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 &&
                                  !_isLoadingMoreDocs && _hasMoreDocs) {
                                _loadMorePreviousDocuments(setStateSheet: setStateSheet);
                              }
                              return false;
                            },
                            child: ListView.separated(
                              itemCount: _previousDocuments.length + (_hasMoreDocs ? 1 : 0),
                              separatorBuilder: (context, index) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index >= _previousDocuments.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: _isLoadingMoreDocs
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                            )
                                          : Text(AppLocalizations.of(context)!.translate('scroll_for_more'), style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ),
                                  );
                                }

                                final doc = _previousDocuments[index];
                                final isSelected = _selectedPreviousDocuments.any((d) => d['id'] == doc['id']);
                                final isAlreadyAttached = _documents.any((d) => d['id'] == doc['id']);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  title: Text(
                                    doc['title'] ?? AppLocalizations.of(context)!.translate('untitled'),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    isAlreadyAttached
                                        ? AppLocalizations.of(context)!.translate('already_attached')
                                        : _formatDate(doc['uploadedAt'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isAlreadyAttached ? AppColors.accentGreen : AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: isAlreadyAttached
                                      ? Icon(Icons.check_circle, color: AppColors.accentGreen)
                                      : isSelected
                                          ? Icon(Icons.check_circle_rounded, color: AppColors.accentGreen)
                                          : Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                  enabled: !isAlreadyAttached,
                                  onTap: isAlreadyAttached ? null : () {
                                    if (isSelected) {
                                      _removePreviousDocument(doc);
                                    } else {
                                      _addPreviousDocument(doc);
                                    }
                                    setStateSheet(() {});
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                  ),

                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('selected_files_label'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_selectedPreviousDocuments.length + _selectedFiles.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('done'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ رفع ملفات جديدة
  Future<void> _uploadNewFiles() async {
    if (_selectedFiles.isEmpty) return;

    for (var file in _selectedFiles) {
      try {
        final finalFileName = file.name;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_documentApiUrl/documents'),
        );

        request.headers['Authorization'] = 'Bearer $_userToken';
        request.headers['accept'] = 'application/json';

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: finalFileName,
        ));

        var response = await request.send();

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final documentData = json.decode(responseData);

          if (documentData["id"] != null) {
            final dynamic rawId = documentData["id"];
            final int documentId = rawId is int ? rawId : int.parse(rawId.toString());

            // ربط الملف بالطلب فوراً
            await _linkDocumentToTransaction(documentId);

            // إضافة الملف للقائمة
            final String title = documentData["title"] ?? file.name;
            final String uploadedAt = documentData["uploadedAt"] ?? DateTime.now().toIso8601String();
            final String uploaderName = documentData["uploaderName"] ?? _userName ?? "user";

            final Map<String, dynamic> newDocument = {
              "id": documentId,
              "title": title,
              "uploadedAt": uploadedAt,
              "uploaderName": uploaderName,
              "downloadURI": "/documents/$documentId/download"
            };

            setState(() {
              _documents.add(newDocument);
              _recentlyLinkedFiles.add(file.name);
            });
          }
        }
      } catch (e) {
        debugPrint('❌ Error uploading file: $e');
      }
    }

    setState(() {
      _selectedFiles.clear();
    });
  }

  // ✅ ربط الملفات القديمة المختارة
  Future<void> _linkPreviousDocuments() async {
    if (_selectedPreviousDocuments.isEmpty) return;

    for (var doc in _selectedPreviousDocuments) {
      try {
        final documentId = doc['id'] is int ? doc['id'] : int.parse(doc['id'].toString());

        // ربط الملف بالطلب
        await _linkDocumentToTransaction(documentId);

        // إضافة الملف للقائمة إذا لم يكن موجوداً
        setState(() {
          final exists = _documents.any((d) => d['id'] == documentId);
          if (!exists) {
            _documents.add(doc);
            _recentlyLinkedFiles.add(doc['title'] ?? AppLocalizations.of(context)!.translate('untitled'));
          }
        });
      } catch (e) {
        debugPrint('❌ Error linking document: $e');
      }
    }

    setState(() {
      _selectedPreviousDocuments.clear();
    });
  }

  // ✅ دالة منفصلة لربط ملف بالطلب
  Future<void> _linkDocumentToTransaction(int documentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_documentApiUrl/transactions/${widget.requestId}/document/$documentId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      debugPrint('🔗 Link Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Document $documentId linked successfully');
      } else {
        debugPrint('❌ Link failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error linking document: $e');
    }
  }

  Future<void> _deleteExistingFile(Map<String, dynamic> document) async {
    try {
      final dynamic rawId = document["id"];
      final int documentId = rawId is int ? rawId : int.parse(rawId.toString());
      final fileName = document["title"] ?? "file";

      final response = await http.delete(
        Uri.parse('$_documentApiUrl/documents/$documentId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _documents.removeWhere((doc) => doc["id"] == documentId);
        });
        _showSuccessSnackBar(AppLocalizations.of(context)!.translate('file_deleted_success'));
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('delete_failed_error').replaceFirst('{fileName}', fileName));
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
    }
  }

  // ✅ تعديل: تحديث الطلب مع معالجة الملفات
  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
      _isUploadingFile = true;
    });

    try {
      // 0. تحديث تعليق المرسل
      if (_forwardId != null) {
        await _updateSenderComment();
      }

      // 1. رفع الملفات الجديدة وربطها
      if (_selectedFiles.isNotEmpty) {
        await _uploadNewFiles();
      }

      // 2. ربط الملفات القديمة المختارة
      if (_selectedPreviousDocuments.isNotEmpty) {
        await _linkPreviousDocuments();
      }

      // 3. تجهيز IDs الملفات الموجودة
      List<int> documentIds = _documents.map((doc) {
        final id = doc["id"];
        return id is int ? id : int.parse(id.toString());
      }).toList();

      // 4. تحديث بيانات الطلب مع تضمين documentsIds
      final requestData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'typeName': _selectedRequestType,
        'priority': _selectedPriority.toUpperCase(),
        'documentsIds': documentIds,
      };

      debugPrint('🚀 Updating request: $requestData');

      final response = await http.patch(
        Uri.parse('$_baseUrl/transactions/${widget.requestId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_userToken',
        },
        body: json.encode(requestData),
      );

      debugPrint('📊 Update Status: ${response.statusCode}');
      debugPrint('📄 Update Response: ${response.body}');

      if (response.statusCode == 200) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.translate('request_updated_success_details'));
        await _fetchRequestDetails();
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('failed_update_request_status').replaceFirst('{status}', response.statusCode.toString()));
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
    } finally {
      setState(() {
        _isUpdating = false;
        _isUploadingFile = false;
      });
    }
  }

  Future<void> _finishEditing() async {
    _showSuccessSnackBar(AppLocalizations.of(context)!.translate('editing_completed'));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildDocumentsSection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('attached_documents'),
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        if (_isUploadingFile) ...[
          LinearProgressIndicator(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: isMobile ? 12 : 16),
        ],

        if (_recentlyLinkedFiles.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.accentGreen, size: isMobile ? 20 : 24),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.translate('files_linked_success').replaceFirst('{count}', _recentlyLinkedFiles.length.toString()),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ..._recentlyLinkedFiles.map((fileName) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '✓ $fileName',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    )
                ).toList(),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
        ],

        if (_documents.isNotEmpty) ...[
          ..._documents.map((document) => _buildDocumentItem(document, isMobile, isTablet)),
          SizedBox(height: isMobile ? 12 : 16),
        ] else ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: AppColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: isMobile ? 20 : 24),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.translate('no_documents_attached'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
        ],

        // عرض الملفات المختارة (جديدة + قديمة) قبل الرفع
        if (_selectedFiles.isNotEmpty || _selectedPreviousDocuments.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.translate('files_to_be_added'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),

          // الملفات القديمة المختارة
          ..._selectedPreviousDocuments.map((doc) => Container(
            margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGreen),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: AppColors.accentGreen, size: isMobile ? 20 : 22),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['title'] ?? AppLocalizations.of(context)!.translate('untitled'),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppLocalizations.of(context)!.translate('existing_file'),
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.accentRed, size: isMobile ? 18 : 20),
                  onPressed: () {
                    setState(() {
                      _selectedPreviousDocuments.removeWhere((d) => d['id'] == doc['id']);
                    });
                  },
                ),
              ],
            ),
          )).toList(),

          // الملفات الجديدة المختارة
          ..._selectedFiles.map((file) => Container(
            margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentBlue),
            ),
            child: Row(
              children: [
                Icon(Icons.file_present_rounded, color: AppColors.accentBlue, size: isMobile ? 20 : 22),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.accentRed, size: isMobile ? 18 : 20),
                  onPressed: () {
                    setState(() {
                      _selectedFiles.removeWhere((f) => f.name == file.name);
                    });
                  },
                ),
              ],
            ),
          )).toList(),

          SizedBox(height: isMobile ? 12 : 16),
        ],

        ElevatedButton.icon(
          onPressed: _showFileSelectionMenu,
          icon: Icon(Icons.add, size: isMobile ? 18 : 20),
          label: Text(
            AppLocalizations.of(context)!.translate('add_files'),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 14,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document, bool isMobile, bool isTablet) {
    final fileName = document["title"] ?? "document.pdf";
    final fileId = document["id"]?.toString() ?? "";
    final uploadDate = document["uploadedAt"] ?? "";
    final uploader = document["uploaderName"] ?? "";

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ListTile(
        leading: _getFileIcon(fileName),
        title: Text(
          fileName,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.translate('file_id_value').replaceFirst('{id}', fileId)} | ${AppLocalizations.of(context)!.translate('uploaded_by_user').replaceFirst('{name}', uploader)}',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (uploadDate.isNotEmpty)
              Text(
                AppLocalizations.of(context)!.translate('uploaded_at_date').replaceFirst('{date}', _formatDate(uploadDate)),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: AppColors.accentRed, size: isMobile ? 18 : 20),
          onPressed: () => _deleteExistingFile(document),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 12,
        ),
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

  Widget _buildMainContent(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? 16 :
        isTablet ? 20 :
        24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('edit_request'),
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              AppLocalizations.of(context)!.translate('edit_request_subtitle'),
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (!_isCreator) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.translate('view_only_mode_hint'),
                        style: TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: isMobile ? 16 : 24),

            Text(
              AppLocalizations.of(context)!.translate('basic_information'),
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            Text(
              '${AppLocalizations.of(context)!.translate('request_title')} *',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('request_title'),
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.translate('request_title_error') : null,
              enabled: _isCreator,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.translate('request_type_label')} *',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: AppColors.primary, size: 20),
                  onPressed: _showManageTypesDialog,
                  tooltip: AppLocalizations.of(context)!.translate('manage_request_types'),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            FormField<String>(
              initialValue: _selectedRequestType,
              validator: (v) => (_selectedRequestType == 'Request Type') ? AppLocalizations.of(context)!.translate('request_type_hint') : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _isCreator ? _showTypeSelectionDialog : null,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? AppColors.accentRed : AppColors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? AppColors.accentRed : AppColors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? AppColors.accentRed : AppColors.focusBorderColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedRequestType == 'Request Type'
                                    ? AppLocalizations.of(context)!.translate('request_type_hint')
                                    : _selectedRequestType,
                                style: TextStyle(
                                  color: _selectedRequestType == 'Request Type' ? AppColors.textMuted : AppColors.textPrimary,
                                  fontWeight: _selectedRequestType == 'Request Type' ? FontWeight.normal : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: AppColors.accentRed, fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            Text(
              AppLocalizations.of(context)!.translate('priority_label'),
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
              items: _priorityOptions.map((String value) {
                String label = value;
                if (value == 'Low') label = AppLocalizations.of(context)!.translate('priority_low');
                if (value == 'Medium') label = AppLocalizations.of(context)!.translate('priority_medium');
                if (value == 'High') label = AppLocalizations.of(context)!.translate('priority_high');
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isCreator ? (newValue) {
                setState(() { _selectedPriority = newValue!; });
              } : null,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            Text(
              '${AppLocalizations.of(context)!.translate('description_label')} *',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: isMobile ? 4 : 5,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('description_label'),
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 14 : 16,
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.translate('description_error') : null,
              enabled: _isCreator,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // ✅ خانة تعليق المرسل
            Text(
              AppLocalizations.of(context)!.translate('sender_comment_label') ?? 'Sender Comment',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            _isLoadingForward
                ? Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : TextFormField(
                    controller: _senderCommentController,
                    maxLines: isMobile ? 3 : 4,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_sender_comment') ?? 'Enter your comment...',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: isMobile ? 40 : 60),
                        child: Icon(Icons.comment_rounded, color: AppColors.primary, size: 20),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.focusBorderColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 14 : 16,
                      ),
                       suffixIcon: _forwardId == null
                           ? Tooltip(
                                message: AppLocalizations.of(context)!.translate('no_forward_comment_hint'),
                                child: Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                              )
                           : null,
                     ),
                     enabled: _forwardId != null, // 👈 متاح للتعديل لأي شخص له Forward ID خاص به
                   ),
            if (_forwardId == null && !_isLoadingForward)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('no_forward_comment_hint') ?? 'No forward found for this request',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            SizedBox(height: isMobile ? 20 : 32),

            _buildDocumentsSection(isMobile, isTablet),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: _isUpdating ? null : _updateRequest,
                  child: _isUpdating
                      ? SizedBox(
                    width: isMobile ? 20 : 24,
                    height: isMobile ? 20 : 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    AppLocalizations.of(context)!.translate('update_request_button'),
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isMobile ? 24 : 32),

            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _finishEditing,
                icon: Icon(Icons.task_alt_rounded, size: isMobile ? 22 : 26),
                label: Text(
                  AppLocalizations.of(context)!.translate('finish_button'),
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? 16 : 24),
          ],
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('edit_request')),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildLoadingState(),
      );
    }

    final content = Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('edit_request'),
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.bodyBg,
      body: _buildMainContent(isMobile, isTablet, isDesktop),
    );

    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('edit_request')),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        backgroundColor: AppColors.bodyBg,
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              child: _buildMainContent(isMobile, isTablet, isDesktop),
            ),
          ),
        ),
      );
    }
    return content;
  }
}