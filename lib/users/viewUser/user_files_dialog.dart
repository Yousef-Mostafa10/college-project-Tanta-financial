import 'package:flutter/material.dart';
import 'users_api.dart';
import 'users_colors.dart';
import 'users_helpers.dart';
import 'package:college_project/l10n/app_localizations.dart';

class UserFilesDialog extends StatefulWidget {
  final String userName;
  final UsersApiService apiService;
  final bool isMobile;

  const UserFilesDialog({
    super.key,
    required this.userName,
    required this.apiService,
    required this.isMobile,
  });

  @override
  State<UserFilesDialog> createState() => _UserFilesDialogState();
}

class _UserFilesDialogState extends State<UserFilesDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await widget.apiService.getUserUploadedDocuments(widget.userName); // Filtered inside API service per user request
      if (mounted) {
        setState(() {
          _files = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        UsersHelpers.showErrorMessage(context, e.toString());
        setState(() => _isLoading = false);
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
              '${AppLocalizations.of(context)!.translate('uploaded_files') ?? 'Uploaded Files'}',
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
                          AppLocalizations.of(context)!.translate('no_files_found') ?? 'No files uploaded',
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
                      final fileName = file['title'] ?? 'Unknown File';
                      final uploadedAt = file['uploadedAt'] != null 
                          ? UsersHelpers.formatDate(file['uploadedAt'], context) 
                          : 'N/A';
                          
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file_outlined, color: AppColors.accentBlue),
                        title: Text(
                          fileName,
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          uploadedAt,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('close') ?? 'Close'),
        ),
      ],
    );
  }
}
