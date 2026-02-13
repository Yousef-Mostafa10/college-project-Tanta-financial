import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:college_project/request/RequestTracking/tracking_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildTransactionHeader({
  required BuildContext context,
  required String transactionId,
  required List<dynamic> forwards,
  required bool isMobile,
  required bool isTablet,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isMobile ? 16 : 24),
    decoration: BoxDecoration(
      color: TrackingColors.primary.withOpacity(0.1),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: TrackingColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: TrackingColors.primary.withOpacity(0.3)),
              ),
              child: Icon(Icons.timeline_rounded, color: TrackingColors.primary, size: isMobile ? 24 : 28),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('transaction_id_label').replaceFirst('{id}', transactionId),
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: TrackingColors.primary,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    AppLocalizations.of(context)!.translate('tracking_steps_count').replaceFirst('{count}', forwards.length.toString()),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: TrackingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // معلومات سريعة عن الحالة الحالية
        if (forwards.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: TrackingColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: TrackingColors.statShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // أيقونة الحالة
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TrackingHelpers.getStatusColorAsColor(forwards.last['status']).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: TrackingHelpers.getStatusColorAsColor(forwards.last['status']).withOpacity(0.3)),
                  ),
                  child: Icon(
                    TrackingHelpers.getStatusIconAsIconData(forwards.last['status']),
                    color: TrackingHelpers.getStatusColorAsColor(forwards.last['status']),
                    size: 20,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),

                // معلومات الحالة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('current_status_label'),
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: TrackingColors.textSecondary,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.translate('status_${forwards.last['status'].toString().toLowerCase()}'),
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: TrackingHelpers.getStatusColorAsColor(forwards.last['status']),
                        ),
                      ),
                    ],
                  ),
                ),

                // معلومات المشاهدة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          forwards.last['seen'] == true
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: isMobile ? 14 : 16,
                          color: forwards.last['seen'] == true
                              ? TrackingColors.statusApproved
                              : TrackingColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          forwards.last['seen'] == true
                              ? AppLocalizations.of(context)!.translate('seen_label')
                              : AppLocalizations.of(context)!.translate('not_seen_label'),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: forwards.last['seen'] == true
                                ? TrackingColors.statusApproved
                                : TrackingColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.translate('last_update_label'),
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: TrackingColors.textSecondary,
                      ),
                    ),
                    Text(
                      TrackingHelpers.formatDate(forwards.last['updatedAt'] ?? forwards.last['forwardedAt']),
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: TrackingColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}