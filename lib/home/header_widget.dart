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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt_outlined,
                color: AppColors.primary,
                size: isMobile ? 14 : 18,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)?.translate('transaction') ?? 'TRANSACTIONS',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              itemCount > 0
                  ? '$startIndex-$endIndex من $itemCount'
                  : '0 معاملة',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}