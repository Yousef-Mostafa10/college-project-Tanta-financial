import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildEmptyState(BuildContext context, bool isMobile, {Function()? onResetFilters}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: MyRequestsColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate('no_transactions_found'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.translate('try_adjust_filters'),
              style: TextStyle(
                fontSize: 12,
                color: MyRequestsColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            if (onResetFilters != null)
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate('reset_filters')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyRequestsColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      )
    ),
  );
}