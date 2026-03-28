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

// 🎨 COLOR PALETTE - Consistent with Dashboard and Inbox
class CreateRequestColors {
  // Primary Colors (same as AppColors)
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

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor = Color(0xFF00695C);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Type created successfully!'), backgroundColor: CreateRequestColors.accentGreen),
          );
        }
      }
    } catch (e) {}
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Type deleted successfully!'), backgroundColor: CreateRequestColors.accentGreen),
          );
        }
      }
    } catch (e) {}
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
                  height: 200,
                  width: double.maxFinite,
                  child: _isLoadingTypes
                      ? Center(child: CircularProgressIndicator(color: CreateRequestColors.primary))
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _requestTypesData.length,
                    itemBuilder: (context, index) {
                      final type = _requestTypesData[index];
                      return ListTile(
                        title: Text(type.name),
                        subtitle: Text('By: ${type.creatorName}', style: TextStyle(fontSize: 10)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: CreateRequestColors.accentRed, size: 20),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CreateRequestColors.accentRed,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CreateRequestColors.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
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
                        'Select Files',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CreateRequestColors.primary,
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
                        color: CreateRequestColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.cloud_upload_rounded, color: CreateRequestColors.accentBlue),
                    ),
                    title: Text(
                      'Upload New Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CreateRequestColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Select PDF files from your device',
                      style: TextStyle(
                        fontSize: 12,
                        color: CreateRequestColors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: CreateRequestColors.textMuted,
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

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 20, color: CreateRequestColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Previously Uploaded Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                            trailing: isSelected
                                ? Icon(
                              Icons.check_circle_rounded,
                              color: CreateRequestColors.accentGreen,
                            )
                                : Icon(
                              Icons.add_circle_outline_rounded,
                              color: CreateRequestColors.primary,
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

                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CreateRequestColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Files:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CreateRequestColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_selectedPreviousDocuments.length + _selectedFiles.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CreateRequestColors.primary,
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
                        backgroundColor: CreateRequestColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Done',
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

          _showSuccessMessage('Request sent successfully');
          Navigator.pop(context);
        }
      } catch (e) {} finally {
        setState(() => _isSubmitting = false);
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
                          color: CreateRequestColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Select Request Type',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CreateRequestColors.primary,
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
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? CreateRequestColors.primary.withOpacity(0.2)
                                          : CreateRequestColors.primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: isSelected
                                            ? CreateRequestColors.primary
                                            : CreateRequestColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? CreateRequestColors.primary
                                            : CreateRequestColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: (type.creatorName != 'System' && type.creatorName != '')
                                        ? Text(
                                            'Created by: ${type.creatorName}',
                                            style: TextStyle(fontSize: 11, color: CreateRequestColors.textMuted),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: CreateRequestColors.primary,
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

  void _showUserSelectionDialog() {
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
                          Icons.person_search_rounded,
                          color: CreateRequestColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Select User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CreateRequestColors.primary,
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
                    TextField(
                      controller: _userSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search_rounded, color: CreateRequestColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    SizedBox(height: 16),
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
                                itemCount: _filteredUsersData.length + 1 + (_usersHasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.clear_all_rounded,
                                        color: CreateRequestColors.textMuted,
                                      ),
                                      title: Text(
                                        'Clear Selection',
                                        style: TextStyle(
                                          color: CreateRequestColors.textMuted,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() => _selectedReceiver = 'Select User');
                                        Navigator.pop(context);
                                      },
                                    );
                                  }

                                  if (index > _filteredUsersData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
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
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? CreateRequestColors.primary.withOpacity(0.2)
                                          : CreateRequestColors.primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: isSelected
                                            ? CreateRequestColors.primary
                                            : CreateRequestColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      user['name'],
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? CreateRequestColors.primary
                                            : CreateRequestColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${user['id']}',
                                      style: TextStyle(fontSize: 11, color: CreateRequestColors.textMuted),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                      Icons.check_circle_rounded,
                                      color: CreateRequestColors.primary,
                                    )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedReceiver = user['name'];
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

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: CreateRequestColors.primary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('create_new_request'),
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: CreateRequestColors.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.translate('create_request_subtitle'),
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: CreateRequestColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            side: BorderSide(color: CreateRequestColors.primary),
            foregroundColor: CreateRequestColors.primary,
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('cancel'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: CreateRequestColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 24,
              vertical: isMobile ? 12 : 16,
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
            width: isMobile ? 20 : 24,
            height: isMobile ? 20 : 24,
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
            ),
          ),
        ),
      ],
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('create_new_request'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: min(width * 0.04, 20),
            color: Colors.white,
          ),
        ),
        backgroundColor: CreateRequestColors.primary,
        foregroundColor: Colors.white,
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

            _buildSectionHeader(AppLocalizations.of(context)!.translate('basic_information')),
            SizedBox(height: isMobile ? 12 : 16),

            _buildLabel('${AppLocalizations.of(context)!.translate('request_title')} *'),
            SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('request_title_hint'),
                hintStyle: TextStyle(color: CreateRequestColors.textMuted),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? AppLocalizations.of(context)!.translate('request_title_error')
                  : null,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('${AppLocalizations.of(context)!.translate('request_type_label')} *'),
                IconButton(
                  icon: Icon(Icons.settings, color: CreateRequestColors.primary, size: 20),
                  onPressed: _showManageTypesDialog,
                ),
              ],
            ),
            SizedBox(height: 8),

            FormField<String>(
              initialValue: _selectedRequestType,
              validator: (v) => _selectedRequestType == 'Request Type'
                  ? AppLocalizations.of(context)!.translate('request_type_hint')
                  : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        _showTypeSelectionDialog();
                        // We need a way to trigger validation after selection
                        // This is handled by the fact that the dialog sets state and we can manually call validate or just check during submit.
                        // Actually, the simplest is to update the form field state.
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: state.hasError ? CreateRequestColors.accentRed : CreateRequestColors.focusBorderColor, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: isMobile ? 12 : 16,
                          ),
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
                                  color: _selectedRequestType == 'Request Type'
                                      ? CreateRequestColors.textMuted
                                      : CreateRequestColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: CreateRequestColors.textSecondary),
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
            SizedBox(height: isMobile ? 12 : 16),

            _buildLabel(AppLocalizations.of(context)!.translate('priority_label')),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
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
            SizedBox(height: isMobile ? 12 : 16),

            _buildLabel('${AppLocalizations.of(context)!.translate('description_label')} *'),
            SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('description_hint'),
                hintStyle: TextStyle(color: CreateRequestColors.textMuted),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
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
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('comment_hint'),
                hintStyle: TextStyle(color: CreateRequestColors.textMuted),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: CreateRequestColors.focusBorderColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            _buildSectionHeader(AppLocalizations.of(context)!.translate('send_request_section')),
            SizedBox(height: isMobile ? 12 : 16),

            _buildLabel('${AppLocalizations.of(context)!.translate('send_to_user_label')} ${AppLocalizations.of(context)!.locale.languageCode == 'ar' ? '(اختياري)' : '(Optional)'}'),
            SizedBox(height: 8),

            _isLoadingUsers
                ? Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: CreateRequestColors.borderColor),
                borderRadius: BorderRadius.circular(4),
                color: CreateRequestColors.cardBg,
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
                    style: TextStyle(color: CreateRequestColors.textMuted),
                  ),
                ],
              ),
            )
                : InkWell(
              onTap: _showUserSelectionDialog,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedReceiver == 'Select User'
                        ? CreateRequestColors.borderColor
                        : CreateRequestColors.primary,
                    width: _selectedReceiver == 'Select User' ? 1 : 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: CreateRequestColors.cardBg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedReceiver == 'Select User'
                            ? AppLocalizations.of(context)!.translate('select_user_hint')
                            : _selectedReceiver,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: _selectedReceiver == 'Select User'
                              ? CreateRequestColors.textMuted
                              : CreateRequestColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: CreateRequestColors.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            _buildSectionHeader(AppLocalizations.of(context)!.translate('supporting_documents')),
            SizedBox(height: isMobile ? 12 : 16),

            Center(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  border: Border.all(color: CreateRequestColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: CreateRequestColors.cardBg,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: isMobile ? 40 : 48,
                      color: CreateRequestColors.textSecondary,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      _selectedFiles.isEmpty && _selectedPreviousDocuments.isEmpty
                          ? 'Click to select files or choose from previously uploaded'
                          : '${_selectedFiles.length + _selectedPreviousDocuments.length} file(s) selected',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: CreateRequestColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 8 : 16),
                    ElevatedButton(
                      onPressed: _showFileSelectionMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CreateRequestColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      child: Text(
                        'Choose Files',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedFiles.isNotEmpty || _selectedPreviousDocuments.isNotEmpty) ...[
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Selected Files:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: CreateRequestColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: [
                  ..._selectedPreviousDocuments.map((doc) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CreateRequestColors.borderColor),
                        borderRadius: BorderRadius.circular(6),
                        color: CreateRequestColors.cardBg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: CreateRequestColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Previously uploaded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CreateRequestColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: CreateRequestColors.accentRed,
                              size: isMobile ? 18 : 24,
                            ),
                            onPressed: () {
                              _removePreviousDocument(doc);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ..._selectedFiles.map((file) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CreateRequestColors.borderColor),
                        borderRadius: BorderRadius.circular(6),
                        color: CreateRequestColors.cardBg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: CreateRequestColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'New file',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CreateRequestColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: CreateRequestColors.accentRed,
                              size: isMobile ? 18 : 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedFiles.remove(file);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],

            SizedBox(height: isMobile ? 24 : 32),

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