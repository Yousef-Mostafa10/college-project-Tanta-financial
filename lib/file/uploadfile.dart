import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(List<PlatformFile>) onFilesPicked; // Callback عند اختيار الملفات

  const FilePickerWidget({
    super.key,
    required this.onFilesPicked,
  });

  Future<void> _pickFiles(BuildContext context) async {
    // التحقق من الأذونات
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      status = await Permission.storage.request();

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يجب منح إذن التخزين لاختيار الملفات'),
            action: SnackBarAction(
              label: 'الإعدادات',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    // اختيار الملفات
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png', 'jpeg'
      ],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<PlatformFile> files = result.files;

      // استدعاء الكولباك وتمرير الملفات
      onFilesPicked(files);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم اختيار ${files.length} ملف'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('تم إلغاء اختيار الملفات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Drag and drop files here, or click to browse',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG (Max 10MB each)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickFiles(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text(
                'Choose Files',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
