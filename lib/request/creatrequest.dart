import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:college_project/l10n/app_localizations.dart';

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
  final _userSearchController = TextEditingController();

  String _selectedRequestType = 'Request Type';
  String _selectedPriority = 'Medium';
  String _selectedReceiver = 'Select User';

  List<String> _requestTypes = ['Request Type'];
  List<String> _availableUsers = ['Select User'];
  List<String> _filteredUsers = ['Select User'];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _areRequestTypesLoaded = false;
  bool _areUsersLoaded = false;

  List<String> _uploadedDocuments = [];
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([fetchRequestTypes(), fetchUsers()]);
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

  Future<void> fetchRequestTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://77.83.242.94:3000/transactions/types'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final List<String> types = [];
          for (var type in data["transactionTypes"]) {
            if (type["name"] != null) types.add(type["name"]);
          }

          setState(() {
            _requestTypes = ['Request Type', ...types];
            _selectedRequestType =
            _requestTypes.length > 1 ? _requestTypes[1] : _requestTypes.first;
            _areRequestTypesLoaded = true;
            _checkLoadingStatus();
          });
        } else {
          _showErrorMessage('API Error: ${data["message"]}');
        }
      } else {
        _showErrorMessage('HTTP Error: ${response.statusCode}');
        _loadFallbackData();
      }
    } catch (e) {
      _showErrorMessage('Connection Error: $e');
      _loadFallbackData();
    }
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://77.83.242.94:3000/users?pageNumber=1&pageSize=100'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final List<String> users = [];
          for (var user in data["users"]) {
            if (user["name"] != null) users.add(user["name"]);
          }

          setState(() {
            _availableUsers = ['Select User', ...users];
            _filteredUsers = List.from(_availableUsers);
            _selectedReceiver = _availableUsers.first;
            _areUsersLoaded = true;
            _checkLoadingStatus();
          });
        } else {
          _showErrorMessage('API Error: ${data["message"]}');
        }
      } else {
        _showErrorMessage('HTTP Error: ${response.statusCode}');
        setState(() {
          _areUsersLoaded = true;
          _checkLoadingStatus();
        });
      }
    } catch (e) {
      _showErrorMessage('Connection Error: $e');
      setState(() {
        _areUsersLoaded = true;
        _checkLoadingStatus();
      });
    }
  }

  void _loadFallbackData() {
    setState(() {
      _requestTypes = [
        'Request Type',
        'Purchase Request',
        'Leave Request',
        'Training Request',
        'Equipment Request'
      ];
      _selectedRequestType = _requestTypes[1];
      _areRequestTypesLoaded = true;
      _checkLoadingStatus();
    });
  }

  void _checkLoadingStatus() {
    if (_areRequestTypesLoaded && _areUsersLoaded) {
      setState(() => _isLoading = false);
    }
  }

  // 🔍 دالة البحث عن المستخدمين
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

        // إضافة Select User في البداية إذا كان البحث فارغاً
        if (!_filteredUsers.contains('Select User')) {
          _filteredUsers.insert(0, 'Select User');
        }
      }
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CreateRequestColors.accentRed,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
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
    _uploadedDocuments.clear(); // Clear previously uploaded docs for this submission
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    for (var file in _selectedFiles) {
      try {
        final finalFileName = _generateUniqueFileName(file.name);
        if (file.path == null) {
          _showErrorMessage("Could not get file path for ${file.name}");
          continue;
        }
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$finalFileName');
        final originalFile = File(file.path!);

        if (await originalFile.exists()) {
          await originalFile.copy(tempFile.path);
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://77.83.242.94:3000/documents'),
        );
        request.files.add(await http.MultipartFile.fromPath('file', tempFile.path,
            filename: finalFileName));
        request.headers['Authorization'] = 'Bearer $token';

        var response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final documentData = json.decode(responseData);
          final documentURI =
          documentData["documentURI"].replaceAll('\\', '/');
          _uploadedDocuments.add(documentURI);
          _showSuccessMessage(AppLocalizations.of(context)!.translate('file_uploaded_success').replaceFirst('{fileName}', file.name));
        } else {
          _showErrorMessage(AppLocalizations.of(context)!.translate('upload_failed_error').replaceFirst('{fileName}', file.name));
        }

        if (await tempFile.exists()) await tempFile.delete();
      } catch (e) {
        _showErrorMessage(AppLocalizations.of(context)!.translate('error_uploading_file').replaceFirst('{fileName}', file.name));
      }
    }
  }

  Future<void> _forwardTransaction(int transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse(
            'http://77.83.242.94:3000/transactions/$transactionId/forwards'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"receiverName": _selectedReceiver}),
      );

      if (response.statusCode == 200) {
        _showSuccessMessage(AppLocalizations.of(context)!.translate('request_sent_to').replaceFirst('{user}', _selectedReceiver));
      } else {
        _showErrorMessage(AppLocalizations.of(context)!.translate('failed_send_request'));
      }
    } catch (e) {
      _showErrorMessage(AppLocalizations.of(context)!.translate('failed_send_request'));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        if (_selectedFiles.isNotEmpty) await _uploadFiles();

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';
        final transactionData = {
          "title": _titleController.text,
          "description": _descriptionController.text,
          "typeName": _selectedRequestType,
          "priority": _selectedPriority.toLowerCase(),
          "documentsURIs": _uploadedDocuments,
        };

        final response = await http.post(
          Uri.parse('http://77.83.242.94:3000/transactions'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(transactionData),
        );

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          final id = data["transaction"]["id"];
          await _forwardTransaction(id);
          _showSuccessMessage(AppLocalizations.of(context)!.translate('request_sent_success'));
          Navigator.pop(context);
        } else {
          _showErrorMessage(AppLocalizations.of(context)!.translate('failed_create_request'));
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
      // Note: FilePicker handles permission internally on many platforms. 
      // Manual storage permission check is often problematic on Android 13+.

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'jpg',
        'png',
        'jpeg'
      ],
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _userSearchController.dispose();
    super.dispose();
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
        color: CreateRequestColors.primary,
      ))
          : _buildResponsiveBody(isMobile, isTablet, isDesktop, height),
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
            // الهيدر
            _buildHeader(isMobile),
            SizedBox(height: isMobile ? 16 : 24),

            // المعلومات الأساسية
            _buildSectionHeader(AppLocalizations.of(context)!.translate('basic_information')),
            SizedBox(height: isMobile ? 12 : 16),

            // العنوان
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

            // نوع الطلب
            _buildLabel('${AppLocalizations.of(context)!.translate('request_type_label')} *'),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
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
                  horizontal: 12,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              items: _requestTypes
                  .map((v) => DropdownMenuItem(
                value: v,
                child: Text(
                  v == 'Request Type' ? AppLocalizations.of(context)!.translate('request_type_hint') : v,
                  style: TextStyle(
                    color: v == 'Request Type'
                        ? CreateRequestColors.textMuted
                        : CreateRequestColors.textPrimary,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRequestType = v!),
              validator: (v) => v == 'Request Type'
                  ? AppLocalizations.of(context)!.translate('request_type_hint')
                  : null,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // الأولوية
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

            // الوصف
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
            SizedBox(height: isMobile ? 24 : 32),

            // إرسال الطلب
            _buildSectionHeader(AppLocalizations.of(context)!.translate('send_request_section')),
            SizedBox(height: isMobile ? 12 : 16),

            // المستخدم المستلم مع البحث
            _buildLabel('${AppLocalizations.of(context)!.translate('send_to_user_label')} *'),
            SizedBox(height: 8),

            // زر اختيار المستخدم مع ديلوج البحث
            InkWell(
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
            if (_selectedReceiver != 'Select User') ...[
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

            // المستندات
            _buildSectionHeader(AppLocalizations.of(context)!.translate('supporting_documents')),
            SizedBox(height: isMobile ? 12 : 16),

            // زر اختيار الملفات
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

            // عرض الملفات المختارة
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

            // أزرار الإرسال والإلغاء
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

  // 🔍 دالة لعرض ديلوج اختيار المستخدم مع البحث
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

                    // عدد النتائج
                    Text(
                      '${_filteredUsers.length - 1} ${AppLocalizations.of(context)!.translate('users_count_label')}',
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

                    // أزرار الإجراء
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