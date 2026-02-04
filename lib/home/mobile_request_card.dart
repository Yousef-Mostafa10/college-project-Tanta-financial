// home/mobile_request_card.dart
import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';
import 'dashboard_helpers.dart';

class MobileRequestCard extends StatelessWidget {
  final String id;
  final String title;
  final String type;
  final String priority;
  final String creator;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onViewDetails;
  final VoidCallback onTrackRequest;
  final VoidCallback onDeleteRequest;

  const MobileRequestCard({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.creator,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.onViewDetails,
    required this.onTrackRequest,
    required this.onDeleteRequest,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = DashboardHelpers.getPriorityColor(priority);

    // Translate priority
    String displayPriority = priority;
    if (priority.toLowerCase() == 'high') displayPriority = AppLocalizations.of(context)!.translate('high');
    else if (priority.toLowerCase() == 'medium') displayPriority = AppLocalizations.of(context)!.translate('medium');
    else if (priority.toLowerCase() == 'low') displayPriority = AppLocalizations.of(context)!.translate('low');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: العنوان والحالة
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate(statusText.toLowerCase().replaceAll(' ', '_')),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // معلومات المرسل والنوع
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${AppLocalizations.of(context)!.translate('by')}: $creator",
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // النوع والأولوية
              Row(
                children: [
                  _buildChip(type, Icons.category_outlined, AppColors.primary),
                  const SizedBox(width: 6),
                  _buildChip(displayPriority, Icons.flag_outlined, priorityColor),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == "details") {
                        onViewDetails();
                      } else if (value == "track") {
                        onTrackRequest();
                      } else if (value == "delete") {
                        onDeleteRequest();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "details",
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('view_details'), style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "track",
                        child: Row(
                          children: [
                            Icon(Icons.track_changes_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('track_request'), style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete_outlined, size: 16, color: AppColors.accentRed),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('delete'), style: TextStyle(fontSize: 12, color: AppColors.accentRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text.length > 8 ? text.substring(0, 8) + '...' : text,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
