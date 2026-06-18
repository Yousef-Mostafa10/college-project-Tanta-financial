import 'dart:ui';
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.statShadow.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: AppColors.isDark
                  ? Colors.white.withOpacity(0.15)
                  : AppColors.borderColor.withOpacity(0.6),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.statBgLight,
                AppColors.statBgLight.withOpacity(AppColors.isDark ? 0.45 : 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            boxShadow: AppColors.isDark
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, color: color, size: isMobile ? 22 : 28),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutQuart,
          builder: (context, val, child) {
            return Text(
              val.toString(),
              style: TextStyle(
                fontSize: isMobile ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: AppColors.isDark
                    ? [
                        Shadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          label,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            fontSize: isMobile ? 11 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
