import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildLoadingState(BuildContext context, bool isMobile) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TrackingColors.primary),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          AppLocalizations.of(context)!.translate('loading_tracking_msg'),
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: TrackingColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}