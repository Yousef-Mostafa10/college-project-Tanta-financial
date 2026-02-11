import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:college_project/l10n/app_localizations.dart';

import '../../app_config.dart';
import '../../utils/storage_permission_helper.dart';

// 🎨 COLOR PALETTE - Consistent with Dashboard and Inbox
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

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);

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
}

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

  // متغيرات لمنع الاستدعاء المكرر
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _getUserToken();
  }



  Future<void> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      setState(() {
        _userToken = token;
      });
      await _fetchRequestData();
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.translate('error_loading_data_msg');
        _isLoading = false;
      });
    }
  }

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
        } else {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.translate('no_request_details_msg');
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.translate('failed_load_requests')}: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "${AppLocalizations.of(context)!.translate('network_error')}: ${e.toString()}";
        _isLoading = false;
      });
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

  Future<bool> _requestPermission() async {
    return await StoragePermissionHelper.requestStoragePermission();
  }

  Future<void> _downloadFile(int documentId, String fileName) async {
    // 1️⃣ التحقق من الأذونات أولاً
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

    // 2️⃣ تحديث حالة التنزيل
    setState(() {
      _downloadingFiles[fileName] = true;
      _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('starting_download_msg');
    });

    // 3️⃣ الحصول على مسار التخزين الآمن
    Directory? downloadDir;
    String? storagePath;

    try {
      downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        downloadDir = Directory((await getTemporaryDirectory()).path);
      }

      storagePath = downloadDir.path;

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

    // 4️⃣ التحميل من الـ API الجديد باستخدام الـ ID
    final downloadUrl = "$_baseUrl/documents/$documentId/download";

    try {
      setState(() {
        _downloadProgress[fileName] = '📥 Downloading...';
      });

      final response = await http.get(
        Uri.parse(downloadUrl),
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
  // 🔥 دالة جديدة لعرض تفاصيل الملف المحمل
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

  // 🔥 دالة للحصول على حجم الملف
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
    return 'Unknown';
  }

  // 🔥 دالة لفتح موقع الملف
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
            icon: const Icon(Icons.refresh_rounded),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.accentRed, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
    final type = data["type"]?["name"] ?? AppLocalizations.of(context)!.translate('not_available');
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
    final status = fulfilled ? AppLocalizations.of(context)!.translate('status_fulfilled') : AppLocalizations.of(context)!.translate('pending');
    final statusColor = fulfilled ? AppColors.accentGreen : AppColors.accentYellow;
    final creator = data["creator"]?["name"] ?? AppLocalizations.of(context)!.translate('unknown');
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
          _buildDetailsCard(type, priority, description, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          if (documents.isNotEmpty) ...[
            _buildAttachmentsCard(documents, isMobile),
            SizedBox(height: isMobile ? 16 : 20),
          ],
          _buildAdditionalInfoCard(data, isMobile),
        ],
      ),
    );

    // إضافة السكرول للديسكتوب فقط
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

  Widget _buildDetailsCard(String type, String priority, String description, bool isMobile) {
    final priorityColor = _getPriorityColor(priority);
    final priorityIcon = _getPriorityIcon(priority);

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

  // تصميم للموبايل
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

  // تصميم جديد للديسكتوب - أكثر مرونة
  Widget _buildDesktopAttachmentItem(
      String fileName, String uploaderName, dynamic fileId,
      bool isDownloading, String? downloadStatus, bool isDownloaded,
      dynamic documentId, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Icon
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: _getFileIcon(fileName),
          ),
          SizedBox(width: 12),

          // File Info - تأخذ المساحة المتبقية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File Name
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

                // Uploader Info و File ID في سطر واحد إذا أمكن
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
                        'ID: $fileId',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),

                // Download Status
                if (isDownloading && downloadStatus != null) ...[
                  SizedBox(height: 6),
                  _buildDownloadProgress(downloadStatus, false),
                ],

                // Downloaded Status
                if (isDownloaded) ...[
                  SizedBox(height: 6),
                  _buildDownloadedStatus(fileName, false),
                ],
              ],
            ),
          ),

          SizedBox(width: 12),

          // Download Button
          _buildDownloadButton(isDownloading, isDownloaded, documentId, fileName, false),
        ],
      ),
    );
  }

  // بناء الـ subtitle بشكل منفصل لإعادة استخدامه
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
                Text('ID: $fileId',
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

  // بناء progress indicator منفصل
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

  // بناء حالة التحميل المكتمل
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

  // تحديث دالة بناء زر التحميل
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

  Future<String> _getDownloadPath(String fileName) async {
    try {
      final filePath = _downloadedFilePaths[fileName];
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          return filePath;
        }
      }

      final dir = await getDownloadsDirectory();
      if (dir != null) {
        return '${dir.path}/$fileName';
      }
      final internalDir = await getExternalStorageDirectory();
      return internalDir?.path ?? AppLocalizations.of(context)!.translate('unknown');
    } catch (e) {
      return AppLocalizations.of(context)!.translate('unknown');
    }
  }

  Widget _buildAdditionalInfoCard(Map<String, dynamic> data, bool isMobile) {
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
            if (data["creator"]?["group"] != null)
              _buildInfoRow(AppLocalizations.of(context)!.translate('role_label'), data["creator"]?["group"] ?? AppLocalizations.of(context)!.translate('not_available'), isMobile),
          ],
        ),
      ),
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
