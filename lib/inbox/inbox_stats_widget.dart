

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';
import './inbox_helpers.dart';

class InboxStatsWidget extends StatelessWidget {
  final List<dynamic> requests;
  final bool isMobile;
  final Map<String, int>? apiSummary;
  final int? totalRequests;

  const InboxStatsWidget({
    Key? key,
    required this.requests,
    this.isMobile = false,
    this.apiSummary,
    this.totalRequests,
  }) : super(key: key);

  // حساب الإحصائيات من الـ API summary أو من البيانات المحلية
  Map<String, int> _calculateStats() {
    if (apiSummary != null) {
      return {
        'total': totalRequests ?? requests.length,
        'waiting': apiSummary!['WAITING'] ?? 0,
        'approved': apiSummary!['APPROVED'] ?? 0,
        'rejected': apiSummary!['REJECTED'] ?? 0,
        'needs_change': apiSummary!['NEEDS_EDITING'] ?? 0,
      };
    }

    final total = requests.length;

    final waiting = requests.where((req) =>
    InboxHelpers.isRequestPending(req) &&
        req["fulfilled"] != true
    ).length;

    final approved = requests.where((req) =>
    InboxHelpers.isRequestApproved(req) &&
        req["fulfilled"] != true
    ).length;

    final rejected = requests.where((req) =>
    InboxHelpers.isRequestRejected(req) &&
        req["fulfilled"] != true
    ).length;

    final needsChange = requests.where((req) =>
    InboxHelpers.isRequestNeedsChange(req) &&
        req["fulfilled"] != true
    ).length;

    return {
      'total': total,
      'waiting': waiting,
      'approved': approved,
      'rejected': rejected,
      'needs_change': needsChange,
    };
  }

  // إحصائيات الديسكتوب
  Widget _buildDesktopStatsRow(BuildContext context) {
    final stats = _calculateStats();

    final statItems = [
      {"label": AppLocalizations.of(context)!.translate('total_stat'), "value": stats['total']!, "color": AppColors.textPrimary, "icon": Icons.dashboard_rounded},
      {"label": AppLocalizations.of(context)!.translate('waiting'), "value": stats['waiting']!, "color": AppColors.statusWaiting, "icon": Icons.hourglass_empty_rounded},
      {"label": AppLocalizations.of(context)!.translate('approved'), "value": stats['approved']!, "color": AppColors.statusApproved, "icon": Icons.check_circle_rounded},
      {"label": AppLocalizations.of(context)!.translate('rejected'), "value": stats['rejected']!, "color": AppColors.statusRejected, "icon": Icons.cancel_rounded},
      {"label": AppLocalizations.of(context)!.translate('needs_change'), "value": stats['needs_change']!, "color": AppColors.statusNeedsChange, "icon": Icons.edit_note_rounded},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.statBgLight,
                AppColors.statBgLight.withOpacity(AppColors.isDark ? 0.45 : 0.9),
              ],
            ),
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
                  ? Colors.white.withOpacity(0.15)
                  : AppColors.borderColor.withOpacity(0.6),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statItems.map((stat) =>
                  _buildStatItem(
                    stat["label"] as String,
                    stat["value"] as int,
                    stat["color"] as Color,
                    stat["icon"] as IconData,
                    false,
                  )
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon, bool isMobile) {
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

  @override
  Widget build(BuildContext context) {
    return _buildDesktopStatsRow(context);
  }
}
