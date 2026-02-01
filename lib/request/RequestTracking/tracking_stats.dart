import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildStatsSection({
  required BuildContext context,
  required List<dynamic> forwards,
  required bool isMobile,
  required bool isTablet,
}) {
  final total = forwards.length;
  final waiting = forwards.where((f) => f['status'] == 'waiting').length;
  final approved = forwards.where((f) => f['status'] == 'approved').length;
  final rejected = forwards.where((f) => f['status'] == 'rejected').length;
  final needsEditing = forwards.where((f) => f['status'] == 'needs-editing').length;

  final statItems = [
    {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": total, "color": TrackingColors.textPrimary, "icon": Icons.dashboard_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_waiting'), "value": waiting, "color": TrackingColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
    {"label": AppLocalizations.of(context)!.translate('status_approved'), "value": approved, "color": TrackingColors.statusApproved, "icon": Icons.check_circle_rounded},
    {"label": AppLocalizations.of(context)!.translate('others_stat_label'), "value": rejected + needsEditing, "color": TrackingColors.statusNeedsEditing, "icon": Icons.more_horiz_rounded},
  ];

  return Container(
    margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
    padding: EdgeInsets.all(isMobile ? 16 : 20),
    decoration: BoxDecoration(
      color: TrackingColors.statBgLight,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: TrackingColors.statShadow,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: TrackingColors.statBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: statItems.map((stat) => _buildStatItem(
        label: stat["label"] as String,
        value: stat["value"] as int,
        color: stat["color"] as Color,
        icon: stat["icon"] as IconData,
        isMobile: isMobile,
      )).toList(),
    ),
  );
}

Widget _buildStatItem({required String label, required int value, required Color color, required IconData icon, required bool isMobile}) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: isMobile ? 18 : 20),
      ),
      SizedBox(height: isMobile ? 6 : 8),
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 10 : 12,
          color: TrackingColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}