// Notefecation/inbox_header.dart
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';

class InboxHeader extends StatelessWidget {
  final bool isMobile;
  final int itemCount;

  const InboxHeader({
    Key? key,
    required this.isMobile,
    required this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, color: InboxColors.primary, size: isMobile ? 14 : 18),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                AppLocalizations.of(context)!.translate('inbox_requests'),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 14,
                  fontWeight: FontWeight.w600,
                  color: InboxColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: InboxColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: InboxColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('transactions_count').replaceAll('{count}', itemCount.toString()),
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: InboxColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}