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

  String? _userToken;
  String? _userName;
  String _selectedRequestType = 'Request Type';
  String _selectedPriority = 'Medium';

  List<TransactionType> _requestTypesData = [];
  List<String> _requestTypes = ['Request Type'];

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isUploadingFile = false;

  final String _baseUrl = AppConfig.baseUrl;
  final String _documentApiUrl = AppConfig.baseUrl;

  List<dynamic> _documents = [];
  List<PlatformFile> _newFiles = [];

  // 🔥 متغير لتتبع الملفات المرفوعة حديثاً
  List<String> _recentlyUploadedFiles = [];

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
      _userName = prefs.getString('userName') ?? prefs.getString('username') ?? 'user1';
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _fetchRequestTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$_documentApiUrl/transactions/types'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

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
        });
      } else {
        debugPrint('Error fetching types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching types: $e');
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
        await _fetchRequestTypes(); // Refresh
        _showSuccessSnackBar('Type created successfully!');
      } else {
        _showErrorSnackBar('Failed to create type: ${response.statusCode}');
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
        Uri.parse('$_documentApiUrl/transactions/types/$name'), // Using _documentApiUrl instead of AppConfig.baseUrl
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchRequestTypes();
        _showSuccessSnackBar('Type deleted successfully!');
      } else {
        _showErrorSnackBar('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
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
                      subtitle: Text('By: ${type.creatorName}', style: TextStyle(fontSize: 10)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRequestDetails() async {
    try {
      // استخدام الـ endpoint الصحيح من port 3300
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
          _showErrorSnackBar('No transaction data found');
          return;
        }

        setState(() {
          _titleController.text = data["title"] ?? '';
          _descriptionController.text = data["description"] ?? '';

          // تعيين نوع الطلب
          final typeName = data["typeName"];
          if (typeName != null && _requestTypes.contains(typeName)) {
            _selectedRequestType = typeName;
          }

          // تعيين الأولوية
          final priority = data["priority"] ?? 'Medium';
          _selectedPriority = _normalizePriority(priority);

          // تعيين الملفات
          _documents = data["documents"] ?? [];
          debugPrint('📋 Loaded ${_documents.length} documents');
        });
      } else {
        _showErrorSnackBar('Failed to load request details: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
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

  // 🔥 دالة لتوليد اسم فريد للملف
  String _generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString();
    final extension = originalName.split('.').last;
    final nameWithoutExtension = originalName.substring(0, originalName.lastIndexOf('.'));

    // تنظيف الاسم من الأحرف الخاصة
    String cleanedName = nameWithoutExtension
        .replaceAll(RegExp(r'[^\w\s\.-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .trim();

    return '${cleanedName}_${timestamp}_$randomSuffix.$extension';
  }

  // 🔹 دالة رفع ملف جديد
  Future<void> _uploadNewFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
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
          _newFiles.addAll(uniqueFiles);
        });
        _showSuccessSnackBar(AppLocalizations.of(context)!.translate('files_selected_for_upload').replaceFirst('{count}', '${uniqueFiles.length}'));
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_uploading_file').split(':')[0]}: $e');
    }
  }

  // 🔹 دالة حذف ملف موجود
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

  // 🔹 دالة رفع ملف جديد وربطه بالطلب - مصححة
  Future<void> _uploadAndLinkNewFiles() async {
    if (_newFiles.isEmpty) return;

    setState(() {
      _isUploadingFile = true;
    });

    try {
      List<String> uploadedFiles = [];
      List<Map<String, dynamic>> newDocuments = [];

      // 1. رفع الملفات الجديدة
      for (final file in _newFiles) {
        final uniqueFileName = file.name;

        var uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('$_documentApiUrl/documents'),
        );

        uploadRequest.headers['Authorization'] = 'Bearer $_userToken';
        uploadRequest.headers['accept'] = 'application/json';

        uploadRequest.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: uniqueFileName,
        ));

        var uploadResponse = await uploadRequest.send();
        debugPrint('📤 Upload Status: ${uploadResponse.statusCode}');

        if (uploadResponse.statusCode == 201 || uploadResponse.statusCode == 200) {
          final responseData = await uploadResponse.stream.bytesToString();
          final documentData = json.decode(responseData);
          debugPrint('📄 Upload Response: $responseData');

          final dynamic rawId = documentData["id"];
          final int documentId = rawId is int ? rawId : int.parse(rawId.toString());
          final String title = documentData["title"] ?? file.name;
          final String uploadedAt = documentData["uploadedAt"] ?? DateTime.now().toIso8601String();
          final String uploaderName = documentData["uploaderName"] ?? _userName ?? "user";

          // بناء كائن الملف بالشكل الصحيح كما في الـ response
          final Map<String, dynamic> newDocument = {
            "id": documentId,
            "title": title,
            "uploadedAt": uploadedAt,
            "uploaderName": uploaderName,
            "downloadURI": "/documents/$documentId/download"
          };

          newDocuments.add(newDocument);
          uploadedFiles.add(file.name);
          debugPrint('📎 Document created: ${newDocument["title"]}');
        } else {
          final errorData = await uploadResponse.stream.bytesToString();
          debugPrint('❌ Upload failed: $errorData');
        }
      }

      // 2. ربط كل الملفات الجديدة بالمعاملة
      if (newDocuments.isNotEmpty) {
        int linkedCount = 0;

        for (final document in newDocuments) {
          final int documentId = document["id"];
          debugPrint('🔗 Linking document $documentId to transaction ${widget.requestId}');

          final linkResponse = await http.post(
            Uri.parse('$_documentApiUrl/transactions/${widget.requestId}/document/$documentId'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $_userToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({}),
          );

          debugPrint('🔗 Link Status: ${linkResponse.statusCode}');
          if (linkResponse.statusCode == 200 || linkResponse.statusCode == 201) {
            linkedCount++;

            // ✅ إضافة الملف إلى القائمة مباشرة
            setState(() {
              _documents.add(document);
            });

            debugPrint('✅ Document $documentId linked and added to list');
          } else {
            debugPrint('❌ Link failed: ${linkResponse.body}');
          }
        }

        if (linkedCount > 0) {
          setState(() {
            _recentlyUploadedFiles.addAll(uploadedFiles);
            _newFiles.clear();
          });

          _showSuccessSnackBar(AppLocalizations.of(context)!.translate('files_uploaded_success_count').replaceFirst('{count}', '$linkedCount'));
        } else {
          _showErrorSnackBar('Failed to link any documents to the request');
        }
      } else {
        _showErrorSnackBar('No files were uploaded successfully');
      }

    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_uploading_file').split(':')[0]}: $e');
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  // 🔹 دالة تحديث بيانات الطلب
  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 1. تحديث بيانات الطلب الأساسية
      final requestData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'typeName': _selectedRequestType,
        'priority': _selectedPriority.toUpperCase(),
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
        final responseData = json.decode(response.body);
        if (responseData["status"] == "success") {
          // 2. إذا كانت هناك ملفات جديدة، رفعها وربطها
          if (_newFiles.isNotEmpty) {
            await _uploadAndLinkNewFiles();
          } else {
            _showSuccessSnackBar(AppLocalizations.of(context)!.translate('request_updated_success_details'));
            // إعادة تحميل البيانات للتأكد من التحديث
            await _fetchRequestDetails();
          }
        } else {
          _showErrorSnackBar('Update failed: ${responseData["message"]}');
        }
      } else {
        _showErrorSnackBar('Failed to update request with status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.translate('error_loading_data')} $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // 🔥 دالة جديدة للخروج
  Future<void> _finishEditing() async {
    _showSuccessSnackBar(AppLocalizations.of(context)!.translate('editing_completed'));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // دالة مساعدة لتنسيق التاريخ
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  // 🔹 ويدجت لعرض الملفات
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

        // مؤشر تحميل رفع الملفات
        if (_isUploadingFile) ...[
          LinearProgressIndicator(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: isMobile ? 12 : 16),
        ],

        // 🔥 رسالة تذكير إذا كان هناك ملفات مرفوعة حديثاً
        if (_recentlyUploadedFiles.isNotEmpty) ...[
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
                        AppLocalizations.of(context)!.translate('recently_uploaded_files').replaceFirst('{count}', '${_recentlyUploadedFiles.length}'),
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
                ..._recentlyUploadedFiles.map((fileName) =>
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

        // الملفات المرفقة حالياً
        if (_documents.isNotEmpty) ...[
          ..._documents.map((document) => _buildDocumentItem(document, isMobile, isTablet)),
          SizedBox(height: isMobile ? 12 : 16),
        ] else if (_recentlyUploadedFiles.isEmpty) ...[
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

        // الملفات الجديدة المحددة للرفع
        if (_newFiles.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.translate('new_files_to_upload'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          ..._newFiles.map((file) => _buildNewFileItem(file, isMobile, isTablet)),
          SizedBox(height: isMobile ? 12 : 16),
        ],

        // زر إضافة ملفات جديدة
        ElevatedButton.icon(
          onPressed: _uploadNewFile,
          icon: Icon(Icons.add, size: isMobile ? 18 : 20),
          label: Text(
            AppLocalizations.of(context)!.translate('add_more_files'),
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

  // 🔹 ويدجت لعرض ملف مرفق
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
              'ID: $fileId | Uploaded by: $uploader',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (uploadDate.isNotEmpty)
              Text(
                'Uploaded: ${_formatDate(uploadDate)}',
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

  // 🔹 ويدجت لعرض ملف جديد
  Widget _buildNewFileItem(PlatformFile file, bool isMobile, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentBlue),
      ),
      child: ListTile(
        leading: Icon(Icons.file_present_rounded, color: AppColors.accentBlue, size: isMobile ? 20 : 22),
        title: Text(
          file.name,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: AppColors.accentBlue,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: AppColors.accentRed, size: isMobile ? 18 : 20),
          onPressed: () {
            setState(() {
              _newFiles.removeWhere((f) => f.name == file.name);
            });
          },
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
    } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg') || fileName.toLowerCase().endsWith('.png')) {
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
            // العنوان الرئيسي
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
            SizedBox(height: isMobile ? 16 : 24),

            // المعلومات الأساسية
            Text(
              AppLocalizations.of(context)!.translate('basic_information'),
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // حقل العنوان
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
                  tooltip: 'Manage Request Types',
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            DropdownButtonFormField<String>(
              value: _selectedRequestType,
              decoration: _buildInputDecoration(),
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
                          color: v == 'Request Type' ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                      if (v != 'Request Type' && typeData.creatorName != 'System' && typeData.creatorName != '')
                        Text(
                          'Created by: ${typeData.creatorName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() { _selectedRequestType = newValue!; });
              },
              validator: (value) => (value == 'Request Type') ? AppLocalizations.of(context)!.translate('request_type_hint') : null,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // الأولوية
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
              onChanged: (newValue) {
                setState(() { _selectedPriority = newValue!; });
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // الوصف
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
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // قسم الملفات
            _buildDocumentsSection(isMobile, isTablet),

            // 🔥 زر Update Request في الأعلى
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

            // 🔥 زر Finish في المنتصف في الأسفل
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

    // إضافة السكرول للديسكتوب فقط مع حدود قصوى
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