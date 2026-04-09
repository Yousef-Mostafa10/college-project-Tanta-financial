import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../app_config.dart';
import 'transaction_type_model.dart';

import '../core/app_colors.dart';

// 🎨 COLOR PALETTE - Consistent with Dashboard and Inbox
class CreateRequestColors {
  // ─── FOREST DARK THEME ─────────────────────────────────────────
  static Color get primary         => AppColors.primary;
  static Color get primaryLight    => AppColors.primaryLight;

  static Color get bodyBg          => AppColors.bodyBg;
  static Color get cardBg          => AppColors.cardBg;

  static Color get textPrimary     => AppColors.textPrimary;
  static Color get textSecondary   => AppColors.textSecondary;
  static Color get textMuted       => AppColors.textMuted;

  static Color get accentRed       => AppColors.accentRed;
  static Color get accentGreen     => AppColors.accentGreen;
  static Color get accentBlue      => AppColors.accentBlue;
  static Color get accentYellow    => AppColors.accentYellow;

  // Always dark for headers: white text must be readable in both themes
  static Color get primaryGradientStart => AppColors.headerGradientStart;
  static Color get primaryGradientEnd   => AppColors.headerGradientEnd;

  static Color get borderColor     => AppColors.borderColor;
  static Color get focusBorderColor=> AppColors.primary;
  static Color get shadowColor     => AppColors.shadowColor;
}

class CreateRequestPage extends StatefulWidget {
  @override
  _CreateRequestPageState createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _userSearchController = TextEditingController();

  final _titleKey = GlobalKey();
  final _typeKey = GlobalKey();
  final _descriptionKey = GlobalKey();

  String _selectedRequestType = 'Request Type';
  String _selectedPriority = 'Medium';
  String _selectedReceiver = 'Select User';

  List<TransactionType> _requestTypesData = [];
  List<String> _requestTypes = ['Request Type'];

  // ✅ تعديل: تخزين بيانات المستخدمين بنظام الصفحات
  List<Map<String, dynamic>> _usersData = [];
  List<Map<String, dynamic>> _filteredUsersData = [];
  bool _isLoadingUsers = true;
  bool _isLoadingMoreUsers = false;
  bool _usersHasMore = true;
  int _usersCurrentPage = 1;

  // ✅ الملفات السابقة للمستخدم
  List<Map<String, dynamic>> _previousDocuments = [];
  bool _isLoadingPreviousDocs = false;
  bool _isLoadingMoreDocs = false;
  bool _hasMoreDocs = true;
  int _docsCurrentPage = 1;
  List<Map<String, dynamic>> _selectedPreviousDocuments = [];

  bool _isLoadingTypes = true;
  bool _isLoadingMoreTypes = false;
  bool _typesHasMore = true;
  int _typesCurrentPage = 1;
  bool _isSubmitting = false;

  Timer? _userSearchTimer;

  List<int> _uploadedDocumentIds = [];
  List<PlatformFile> _selectedFiles = [];

  final String _documentApiUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchRequestTypes();
    fetchUsers();
    _requestTypes = ['Request Type'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _userSearchController.dispose();
    _userSearchTimer?.cancel();
    super.dispose();
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

        setState(() {
          _previousDocuments.addAll(List<Map<String, dynamic>>.from(docs));
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

  Future<void> fetchRequestTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _requestTypesData = [];
      _requestTypes = ['Request Type']; // Reset names list
      _typesCurrentPage = 1;
      _typesHasMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types?page=1&perPage=10'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          List<dynamic> typesList = [];
          Map<String, dynamic>? pagination;

          if (responseData is Map) {
            typesList = responseData['data'] ?? responseData['transactionTypes'] ?? [];
            pagination = responseData['pagination'];
          } else if (responseData is List) {
            typesList = responseData;
          }

          List<TransactionType> types = typesList.map((item) => TransactionType.fromJson(item)).toList();

          setState(() {
            _requestTypesData = types;
            final typeNames = types.map((t) => t.name).toList();
            _requestTypes = ['Request Type', ...typeNames];
            
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final nextPage = _typesCurrentPage + 1;

      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types?page=$nextPage&perPage=10'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted && response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> typesList = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          typesList = responseData['data'] ?? responseData['transactionTypes'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          typesList = responseData;
        }

        final newTypes = typesList.map((item) => TransactionType.fromJson(item)).toList();
        
        setState(() {
          _requestTypesData.addAll(newTypes);
          final typeNames = newTypes.map((t) => t.name).toList();
          _requestTypes.addAll(typeNames);
          
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
      if (mounted) {
        setState(() => _isLoadingMoreTypes = false);
        setStateDialog?.call(() {});
      }
    }
  }

    // ✅ جلب أول صفحة من المستخدمين
  Future<void> fetchUsers({String? name}) async {
    setState(() {
      _isLoadingUsers = true;
      _usersData = [];
      _usersCurrentPage = 1;
      _usersHasMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String url = '$_documentApiUrl/users?page=1&perPage=10';
      if (name != null && name.isNotEmpty) {
        url += '&name=${Uri.encodeComponent(name)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          List<dynamic> users = [];
          Map<String, dynamic>? pagination;

          if (responseData is Map) {
            users = responseData['data'] ?? [];
            pagination = responseData['pagination'];
          } else if (responseData is List) {
            users = responseData;
          }

          final currentUserId = prefs.getInt('user_id');

          setState(() {
            _usersData = users
                .where((u) {
              final id = u['id'] is int ? u['id'] : int.tryParse(u['id'].toString());
              return id != currentUserId;
            })
                .map((u) => Map<String, dynamic>.from(u))
                .toList();
            _filteredUsersData = List.from(_usersData);
            _usersCurrentPage = pagination?['currentPage'] ?? 1;
            _usersHasMore = pagination?['next'] != null;
            _isLoadingUsers = false;
          });
        } else {
          setState(() {
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  // ✅ جلب المزيد من المستخدمين (عند السكرول)
  Future<void> _loadMoreUsers({void Function(void Function())? setStateDialog, String? name}) async {
    if (_isLoadingMoreUsers || !_usersHasMore) return;

    setState(() => _isLoadingMoreUsers = true);
    setStateDialog?.call(() {});

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final nextPage = _usersCurrentPage + 1;

      String url = '$_documentApiUrl/users?page=$nextPage&perPage=10';
      if (name != null && name.isNotEmpty) {
        url += '&name=${Uri.encodeComponent(name)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted && response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> users = [];
        Map<String, dynamic>? pagination;

        if (responseData is Map) {
          users = responseData['data'] ?? [];
          pagination = responseData['pagination'];
        } else if (responseData is List) {
          users = responseData;
        }

        final newUsersRaw = List<Map<String, dynamic>>.from(users);
        final currentUserId = prefs.getInt('user_id');
        final newUsers = newUsersRaw.where((u) {
          final id = u['id'] is int ? u['id'] : int.tryParse(u['id'].toString());
          return id != currentUserId;
        }).toList();

        setState(() {
          _usersData.addAll(newUsers);
          _usersCurrentPage = pagination?['currentPage'] ?? nextPage;
          _usersHasMore = pagination?['next'] != null;
          _isLoadingMoreUsers = false;
          _filterUsers(_userSearchController.text);
        });
        setStateDialog?.call(() {});
      } else {
        setState(() => _isLoadingMoreUsers = false);
        setStateDialog?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMoreUsers = false);
        setStateDialog?.call(() {});
      }
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      _filteredUsersData = List.from(_usersData);
    } else {
      _filteredUsersData = _usersData
          .where((user) =>
          user['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          user['id'].toString().contains(query))
          .toList();
    }
  }

  Future<void> _createNewRequestType(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$_documentApiUrl/transactions/types'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({"name": name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRequestTypes();
        _showSuccessMessage('Type created successfully!');
      } else {
        _handleApiError(response, 'Failed to create type');
      }
    } catch (e) {
      _showErrorMessage(e.toString().replaceFirst('Exception: ', ''));
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
        await fetchRequestTypes();
        _showSuccessMessage('Type deleted successfully!');
      } else {
        _handleApiError(response, 'Failed to delete type');
      }
    } catch (e) {
      _showErrorMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showManageTypesDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Manage Request Types'),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: 'New type name'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: CreateRequestColors.primary),
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
                  height: 300,
                  width: double.maxFinite,
                  child: _isLoadingTypes
                      ? Center(child: CircularProgressIndicator(color: CreateRequestColors.primary))
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
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
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                    child: _isLoadingMoreTypes 
                                      ? CircularProgressIndicator(strokeWidth: 2, color: CreateRequestColors.primary)
                                      : SizedBox.shrink(),
                                  ),
                                );
                              }
                              final type = _requestTypesData[index];
                              return ListTile(
                                title: Text(type.name),
                                subtitle: Text('By: ${type.creatorName}', style: TextStyle(fontSize: 10)),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: CreateRequestColors.accentRed, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (confirmContext) => AlertDialog(
                                        title: Text('Delete Type'),
                                        content: Text('Are you sure you want to delete "${type.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(confirmContext),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(confirmContext);
                                              _deleteRequestType(type.name).then((_) {
                                                setStateDialog(() {});
                                              });
                                            },
                                            child: Text('Delete', style: TextStyle(color: CreateRequestColors.accentRed)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    final translated = AppLocalizations.of(context)?.translate(message) ?? message;
    final displayMsg = (translated != message) ? translated : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMsg),
        backgroundColor: CreateRequestColors.accentRed,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    
    final translated = AppLocalizations.of(context)?.translate(message) ?? message;
    final displayMsg = (translated != message) ? translated : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMsg),
        backgroundColor: CreateRequestColors.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleApiError(http.Response response, String fallback) {
    String errorMsg = fallback;
    try {
      if (response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is Map) {
          final rawMsg = data["message"] ?? data["error"] ?? data["msg"];
          if (rawMsg is Map) {
            if (rawMsg['ar'] != null) errorMsg = rawMsg['ar'];
            else if (rawMsg['en'] != null) errorMsg = rawMsg['en'];
            else if (rawMsg['key'] != null) errorMsg = rawMsg['key'];
          } else if (rawMsg is String) {
             errorMsg = rawMsg;
          }
        }
      }
    } catch (_) {}
    _showErrorMessage(errorMsg);
  }

  Future<void> _uploadNewFiles() async {
    if (_selectedFiles.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    for (var file in _selectedFiles) {
      try {
        // ✅ استخدام الاسم الفريد الذي تم إنشاؤه عند الاختيار
        final finalFileName = file.name;

        if (file.path == null) continue;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_documentApiUrl/documents'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.headers['accept'] = 'application/json'; // ✅ إضافة header مفقود
        
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: finalFileName,
        ));

        debugPrint('📄 Uploading: $finalFileName');

        var response = await request.send();

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final documentData = json.decode(responseData);

          if (documentData["id"] != null) {
            final dynamic rawId = documentData["id"];
            final int documentId = rawId is int ? rawId : int.parse(rawId.toString());
            _uploadedDocumentIds.add(documentId);
            debugPrint('✅ Uploaded: $finalFileName (ID: $documentId)');
          }
        } else {
          debugPrint('❌ Failed upload: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Exception upload: $e');
      }
    }
  }

  void _addPreviousDocument(Map<String, dynamic> document) {
    setState(() {
      final alreadyAdded = _selectedPreviousDocuments.any((doc) => doc['id'] == document['id']);
      if (!alreadyAdded) {
        _selectedPreviousDocuments.add(document);
        _uploadedDocumentIds.add(document['id'] as int);
      }
    });
  }

  void _removePreviousDocument(Map<String, dynamic> document) {
    setState(() {
      _selectedPreviousDocuments.removeWhere((doc) => doc['id'] == document['id']);
      _uploadedDocumentIds.remove(document['id'] as int);
    });
  }

  // ✅ حذف ملف من السيرفر تماماً
  Future<void> _deleteDocument(Map<String, dynamic> document, {void Function(void Function())? setStateSheet}) async {
    try {
      final dynamic rawId = document["id"];
      final int documentId = rawId is int ? rawId : int.parse(rawId.toString());
      final fileName = document["title"] ?? "file";

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.delete(
        Uri.parse('$_documentApiUrl/documents/$documentId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          setState(() {
            _previousDocuments.removeWhere((doc) => doc["id"] == documentId);
            _selectedPreviousDocuments.removeWhere((doc) => doc["id"] == documentId);
            _uploadedDocumentIds.remove(documentId);
          });
          setStateSheet?.call(() {});
          _showSuccessMessage(AppLocalizations.of(context)!.translate('file_deleted_success') ?? 'File deleted successfully');
        }
      } else if (response.statusCode == 403) {
        _handleApiError(response, 'document_already_used');
      } else {
        _handleApiError(response, 'Failed to delete file "$fileName"');
      }
    } catch (e) {
      _showErrorMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ✅ ✅ ✅ قائمة المنسدلة للملفات (القديمة + رفع جديد)
  void _showFileSelectionMenu() async {
    await _fetchPreviousDocuments();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surface,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: CreateRequestColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Files',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CreateRequestColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: CreateRequestColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: CreateRequestColors.accentBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CreateRequestColors.accentBlue.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CreateRequestColors.accentBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_upload_rounded, color: CreateRequestColors.accentBlue),
                      ),
                      title: Text(
                        'Upload New Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CreateRequestColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Select PDF files from your device',
                        style: TextStyle(
                          fontSize: 13,
                          color: CreateRequestColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.add_rounded,
                        color: CreateRequestColors.accentBlue,
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
                          // ✅ إنشاء أسماء فريدة للملفات كما في editerequest.dart
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
                ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CreateRequestColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.history_rounded, size: 18, color: CreateRequestColors.primary),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Previously Uploaded Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CreateRequestColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Expanded(
                    child: _isLoadingPreviousDocs
                      ? Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: CreateRequestColors.primary,
                      ),
                    ),
                  )
                      : _previousDocuments.isEmpty
                      ? Container(
                    height: 100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 32,
                            color: CreateRequestColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No previous files found',
                            style: TextStyle(
                              color: CreateRequestColors.textMuted,
                            ),
                          ),
                        ],
                      ),
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
                        shrinkWrap: true,
                        itemCount: _previousDocuments.length + (_hasMoreDocs ? 1 : 0),
                        separatorBuilder: (context, index) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          // عنصر تحميل المزيد
                          if (index >= _previousDocuments.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: _isLoadingMoreDocs
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: CreateRequestColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Scroll for more...',
                                        style: TextStyle(
                                          color: CreateRequestColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            );
                          }

                          final doc = _previousDocuments[index];
                          final isSelected = _selectedPreviousDocuments.any((d) => d['id'] == doc['id']);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: CreateRequestColors.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.description_rounded,
                                color: CreateRequestColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              doc['title'] ?? 'Untitled',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? CreateRequestColors.primary : CreateRequestColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: CreateRequestColors.accentRed, size: 22),
                                  onPressed: () {
                                    // تأكيد الحذف
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.translate('delete_file') ?? 'Delete File'),
                                        content: Text(AppLocalizations.of(context)!.translate('delete_file_confirm')?.replaceFirst('{fileName}', doc['title'] ?? '') ?? 'Are you sure you want to delete this file?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(AppLocalizations.of(context)!.translate('cancel') ?? 'Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteDocument(doc, setStateSheet: setStateSheet);
                                            },
                                            child: Text(AppLocalizations.of(context)!.translate('delete') ?? 'Delete', style: TextStyle(color: CreateRequestColors.accentRed)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                isSelected
                                    ? Icon(
                                  Icons.check_circle_rounded,
                                  color: CreateRequestColors.accentGreen,
                                )
                                    : Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: CreateRequestColors.primary,
                                ),
                              ],
                            ),
                            onTap: () {
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

                    SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [CreateRequestColors.primaryGradientStart, CreateRequestColors.primaryGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CreateRequestColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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


  // ✅ ربط ملف بالعملية يدوياً (مثل editerequest.dart)
  Future<void> _linkDocumentToTransaction(int transactionId, int documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$_documentApiUrl/transactions/$transactionId/document/$documentId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Document $documentId linked successfully to transaction $transactionId');
      } else {
        debugPrint('❌ Link failed ($documentId): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error linking document: $e');
    }
  }

  // ✅ تحديث: استخدام receiverId بدلاً من receiverName
  Future<void> _forwardTransaction(int transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      // حل receiverId من الاسم
      int? receiverId;
      final user = _usersData.firstWhere(
        (u) => u['name'] == _selectedReceiver,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        receiverId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
      }

      if (receiverId == null) {
        debugPrint("❌ Could not resolve receiverId for: $_selectedReceiver");
        return;
      }

      final response = await http.post(
        Uri.parse('$_documentApiUrl/transaction/$transactionId/forward'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "receiverId": receiverId,
          "comment": _commentController.text.trim().isEmpty
              ? "Request forwarded"
              : _commentController.text.trim(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint("❌ Forward failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error forwarding transaction: $e");
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        if (_selectedFiles.isNotEmpty) {
          await _uploadNewFiles();
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';

        final transactionData = {
          "title": _titleController.text,
          "description": _descriptionController.text,
          "typeName": _selectedRequestType,
          "priority": _selectedPriority.toUpperCase(),
          "documentsIds": _uploadedDocumentIds.isNotEmpty ? _uploadedDocumentIds : [],
        };

        final response = await http.post(
          Uri.parse('$_documentApiUrl/transactions'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(transactionData),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          final transactionId = data["id"];

          if (transactionId != null) {
            // ✅ ربط الملفات يدوياً بالعملية (لضمان ظهورها مثل editerequest.dart)
            if (_uploadedDocumentIds.isNotEmpty) {
              for (var docId in _uploadedDocumentIds) {
                await _linkDocumentToTransaction(transactionId, docId);
              }
            }

            await _forwardTransaction(transactionId);
          }

          _showSuccessMessage('request_sent_success');
          Navigator.pop(context);
        } else {
          _handleApiError(response, 'failed_create_request');
        }
      } catch (e) {
         _showErrorMessage(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      if (_titleController.text.trim().isEmpty && _titleKey.currentContext != null) {
        Scrollable.ensureVisible(_titleKey.currentContext!, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (_selectedRequestType == 'Request Type' && _typeKey.currentContext != null) {
        Scrollable.ensureVisible(_typeKey.currentContext!, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (_descriptionController.text.trim().isEmpty && _descriptionKey.currentContext != null) {
        Scrollable.ensureVisible(_descriptionKey.currentContext!, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CreateRequestColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.list_alt_rounded,
                            color: CreateRequestColors.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Select Request Type',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CreateRequestColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: CreateRequestColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(color: CreateRequestColors.borderColor),
                    SizedBox(height: 12),
                    Expanded(
                      child: _isLoadingTypes
                          ? Center(child: CircularProgressIndicator(color: CreateRequestColors.primary))
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
                                padding: EdgeInsets.zero,
                                itemCount: _requestTypesData.length + (_typesHasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _requestTypesData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: _isLoadingMoreTypes
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: CreateRequestColors.primary,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Scroll for more...',
                                                style: TextStyle(
                                                  color: CreateRequestColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final type = _requestTypesData[index];
                                  final isSelected = type.name == _selectedRequestType;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? CreateRequestColors.primary.withOpacity(0.05) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? CreateRequestColors.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? CreateRequestColors.primary.withOpacity(0.2)
                                            : CreateRequestColors.bodyBg.withOpacity(0.8),
                                        child: Icon(
                                          Icons.description_outlined,
                                          color: isSelected
                                              ? CreateRequestColors.primary
                                              : CreateRequestColors.textSecondary,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        type.name,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? CreateRequestColors.primary
                                              : CreateRequestColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: (type.creatorName != 'System' && type.creatorName != '')
                                          ? Text(
                                              'Created by: ${type.creatorName}',
                                              style: TextStyle(fontSize: 11, color: CreateRequestColors.textSecondary),
                                            )
                                          : null,
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: CreateRequestColors.primary,
                                              size: 20,
                                            )
                                          : Icon(
                                              Icons.chevron_right_rounded,
                                              color: CreateRequestColors.textMuted,
                                              size: 20,
                                            ),
                                      onTap: () {
                                        setState(() {
                                          _selectedRequestType = type.name;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
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

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CreateRequestColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            color: CreateRequestColors.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Select User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CreateRequestColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: CreateRequestColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _userSearchController,
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search_rounded, color: CreateRequestColors.primary, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) {
                        _userSearchTimer?.cancel();
                        _userSearchTimer = Timer(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            fetchUsers(name: value).then((_) {
                              if (mounted) setStateDialog(() {});
                            });
                          }
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: _isLoadingUsers
                          ? Center(child: CircularProgressIndicator(color: CreateRequestColors.primary))
                          : NotificationListener<ScrollNotification>(
                              onNotification: (scrollInfo) {
                                if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 &&
                                    !_isLoadingMoreUsers && _usersHasMore) {
                                  _loadMoreUsers(
                                    setStateDialog: setStateDialog,
                                    name: _userSearchController.text
                                  );
                                }
                                return false;
                              },
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _filteredUsersData.length + 1 + (_usersHasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: CreateRequestColors.bodyBg.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: CreateRequestColors.borderColor),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.clear_all_rounded,
                                          color: CreateRequestColors.textSecondary,
                                          size: 20,
                                        ),
                                        title: Text(
                                          'Clear Selection',
                                          style: TextStyle(
                                            color: CreateRequestColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() => _selectedReceiver = 'Select User');
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  }

                                  if (index > _filteredUsersData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: _isLoadingMoreUsers
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: CreateRequestColors.primary,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Scroll for more...',
                                                style: TextStyle(
                                                  color: CreateRequestColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final user = _filteredUsersData[index - 1];
                                  final isSelected = user['name'] == _selectedReceiver;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? CreateRequestColors.primary.withOpacity(0.05) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? CreateRequestColors.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? CreateRequestColors.primary.withOpacity(0.2)
                                            : CreateRequestColors.bodyBg.withOpacity(0.8),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: isSelected
                                              ? CreateRequestColors.primary
                                              : CreateRequestColors.textSecondary,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        user['name'],
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? CreateRequestColors.primary
                                              : CreateRequestColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${user['id']}',
                                        style: TextStyle(fontSize: 11, color: CreateRequestColors.textSecondary),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                        Icons.check_circle_rounded,
                                        color: CreateRequestColors.primary,
                                        size: 20,
                                      )
                                          : Icon(
                                        Icons.chevron_right_rounded,
                                        color: CreateRequestColors.textMuted,
                                        size: 20,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedReceiver = user['name'];
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
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

  Widget _buildSectionHeader(String title, IconData icon) => Row(
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CreateRequestColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CreateRequestColors.primary, size: 20),
      ),
      SizedBox(width: 12),
      Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CreateRequestColors.primary),
      ),
    ],
  );

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: CreateRequestColors.textPrimary,
    ),
  );

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CreateRequestColors.primaryGradientStart, CreateRequestColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CreateRequestColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_document, color: Colors.white, size: isMobile ? 24 : 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.translate('create_new_request'),
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.translate('create_request_subtitle'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 14 : 18,
                ),
                side: BorderSide(color: CreateRequestColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: CreateRequestColors.primary,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel'),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CreateRequestColors.primaryGradientStart, CreateRequestColors.primaryGradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CreateRequestColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  _selectedReceiver == 'Select User'
                      ? AppLocalizations.of(context)!.translate('create_request')
                      : AppLocalizations.of(context)!.translate('send_request_button'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('create_new_request'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: min(width * 0.045, 22),
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [CreateRequestColors.primaryGradientStart, CreateRequestColors.primaryGradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: CreateRequestColors.bodyBg,
      body: _buildResponsiveBody(isMobile, isTablet, isDesktop, height),
    );
  }

  Widget _buildResponsiveBody(bool isMobile, bool isTablet, bool isDesktop, double height) {
    Widget content = SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? 16.0 : isTablet ? 24.0 : 32.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            SizedBox(height: isMobile ? 16 : 24),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CreateRequestColors.borderColor),
              ),
              color: CreateRequestColors.cardBg,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.translate('basic_information'), Icons.info_outline_rounded),
                    SizedBox(height: isMobile ? 12 : 16),

                    _buildLabel('${AppLocalizations.of(context)!.translate('request_title')} *'),
                    SizedBox(height: 8),
                    TextFormField(
                      key: _titleKey,
                      controller: _titleController,
                      style: TextStyle(fontSize: 15, color: CreateRequestColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                        hintText: AppLocalizations.of(context)!.translate('request_title_hint'),
                        hintStyle: TextStyle(color: CreateRequestColors.textMuted, fontSize: 14),
                        prefixIcon: Icon(Icons.title_rounded, color: CreateRequestColors.primary, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? AppLocalizations.of(context)!.translate('request_title_error')
                          : null,
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('${AppLocalizations.of(context)!.translate('request_type_label')} *'),
                        IconButton(
                          icon: Icon(Icons.settings_suggest_rounded, color: CreateRequestColors.primary, size: 22),
                          onPressed: _showManageTypesDialog,
                          style: IconButton.styleFrom(
                            backgroundColor: CreateRequestColors.primary.withOpacity(0.1),
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    FormField<String>(
                      key: _typeKey,
                      initialValue: _selectedRequestType,
                      validator: (v) => _selectedRequestType == 'Request Type'
                          ? AppLocalizations.of(context)!.translate('request_type_hint')
                          : null,
                      builder: (state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _showTypeSelectionDialog(),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                                  prefixIcon: Icon(Icons.category_rounded, color: CreateRequestColors.primary, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.focusBorderColor, width: 1.5),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                          fontWeight: _selectedRequestType == 'Request Type' ? FontWeight.normal : FontWeight.w600,
                                          fontSize: 15,
                                          color: _selectedRequestType == 'Request Type'
                                              ? CreateRequestColors.textMuted
                                              : CreateRequestColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded, color: CreateRequestColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 12),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(color: CreateRequestColors.accentRed, fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    _buildLabel(AppLocalizations.of(context)!.translate('priority_label')),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      style: TextStyle(fontSize: 15, color: CreateRequestColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                        prefixIcon: Icon(Icons.priority_high_rounded, color: CreateRequestColors.primary, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: CreateRequestColors.textSecondary),
                      items: ['Low', 'Medium', 'High']
                          .map((v) {
                        String label = v;
                        if (v == 'Low') label = AppLocalizations.of(context)!.translate('priority_low');
                        if (v == 'Medium') label = AppLocalizations.of(context)!.translate('priority_medium');
                        if (v == 'High') label = AppLocalizations.of(context)!.translate('priority_high');
                        return DropdownMenuItem(value: v, child: Text(label));
                      })
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    _buildLabel('${AppLocalizations.of(context)!.translate('description_label')} *'),
                    SizedBox(height: 8),
                    TextFormField(
                      key: _descriptionKey,
                      controller: _descriptionController,
                      maxLines: 4,
                      style: TextStyle(fontSize: 15, color: CreateRequestColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                        hintText: AppLocalizations.of(context)!.translate('description_hint'),
                        hintStyle: TextStyle(color: CreateRequestColors.textMuted, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? AppLocalizations.of(context)!.translate('description_error')
                          : null,
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    _buildLabel(AppLocalizations.of(context)!.translate('comment_label')),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15, color: CreateRequestColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CreateRequestColors.bodyBg.withOpacity(0.5),
                        hintText: AppLocalizations.of(context)!.translate('comment_hint'),
                        hintStyle: TextStyle(color: CreateRequestColors.textMuted, fontSize: 14),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.comment_outlined, color: CreateRequestColors.primary, size: 20),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            SizedBox(height: isMobile ? 16 : 24),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CreateRequestColors.borderColor),
              ),
              color: CreateRequestColors.cardBg,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.translate('send_request_section'), Icons.send_rounded),
                    SizedBox(height: isMobile ? 12 : 16),

                    _buildLabel('${AppLocalizations.of(context)!.translate('send_to_user_label')} ${AppLocalizations.of(context)!.locale.languageCode == 'ar' ? '(اختياري)' : '(Optional)'}'),
                    SizedBox(height: 8),

                    _isLoadingUsers
                        ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: CreateRequestColors.bodyBg.withOpacity(0.5),
                        border: Border.all(color: CreateRequestColors.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CreateRequestColors.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Loading users...',
                            style: TextStyle(color: CreateRequestColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                        : InkWell(
                      onTap: _showUserSelectionDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedReceiver == 'Select User'
                              ? CreateRequestColors.bodyBg.withOpacity(0.5)
                              : CreateRequestColors.primary.withOpacity(0.05),
                          border: Border.all(
                            color: _selectedReceiver == 'Select User'
                                ? CreateRequestColors.borderColor
                                : CreateRequestColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedReceiver == 'Select User' ? Icons.person_outline_rounded : Icons.person_rounded,
                                    color: _selectedReceiver == 'Select User' ? CreateRequestColors.textMuted : CreateRequestColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedReceiver == 'Select User'
                                          ? AppLocalizations.of(context)!.translate('select_user_hint')
                                          : _selectedReceiver,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: _selectedReceiver == 'Select User' ? FontWeight.normal : FontWeight.w600,
                                        color: _selectedReceiver == 'Select User'
                                            ? CreateRequestColors.textMuted
                                            : CreateRequestColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: CreateRequestColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            SizedBox(height: isMobile ? 16 : 24),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CreateRequestColors.borderColor),
              ),
              color: CreateRequestColors.cardBg,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AppLocalizations.of(context)!.translate('supporting_documents'), Icons.attach_file_rounded),
                    SizedBox(height: isMobile ? 16 : 20),

                    Center(
                      child: InkWell(
                        onTap: _showFileSelectionMenu,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 24 : 32),
                          decoration: BoxDecoration(
                            color: CreateRequestColors.bodyBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CreateRequestColors.borderColor,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: CreateRequestColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.cloud_upload_outlined,
                                  size: isMobile ? 32 : 40,
                                  color: CreateRequestColors.primary,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                _selectedFiles.isEmpty && _selectedPreviousDocuments.isEmpty
                                    ? 'Click to select files'
                                    : '${_selectedFiles.length + _selectedPreviousDocuments.length} file(s) selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CreateRequestColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Support PDF documents',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CreateRequestColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: CreateRequestColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Choose Files',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_selectedFiles.isNotEmpty || _selectedPreviousDocuments.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Text(
                        'Selected Files:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: CreateRequestColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Column(
                        children: [
                          ..._selectedPreviousDocuments.map((doc) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CreateRequestColors.bodyBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: CreateRequestColors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: CreateRequestColors.accentRed, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc['title'] ?? 'Untitled',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: CreateRequestColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Previously uploaded',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: CreateRequestColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: CreateRequestColors.textMuted, size: 20),
                                    onPressed: () => _removePreviousDocument(doc),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ..._selectedFiles.map((file) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CreateRequestColors.bodyBg.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: CreateRequestColors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: CreateRequestColors.accentRed, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: CreateRequestColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'New file to upload',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: CreateRequestColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: CreateRequestColors.textMuted, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFiles.removeWhere((f) => f.name == file.name);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            _buildActionButtons(isMobile),
            SizedBox(height: isMobile ? 16 : 24),
          ],
        ),
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
}