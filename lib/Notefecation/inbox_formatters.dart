import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:college_project/l10n/app_localizations.dart';

class InboxFormatters {
  // 🔹 دالة لتحويل التاريخ
  static String formatDate(BuildContext context, dynamic dateValue) {
    try {
      if (dateValue == null ||
          dateValue == "N/A" ||
          dateValue.toString().isEmpty) {
        return AppLocalizations.of(context)!.translate('n_a');
      }

      String dateString = dateValue.toString();
      if (dateString.contains('T')) {
        final date = DateTime.parse(dateString);
        final locale = Localizations.localeOf(context).languageCode;
        return DateFormat('MMM dd, yyyy - HH:mm', locale).format(date);
      }
      return dateString;
    } catch (e) {
      print("❌ Error formatting date: $dateValue - $e");
      return AppLocalizations.of(context)!.translate('n_a');
    }
  }
}