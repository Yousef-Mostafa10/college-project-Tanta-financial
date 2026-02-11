import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'users_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

class UsersHelpers {
  static String formatDate(String? iso, BuildContext context) {
    if (iso == null || iso.isEmpty) {
      return AppLocalizations.of(context)?.translate('unknown') ?? "Unknown";
    }
    try {
      final dt = DateTime.parse(iso);
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('dd/MM/yyyy', locale).format(dt);
    } catch (e) {
      return iso;
    }
  }

  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.roleAdmin;
      case 'user':
        return AppColors.roleUser;
      default:
        return AppColors.textSecondary;
    }
  }

  static void showErrorMessage(BuildContext context, String message) {
    final cleanMessage = message.replaceAll('Exception: ', '');
    final localizedMessage = AppLocalizations.of(context)?.translate(cleanMessage) ?? cleanMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(localizedMessage)),
          ],
        ),
        backgroundColor: AppColors.statusRejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccessMessage(BuildContext context, String message) {
    final localizedMessage = AppLocalizations.of(context)?.translate(message) ?? message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(localizedMessage)),
          ],
        ),
        backgroundColor: AppColors.statusApproved,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}