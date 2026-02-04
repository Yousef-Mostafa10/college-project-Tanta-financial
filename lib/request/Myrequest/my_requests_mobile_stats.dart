import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildMobileStatsSection(BuildContext context, int total, int approved, int rejected, int waiting, int needsChange, int fulfilled) {
  final statItems = [
    {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": total, "color": MyRequestsColors.textPrimary, "icon": Icons.dashboard_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_approved'), "value": approved, "color": MyRequestsColors.statusApproved, "icon": Icons.check_circle_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_rejected'), "value": rejected, "color": MyRequestsColors.statusRejected, "icon": Icons.cancel_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_waiting'), "value": waiting, "color": MyRequestsColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_needs_editing'), "value": needsChange, "color": MyRequestsColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_fulfilled'), "value": fulfilled, "color": MyRequestsColors.statusFulfilled, "icon": Icons.task_alt_rounded},
  ];

  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: statItems.map((stat) => Expanded(
        child: _buildMobileStatItem(
          label: stat["label"] as String,
          value: stat["value"] as int,
          color: stat["color"] as Color,
          icon: stat["icon"] as IconData,
        ),
      )).toList(),
    ),
  );
}

Widget _buildMobileStatItem({required String label, required int value, required Color color, required IconData icon}) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: MyRequestsColors.textSecondary,
        ),
      ),
    ],
  );
}