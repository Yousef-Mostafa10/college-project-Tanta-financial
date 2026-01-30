import 'package:flutter/material.dart';
import 'tracking_colors.dart';

Widget buildLoadingState(bool isMobile) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TrackingColors.primary),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          'Loading transaction tracking...',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: TrackingColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}