
import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildDesktopStatsRow(BuildContext context, int total, int approved, int rejected, int waiting, int needsChange) {
  final stats = [
    {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": total, "color": MyRequestsColors.textPrimary, "icon": Icons.dashboard_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_approved'), "value": approved, "color": MyRequestsColors.statusApproved, "icon": Icons.check_circle_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_rejected'), "value": rejected, "color": MyRequestsColors.statusRejected, "icon": Icons.cancel_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_waiting'), "value": waiting, "color": MyRequestsColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
    {"label": AppLocalizations.of(context)!.translate('needs_change_stat'), "value": needsChange, "color": MyRequestsColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
  ];

  return Container(
    decoration: BoxDecoration(
      color: MyRequestsColors.statBgLight,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: MyRequestsColors.statShadow,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(color: MyRequestsColors.statBorder),
    ),
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (stat["color"] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: (stat["color"] as Color).withOpacity(0.3), width: 1),
              ),
              child: Icon(stat["icon"] as IconData, color: stat["color"] as Color, size: 22),
            ),
            SizedBox(height: 10),
            Text(
              (stat["value"] as int).toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stat["color"] as Color,
              ),
            ),
            SizedBox(height: 6),
            Text(
              stat["label"] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textSecondary,
              ),
            ),
          ],
        )).toList(),
      ),
    ),
  );
}