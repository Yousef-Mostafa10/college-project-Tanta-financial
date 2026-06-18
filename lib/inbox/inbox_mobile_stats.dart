

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';

class InboxMobileStats extends StatelessWidget {
  final int total;
  final int waiting;
  final int approved;
  final int rejected;
  final int needsChange; // إضافة هذا الحقل

  const InboxMobileStats({
    Key? key,
    required this.total,
    required this.waiting,
    required this.approved,
    required this.rejected,
    required this.needsChange, // إضافة هذا
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statItems = [
      {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": total, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
      {"label": AppLocalizations.of(context)!.translate('waiting'), "value": waiting, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
      {"label": AppLocalizations.of(context)!.translate('approved'), "value": approved, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
      {"label": AppLocalizations.of(context)!.translate('rejected'), "value": rejected, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
      {"label": AppLocalizations.of(context)!.translate('needs_change'), "value": needsChange, "color": AppColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.statBgLight,
                  AppColors.statBgLight.withOpacity(AppColors.isDark ? 0.45 : 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.borderColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statItems.map((stat) => 
                Expanded(
                  child: _buildMobileStatItem(
                    label: stat["label"] as String,
                    value: stat["value"] as int,
                    color: stat["color"] as Color,
                    icon: stat["icon"] as IconData,
                  ),
                )
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStatItem({required String label, required int value, required Color color, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutQuart,
          builder: (context, val, child) {
            return Text(
              val.toString(),
              style: TextStyle(
                fontSize: 18,
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
        const SizedBox(height: 4),
        Text(
          label,
          softWrap: false,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
