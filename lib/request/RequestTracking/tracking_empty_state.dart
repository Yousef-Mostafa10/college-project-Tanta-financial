import 'package:flutter/material.dart';
import 'tracking_colors.dart';

Widget buildEmptyState({
  required bool isMobile,
  required bool isTablet,
}) {
  return Container(
    height: 300,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: TrackingColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: TrackingColors.primary.withOpacity(0.3)),
              ),
              child: Icon(Icons.timeline_rounded, size: isMobile ? 48 : 64, color: TrackingColors.primary),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              "No forwarding history found",
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: TrackingColors.primary,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              "This transaction hasn't been forwarded to any users yet",
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: TrackingColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}