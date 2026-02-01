import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildErrorState({
  required BuildContext context,
  required String errorMessage,
  required Function() onRetry,
  required bool isMobile,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: isMobile ? 48 : 64, color: TrackingColors.accentRed),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: TrackingColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 18 : 20),
            label: Text(AppLocalizations.of(context)!.translate('try_again_button'), style: TextStyle(fontSize: isMobile ? 14 : 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: TrackingColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}