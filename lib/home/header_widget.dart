import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';

class HeaderWidget extends StatelessWidget {
  final int itemCount;
  final bool isMobile;
  final int currentPage;
  final int itemsPerPage;

  const HeaderWidget({
    super.key,
    required this.itemCount,
    required this.isMobile,
    required this.currentPage,
    required this.itemsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    final startIndex = itemCount > 0 ? (currentPage - 1) * itemsPerPage + 1 : 0;
    final endIndex = itemCount > 0
        ? (startIndex + itemsPerPage - 1).clamp(0, itemCount)
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: icon + title
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.list_alt_rounded,
                color: AppColors.primary,
                size: isMobile ? 14 : 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)?.translate('transaction') ??
                  'TRANSACTIONS',
              style: TextStyle(
                fontSize: isMobile ? 13 : 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Right: count badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            itemCount > 0
                ? AppLocalizations.of(context)!
                    .translate('showing_range')
                    .replaceFirst('{start}', startIndex.toString())
                    .replaceFirst('{end}', endIndex.toString())
                    .replaceFirst('{total}', itemCount.toString())
                : AppLocalizations.of(context)!
                    .translate('transactions_count')
                    .replaceFirst('{count}', '0'),
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}