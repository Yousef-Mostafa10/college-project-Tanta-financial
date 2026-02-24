import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:college_project/request/RequestTracking/tracking_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildTimelineStep({
  required BuildContext context,
  required dynamic forward,
  required int stepNumber,
  required bool isFirst,
  required bool isLast,
  required int totalSteps,
  required bool isMobile,
  required bool isTablet,
}) {
  final statusColor = TrackingHelpers.getStatusColorAsColor(forward['status']);
  final statusIcon = TrackingHelpers.getStatusIconAsIconData(forward['status']);

  return Container(
    margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الخط الزمني العمودي
        Column(
          children: [
            // الدائرة العلوية (للخط)
            if (!isFirst) ...[
              Container(
                width: 2,
                height: isMobile ? 16 : 20,
                color: TrackingColors.primary.withOpacity(0.3),
              ),
            ],
            // الدائرة الرئيسية
            Container(
              width: isMobile ? 32 : 40,
              height: isMobile ? 32 : 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            // الخط السفلي (للخط)
            if (!isLast) ...[
              Container(
                width: 2,
                height: isMobile ? 16 : 20,
                color: TrackingColors.primary.withOpacity(0.3),
              ),
            ],
          ],
        ),
        SizedBox(width: isMobile ? 12 : 16),

        // محتوى الخطوة
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: TrackingColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TrackingColors.statShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الهيدر - المرسل والمستقبل
                Row(
                  children: [
                    // المرسل
                    Expanded(
                      child: _buildUserCard(
                        context,
                        forward['sender'],
                        AppLocalizations.of(context)!.translate('from_label'),
                        Icons.person_outline_rounded,
                        TrackingColors.accentBlue,
                        isMobile,
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    // السهم
                    Container(
                      padding: EdgeInsets.all(isMobile ? 3 : 4),
                      decoration: BoxDecoration(
                        color: TrackingColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: TrackingColors.primary.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, size: isMobile ? 14 : 16, color: TrackingColors.primary),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    // المستقبل
                    Expanded(
                      child: _buildUserCard(
                        context,
                        forward['receiver'],
                        AppLocalizations.of(context)!.translate('to_label'),
                        Icons.person_rounded,
                        TrackingColors.accentGreen,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8 : 12),

                // معلومات الحالة والتاريخ
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: isMobile ? 14 : 16, color: statusColor),
                          SizedBox(width: isMobile ? 4 : 6),
                          Text(
                            AppLocalizations.of(context)!.translate('status_${forward['status'].toString().toLowerCase()}'),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // معلومات المشاهدة - المرسل
                    Row(
                      children: [
                        Icon(
                          forward['senderSeen'] == true
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: isMobile ? 13 : 15,
                          color: forward['senderSeen'] == true
                              ? TrackingColors.accentBlue
                              : TrackingColors.textMuted,
                        ),
                        SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(context)!.translate('from_label'),
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 11,
                            color: forward['senderSeen'] == true
                                ? TrackingColors.accentBlue
                                : TrackingColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    // معلومات المشاهدة - المستقبل
                    Row(
                      children: [
                        Icon(
                          forward['receiverSeen'] == true
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: isMobile ? 13 : 15,
                          color: forward['receiverSeen'] == true
                              ? TrackingColors.statusApproved
                              : TrackingColors.textMuted,
                        ),
                        SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(context)!.translate('to_label'),
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 11,
                            color: forward['receiverSeen'] == true
                                ? TrackingColors.statusApproved
                                : TrackingColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isMobile ? 8 : 12),

                    Text(
                      TrackingHelpers.formatDate(forward['forwardedAt']),
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: TrackingColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // تعليق المرسل (senderComment)
                if (forward['senderComment'] != null && forward['senderComment'].toString().isNotEmpty) ...[
                  SizedBox(height: isMobile ? 8 : 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: TrackingColors.accentBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TrackingColors.accentBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.comment_rounded,
                              size: isMobile ? 14 : 16,
                              color: TrackingColors.accentBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.translate('sender_comment_label'),
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: TrackingColors.accentBlue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          forward['senderComment'].toString(),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: TrackingColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // تعليق المستقبل (receiverComment)
                if (forward['receiverComment'] != null && forward['receiverComment'].toString().isNotEmpty) ...[
                  SizedBox(height: isMobile ? 8 : 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: TrackingColors.accentGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TrackingColors.accentGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: isMobile ? 14 : 16,
                              color: TrackingColors.accentGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.translate('receiver_comment_label'),
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: TrackingColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          forward['receiverComment'].toString(),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: TrackingColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        )],
    ),
  );
}

Widget _buildUserCard(BuildContext context, Map<String, dynamic>? user, String label, IconData icon, Color color, bool isMobile) {
  final userName = user?['name'] ?? AppLocalizations.of(context)!.translate('unknown');
  final userDepartment = user?['departmentName'] ?? AppLocalizations.of(context)!.translate('not_available');
  final userRole = user?['role'] ?? '';

  return Container(
    padding: EdgeInsets.all(isMobile ? 8 : 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: isMobile ? 12 : 14, color: color),
            SizedBox(width: isMobile ? 3 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 2 : 4),
        Text(
          userName,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: TrackingColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (userDepartment.isNotEmpty) ...[
          Text(
            userDepartment,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              color: TrackingColors.textSecondary,
            ),
          ),
        ],
        if (userRole.isNotEmpty) ...[
          Text(
            userRole,
            style: TextStyle(
              fontSize: isMobile ? 8 : 10,
              color: TrackingColors.textMuted,
            ),
          ),
        ],
        if (user?['active'] == false) ...[
          Container(
            margin: EdgeInsets.only(top: isMobile ? 2 : 4),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 4 : 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: TrackingColors.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TrackingColors.accentRed.withOpacity(0.3)),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('inactive_user_label'),
              style: TextStyle(
                fontSize: isMobile ? 7 : 9,
                color: TrackingColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}