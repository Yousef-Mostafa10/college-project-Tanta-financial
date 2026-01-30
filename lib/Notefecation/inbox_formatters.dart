// Notefecation/inbox_formatters.dart
import 'package:intl/intl.dart';

class InboxFormatters {
  // 🔹 دالة لتحويل التاريخ
  static String formatDate(dynamic dateValue) {
    try {
      if (dateValue == null ||
          dateValue == "N/A" ||
          dateValue.toString().isEmpty) {
        return "N/A";
      }

      String dateString = dateValue.toString();
      if (dateString.contains('T')) {
        final date = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy - HH:mm').format(date);
      }
      return dateString;
    } catch (e) {
      print("❌ Error formatting date: $dateValue - $e");
      return "N/A";
    }
  }
}