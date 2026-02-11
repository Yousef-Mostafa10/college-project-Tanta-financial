import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final _commentController = TextEditingController(); // ✅ إضافة حقل الكومنت
  final _userSearchController = TextEditingController();

  String _selectedRequestType = 'Request Type';
  String _selectedPriority = 'Medium';
  String _selectedReceiver = 'Select User';

  List<TransactionType> _requestTypesData = [];
  List<String> _requestTypes = ['Request Type'];
  List<String> _availableUsers = ['Select User'];
  List<String> _filteredUsers = ['Select User'];

  // ✅ تحميل البيانات بشكل منفصل
  bool _isLoadingTypes = true;
  bool _isLoadingUsers = true;
  bool _isSubmitting = false;

  List<int> _uploadedDocumentIds = [];
  List<PlatformFile> _selectedFiles = [];

  final String _documentApiUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchRequestTypes();
    fetchUsers();

    _requestTypes = ['Request Type'];
    _availableUsers = ['Select User'];
    _filteredUsers = ['Select User'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose(); // ✅ dispose الكومنت
    _userSearchController.dispose();
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

  // ✅ جلب أنواع الطلبات
  Future<void> fetchRequestTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> typesList = [];
          if (data is List) {
            typesList = data;
          } else if (data is Map && data["transactionTypes"] != null) {
            typesList = data["transactionTypes"];
          }

          final List<TransactionType> types = [];
          for (var item in typesList) {
            types.add(TransactionType.fromJson(item));
          }

          setState(() {
            _requestTypesData = types;
            _requestTypes = ['Request Type', ...types.map((t) => t.name)];
            if (_selectedRequestType == 'Request Type' && _requestTypes.length > 1) {
              _selectedRequestType = _requestTypes[1];
            }
            _isLoadingTypes = false;
          });
        } else {
          _loadFallbackTypes();
        }
      }
    } catch (e) {
      if (mounted) _loadFallbackTypes();
      print('Error fetching types: $e');
    }
  }

  // ✅ جلب المستخدمين
  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_documentApiUrl/users'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            final List<String> users = [];
            for (var user in data) {
              if (user["name"] != null) users.add(user["name"]);
            }
            setState(() {
              _availableUsers = ['Select User', ...users];
              _filteredUsers = List.from(_availableUsers);
              _selectedReceiver = _availableUsers.first;
              _isLoadingUsers = false;
            });
          } else {
            _loadFallbackUsers();
          }
        } else {
          _loadFallbackUsers();
        }
      }
    } catch (e) {
      if (mounted) _loadFallbackUsers();
      print('Error fetching users: $e');
    }
  }

  void _loadFallbackTypes() {
    setState(() {
      _requestTypes = [
        'Request Type',
        'Purchase Request',
        'Leave Request',
        'Training Request',
        'Equipment Request'
      ];
      _selectedRequestType = _requestTypes[1];
      _isLoadingTypes = false;
    });
  }

  void _loadFallbackUsers() {
    setState(() {
      _availableUsers = ['Select User', 'John Doe', 'Jane Smith', 'Admin User'];
      _filteredUsers = List.from(_availableUsers);
      _selectedReceiver = _availableUsers.first;
      _isLoadingUsers = false;
    });
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
        // ✅ تحسين: استخدم الـ Response بدل ما تعمل Refetch
        if (response.body.isNotEmpty) {
          try {
            final newType = json.decode(response.body);
            setState(() {
              _requestTypesData.add(TransactionType.fromJson(newType));
              _requestTypes = ['Request Type', ..._requestTypesData.map((t) => t.name)];
              _selectedRequestType = newType['name'];
            });
          } catch (e) {
            // لو الـ Response مش صالح، اعمل Refetch
            await fetchRequestTypes();
          }
        } else {
          await fetchRequestTypes();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Type created successfully!'), backgroundColor: CreateRequestColors.accentGreen),
          );
        }
      } else {
        _showErrorMessage('Failed to create type: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Type deleted successfully!'), backgroundColor: CreateRequestColors.accentGreen),
          );
        }
      } else {
        _showErrorMessage('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  void _showManageTypesDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Manage Request Types'),
          content: Column(
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ],
        ),
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_availableUsers);
      } else {
        _filteredUsers = _availableUsers
            .where((user) =>
        user.toLowerCase().contains(query.toLowerCase()) &&
            user != 'Select User')
            .toList();
        if (!_filteredUsers.contains('Select User')) {
          _filteredUsers.insert(0, 'Select User');
        }
      }
    });
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

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;
    _uploadedDocumentIds.clear();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    for (var file in _selectedFiles) {
      try {
        final finalFileName = _generateUniqueFileName(file.name);
        if (file.path == null) {
          _showErrorMessage("Could not get file path for ${file.name}");
          continue;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_documentApiUrl/documents'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.headers['accept'] = 'application/json';

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: finalFileName,
        ));

        debugPrint('📤 Uploading: $finalFileName');
        var response = await request.send();
        debugPrint('📊 Upload Status: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          debugPrint('✅ Upload Response: $responseData');
          final documentData = json.decode(responseData);

          if (documentData["id"] != null) {
            final dynamic rawId = documentData["id"];
            final int documentId = rawId is int ? rawId : int.parse(rawId.toString());
            _uploadedDocumentIds.add(documentId);
            debugPrint('📎 Document ID added: $documentId');

            // ✅ تخزين downloadURI للاستخدام المستقبلي
            if (documentData["downloadURI"] != null) {
              // ممكن تخزينه لو هتحتاجه بعدين
              debugPrint('📥 Download URI: ${documentData["downloadURI"]}');
            }
          }
          _showSuccessMessage(AppLocalizations.of(context)!.translate('file_uploaded_success').replaceFirst('{fileName}', file.name));
        } else {
          final responseData = await response.stream.bytesToString();
          debugPrint('❌ Upload Error: $responseData');
          _showErrorMessage('Upload failed with status ${response.statusCode}');
        }
      } catch (e) {
        _showErrorMessage('${AppLocalizations.of(context)!.translate('error_uploading_file').replaceFirst('{fileName}', file.name)}: $e');
      }
    }
  }

  // ✅ تعديل الـ Forward عشان يستخدم comment بدل senderComment
  Future<void> _forwardTransaction(int transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$_documentApiUrl/transaction/$transactionId/forward'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "receiverName": _selectedReceiver,
          "comment": _commentController.text.trim().isEmpty  // ✅ استخدام comment
              ? "Request forwarded from ${AppLocalizations.of(context)!.translate('app_name')}"
              : _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Forward successful: ${data["id"]}');
        _showSuccessMessage(AppLocalizations.of(context)!
            .translate('request_sent_to')
            .replaceFirst('{user}', _selectedReceiver));
      } else {
        _showErrorMessage('Failed to forward request: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      _showErrorMessage('Failed to forward request: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        if (_selectedFiles.isNotEmpty) {
          await _uploadFiles();
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';

        final transactionData = {
          "title": _titleController.text,
          "description": _descriptionController.text,
          "typeName": _selectedRequestType,
          "priority": _selectedPriority.toUpperCase(),
          "documentsIds": _uploadedDocumentIds.isNotEmpty
              ? _uploadedDocumentIds
              : [],
        };

        debugPrint('🚀 Creating transaction: $transactionData');

        final response = await http.post(
          Uri.parse('$_documentApiUrl/transactions'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(transactionData),
        );

        debugPrint('📊 Create Status: ${response.statusCode}');
        debugPrint('📄 Create Response: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          final transactionId = data["id"];

          if (transactionId != null) {
            await _forwardTransaction(transactionId);
          }

          _showSuccessMessage(AppLocalizations.of(context)!.translate('request_sent_success'));
          Navigator.pop(context);
        } else {
          _showErrorMessage('Failed to create transaction: ${response.statusCode}\n${response.body}');
        }
      } catch (e) {
        _showErrorMessage('${AppLocalizations.of(context)!.translate('error_label')}: $e');
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFiles = result.files);
        _showSuccessMessage(AppLocalizations.of(context)!.translate('selected_files_count').replaceFirst('{count}', '${_selectedFiles.length}'));
      }
    } catch (e) {
      _showErrorMessage('Error picking files: $e');
    }
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
    final content = SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? 16.0 :
        isTablet ? 24.0 :
        32.0,
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
                  tooltip: 'Manage Request Types',
                ),
              ],
            ),
            SizedBox(height: 8),

            _isLoadingTypes
                ? Container(
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: CreateRequestColors.borderColor),
                borderRadius: BorderRadius.circular(4),
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
                    'Loading request types...',
                    style: TextStyle(color: CreateRequestColors.textMuted),
                  ),
                ],
              ),
            )
                : DropdownButtonFormField<String>(
              isExpanded: true,
              itemHeight: 75,
              value: _selectedRequestType,
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
                  horizontal: 18,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              selectedItemBuilder: (BuildContext context) {
                return _requestTypes.map<Widget>((String item) {
                  return Text(
                    item == 'Request Type'
                        ? AppLocalizations.of(context)!.translate('request_type_hint')
                        : item,
                    style: TextStyle(
                      fontWeight: item == 'Request Type' ? FontWeight.normal : FontWeight.w600,
                      color: item == 'Request Type'
                          ? CreateRequestColors.textMuted
                          : CreateRequestColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: _requestTypes.map((v) {
                final typeData = _requestTypesData.firstWhere(
                      (t) => t.name == v,
                  orElse: () => TransactionType(name: v, creatorName: ''),
                );

                return DropdownMenuItem(
                  value: v,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v == 'Request Type' ? AppLocalizations.of(context)!.translate('request_type_hint') : v,
                        style: TextStyle(
                          fontWeight: v == 'Request Type' ? FontWeight.normal : FontWeight.w600,
                          color: v == 'Request Type' ? CreateRequestColors.textMuted : CreateRequestColors.textPrimary,
                        ),
                      ),
                      if (v != 'Request Type' && typeData.creatorName != 'System' && typeData.creatorName != '')
                        Text(
                          'Created by: ${typeData.creatorName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: CreateRequestColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRequestType = v!),
              validator: (v) => v == 'Request Type'
                  ? AppLocalizations.of(context)!.translate('request_type_hint')
                  : null,
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

            // ✅ حقل الكومنت الجديد - تحت الوصف مباشرة
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

            _buildLabel('${AppLocalizations.of(context)!.translate('send_to_user_label')} *'),
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
                        _selectedReceiver == 'Select User' ? AppLocalizations.of(context)!.translate('select_user_hint') : _selectedReceiver,
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
            if (_selectedReceiver != 'Select User' && !_isLoadingUsers) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CreateRequestColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: CreateRequestColors.primary),
                    SizedBox(width: 6),
                    Text(
                      '${AppLocalizations.of(context)!.translate('selected_user')} $_selectedReceiver',
                      style: TextStyle(
                        fontSize: 12,
                        color: CreateRequestColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedReceiver = 'Select User');
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: CreateRequestColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      _selectedFiles.isEmpty
                          ? AppLocalizations.of(context)!.translate('add_documents_hint')
                          : AppLocalizations.of(context)!.translate('selected_files_count').replaceFirst('{count}', '${_selectedFiles.length}'),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: CreateRequestColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 8 : 16),
                    ElevatedButton(
                      onPressed: _pickFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CreateRequestColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('choose_files'),
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

            if (_selectedFiles.isNotEmpty) ...[
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                AppLocalizations.of(context)!.translate('selected_files_label'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: CreateRequestColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: _selectedFiles.map((file) {
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
                          child: Text(
                            file.name,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: CreateRequestColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                            _showSuccessMessage(AppLocalizations.of(context)!.translate('files_removed').replaceFirst('{fileName}', file.name));
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
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

  void _showUserSelectionDialog() {
    if (_isLoadingUsers) {
      _showErrorMessage('Loading users, please wait...');
      return;
    }

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

                    TextField(
                      controller: _userSearchController,
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
                          _filterUsers(value);
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    Text(
                      '${_filteredUsers.length - 1} ${AppLocalizations.of(context)!.translate('users_count_label')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CreateRequestColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = user == _selectedReceiver;
                          final isSelectUserOption = user == 'Select User';

                          if (isSelectUserOption) {
                            return ListTile(
                              leading: Icon(
                                Icons.clear_all_rounded,
                                color: CreateRequestColors.textMuted,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.translate('select_user_hint'),
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
                              setState(() => _selectedReceiver = user);
                              Navigator.pop(context);
                              _userSearchController.clear();
                              _filterUsers('');
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _userSearchController.clear();
                              _filterUsers('');
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
                            onPressed: () {
                              Navigator.pop(context);
                              _userSearchController.clear();
                              _filterUsers('');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CreateRequestColors.primary,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('select_button'),
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
  }

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
            AppLocalizations.of(context)!.translate('send_request_button'),
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }
}