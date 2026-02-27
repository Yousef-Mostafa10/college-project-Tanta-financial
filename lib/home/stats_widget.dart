
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';

class StatsWidget extends StatelessWidget {
  final int total;
  final int approved;
  final int rejected;
  final int waiting;
  final int needsChange;  // إضافة
  final bool isMobile;

  const StatsWidget({
    super.key,
    required this.total,
    required this.approved,
    required this.rejected,
    required this.waiting,
    required this.needsChange,  // إضافة
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      {"label": AppLocalizations.of(context)!.translate('total'), "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
      {"label": AppLocalizations.of(context)!.translate('approved'), "value": approved, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
      {"label": AppLocalizations.of(context)!.translate('rejected'), "value": rejected, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
      {"label": AppLocalizations.of(context)!.translate('waiting'), "value": waiting, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
      // إضافة الحالتين الجديدتين:
      {"label": AppLocalizations.of(context)!.translate('needs_change'), "value": needsChange, "color": AppColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.statBgLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.statShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.statBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) =>
              isMobile 
                  ? Expanded(
                      child: _buildStatItem(
                        stat["label"] as String,
                        stat["value"] as int,
                        stat["color"] as Color,
                        stat["icon"] as IconData,
                      ),
                    )
                  : _buildStatItem(
                      stat["label"] as String,
                      stat["value"] as int,
                      stat["color"] as Color,
                      stat["icon"] as IconData,
                    )
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: isMobile ? 18 : 22),
        ),
        SizedBox(height: isMobile ? 6 : 10),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: color, // الرقم باللون المميز لكل حالة
          ),
        ),
        SizedBox(height: isMobile ? 2 : 6),
        Text(
          label,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            fontSize: isMobile ? 10 : 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
