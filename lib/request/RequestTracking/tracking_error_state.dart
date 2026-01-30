import 'package:flutter/material.dart';
import 'tracking_colors.dart';

Widget buildErrorState({
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
            label: Text('Try Again', style: TextStyle(fontSize: isMobile ? 14 : 16)),
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