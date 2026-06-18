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
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.translate('all_transactions').toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MyRequestsColors.primary,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        // Count badge styled like Inbox
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: MyRequestsColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: MyRequestsColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            AppLocalizations.of(context)!
                .translate('transactions_count')
                .replaceFirst('{count}', '$itemCount'),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
          strokeWidth: 3,
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text(
          AppLocalizations.of(context)!.translate('loading_requests'),
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: MyRequestsColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}