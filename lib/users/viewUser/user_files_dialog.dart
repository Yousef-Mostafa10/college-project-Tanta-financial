import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import '../../utils/app_error_handler.dart';
import '../../utils/storage_permission_helper.dart';
import '../../app_config.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'package:college_project/l10n/app_localizations.dart';

class UserFilesDialog extends StatefulWidget {
  final String userName;
  final int userId;
  final UsersApiService apiService;
  final bool isMobile;

  const UserFilesDialog({
    super.key,
    required this.userName,
    required this.userId,
    required this.apiService,
    required this.isMobile,
  });

  @override
  State<UserFilesDialog> createState() => _UserFilesDialogState();
}

class _UserFilesDialogState extends State<UserFilesDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _files = [];
  String? _userToken;
  final String _baseUrl = AppConfig.baseUrl;

  Map<String, bool> _downloadingFiles = {};
  Map<String, String> _downloadProgress = {};
  Map<String, String> _downloadedFilePaths = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userToken = prefs.getString('token');
    });
    await _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await widget.apiService.getUserUploadedDocuments(widget.userName); // Filtered inside API service per user request
      if (mounted) {
        setState(() {
          _files = files;
          _isLoading = false;
        });
        await _checkDownloadedFiles(files);
      }
    } catch (e) {
      if (mounted) {
        UsersHelpers.showErrorMessage(context, AppErrorHandler.translateException(context, e));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkDownloadedFiles(List<Map<String, dynamic>> documents) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> existingFiles = {};

      for (var doc in documents) {
        final docId = doc["id"]?.toString();
        if (docId == null) continue;

        final savedPath = prefs.getString('downloaded_doc_$docId');
        if (savedPath != null) {
          final file = io.File(savedPath);
          if (await file.exists()) {
            existingFiles[docId] = savedPath;
          } else {
            await prefs.remove('downloaded_doc_$docId');
          }
        }
      }

      if (mounted && existingFiles.isNotEmpty) {
        setState(() {
          _downloadedFilePaths.addAll(existingFiles);
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking downloaded files: $e');
    }
  }

  Future<void> _downloadFile(int documentId, String fileName) async {
    if (!kIsWeb) {
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
    }

    if (kIsWeb) {
      final url = Uri.parse("$_baseUrl/documents/$documentId/download");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch download URL')),
          );
        }
      }
      return;
    }

    setState(() {
      _downloadingFiles[fileName] = true;
      _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('starting_download_msg');
    });

    io.Directory? downloadDir;
    try {
      downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        downloadDir = io.Directory((await getTemporaryDirectory()).path);
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
        onTimeout: () => throw Exception('Download timeout'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _downloadProgress[fileName] = AppLocalizations.of(context)!.translate('saving_file_msg');
        });

        final file = io.File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (await file.exists()) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('downloaded_doc_$documentId', filePath);

          setState(() {
            _downloadingFiles[fileName] = false;
            _downloadProgress.remove(fileName);
            _downloadedFilePaths[documentId.toString()] = filePath;
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

  void _openFileLocation(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.translate('error') ?? "Error"}: ${result.message}'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('error_opening_file') ?? "Error opening file"),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      title: Row(
        children: [
          Icon(Icons.folder_shared_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.translate('uploaded_files'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: widget.isMobile ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.translate('no_files_found'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _files.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final docId = file['id'];
                      final fileName = file['title'] ?? 'Unknown File';
                      final uploadedAt = file['uploadedAt'] != null 
                          ? UsersHelpers.formatDate(file['uploadedAt'], context) 
                          : 'N/A';
                      
                      final isDownloading = _downloadingFiles[fileName] ?? false;
                      final isDownloaded = _downloadedFilePaths.containsKey(docId?.toString());
                      final filePath = _downloadedFilePaths[docId?.toString()];
                          
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file_outlined, color: AppColors.accentBlue),
                        title: Text(
                          fileName,
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              uploadedAt,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (isDownloading)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _downloadProgress[fileName] ?? '',
                                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        trailing: isDownloading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(
                                  isDownloaded ? Icons.folder_open_rounded : Icons.download_rounded,
                                  color: isDownloaded ? AppColors.accentGreen : AppColors.primary,
                                ),
                                tooltip: AppLocalizations.of(context)!.translate(
                                  isDownloaded ? 'open_folder_button' : 'download'
                                ) ?? (isDownloaded ? 'Open' : 'Download'),
                                onPressed: () {
                                  if (isDownloaded && filePath != null) {
                                    _openFileLocation(filePath);
                                  } else if (docId != null) {
                                    _downloadFile(docId, fileName);
                                  }
                                },
                              ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('close')),
        ),
      ],
    );
  }
}
