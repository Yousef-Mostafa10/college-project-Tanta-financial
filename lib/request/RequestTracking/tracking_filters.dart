import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/request/RequestTracking/tracking_colors.dart';
import 'package:college_project/request/RequestTracking/tracking_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildFilterSection({
  required BuildContext context,
  required String selectedStatus,
  required List<String> statusFilters,
  required Function(String) onStatusChanged,
  required bool isMobile,
  required bool isTablet,
}) {
  return Container(
    margin: EdgeInsets.all(isMobile ? 12 : 16),
    padding: EdgeInsets.all(isMobile ? 16 : 20),
    decoration: BoxDecoration(
      color: TrackingColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: TrackingColors.statShadow,
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: TrackingColors.statBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_alt_rounded, color: TrackingColors.primary, size: isMobile ? 18 : 20),
            SizedBox(width: isMobile ? 6 : 8),
            Text(
              AppLocalizations.of(context)!.translate('filter_by_status_label'),
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: TrackingColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusFilters.map((status) {
            final isSelected = selectedStatus == status;
            final statusColor = TrackingHelpers.getStatusColorAsColor(status);

            String displayText = status;
            if (status == "All") {
              displayText = AppLocalizations.of(context)!.translate('all_filter');
            } else {
              displayText = AppLocalizations.of(context)!.translate('status_${status.toLowerCase().replaceAll('-', '_')}');
              if (displayText == 'status_${status.toLowerCase().replaceAll('-', '_')}') {
                displayText = status.toUpperCase();
              }
            }

            return FilterChip(
              selected: isSelected,
              label: Text(
                displayText,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: isSelected ? Colors.white : TrackingColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: TrackingColors.bodyBg,
              selectedColor: status == "All" ? TrackingColors.primary : statusColor,
              checkmarkColor: Colors.white,
              avatar: status != "All" ? Icon(
                TrackingHelpers.getStatusIconAsIconData(status),
                size: isMobile ? 14 : 16,
                color: isSelected ? Colors.white : statusColor,
              ) : null,
              onSelected: (selected) {
                onStatusChanged(selected ? status : "All");
              },
            );
          }).toList(),
        ),
      ],
    ),
  );
}