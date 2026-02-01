// Notefecation/inbox_empty_state.dart
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';

class InboxEmptyState extends StatelessWidget {
  final VoidCallback onResetFilters;
  final String? customMessage;

  const InboxEmptyState({
    Key? key,
    required this.onResetFilters,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child:SingleChildScrollView(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: InboxColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate("no_requests_found"),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: InboxColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customMessage ?? AppLocalizations.of(context)!.translate("try_adjust_filters"),
                style: TextStyle(
                  fontSize: 12,
                  color: InboxColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate("reset_filters")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InboxColors.primary,
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
}