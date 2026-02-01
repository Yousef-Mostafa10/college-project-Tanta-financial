import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildDesktopHeader(BuildContext context, int itemCount) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_outlined, color: MyRequestsColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.translate('all_transactions').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MyRequestsColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: MyRequestsColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: MyRequestsColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('transactions_count').replaceFirst('{count}', '$itemCount'),
            style: TextStyle(
              fontSize: 12,
              color: MyRequestsColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildLoadingState(BuildContext context, bool isMobile) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MyRequestsColors.primary),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          AppLocalizations.of(context)!.translate('loading_requests'),
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: MyRequestsColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}