import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import '../Ditalis_Request/ditalis_request.dart';
import '../editerequest.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildMobileRequestCard({
  required String id,
  required String title,
  required String type,
  required String priority,
  required String date,
  required String statusText,
  required Color statusColor,
  required IconData statusIcon,
  required int documentsCount,
  required Function(String) onDelete,
  required BuildContext context,
}) {
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return MyRequestsColors.accentRed;
      case 'medium':
        return MyRequestsColors.accentYellow;
      case 'low':
        return MyRequestsColors.accentGreen;
      default:
        return MyRequestsColors.textMuted;
    }
  }

  final priorityColor = getPriorityColor(priority);
  final priorityIcon = _getPriorityIcon(priority);

  String displayPriority = priority;
  if (priority.toLowerCase() == 'high') displayPriority = AppLocalizations.of(context)!.translate('priority_high');
  else if (priority.toLowerCase() == 'medium') displayPriority = AppLocalizations.of(context)!.translate('priority_medium');
  else if (priority.toLowerCase() == 'low') displayPriority = AppLocalizations.of(context)!.translate('priority_low');

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: MyRequestsColors.cardBg,
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
                      color: MyRequestsColors.textPrimary,
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
                    statusText,
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

            // التاريخ
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: MyRequestsColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(fontSize: 11, color: MyRequestsColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // النوع والأولوية والمستندات
            Row(
              children: [
                _buildMobileChip(type, Icons.category_outlined, MyRequestsColors.primary),
                const SizedBox(width: 6),
                _buildMobileChip(displayPriority, priorityIcon, priorityColor),
                const SizedBox(width: 6),
                // 📎 أيقونة المستندات
                _buildMobileChip(
                  '$documentsCount',
                  Icons.attach_file_rounded,
                  documentsCount > 0 ? MyRequestsColors.accentBlue : MyRequestsColors.textMuted,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 16, color: MyRequestsColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == "details") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseApprovalRequestPage(requestId: id),
                        ),
                      );
                    } else if (value == "edit") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRequestPage(requestId: id),
                        ),
                      );
                    } else if (value == "delete") {
                      onDelete(id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "details",
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 16, color: MyRequestsColors.primary),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('view_details'), style: TextStyle(fontSize: 12, color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: MyRequestsColors.primary),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('edit_request'), style: TextStyle(fontSize: 12, color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 16, color: MyRequestsColors.accentRed),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('delete_button'), style: TextStyle(fontSize: 12, color: MyRequestsColors.accentRed)),
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

Widget _buildMobileChip(String text, IconData icon, Color color) {
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
          text.length > 6 ? text.substring(0, 6) + '...' : text,
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

IconData _getPriorityIcon(String priority) {
  switch (priority.toLowerCase()) {
    case 'high': return Icons.warning_amber_rounded;
    case 'medium': return Icons.info_rounded;
    case 'low': return Icons.flag_rounded;
    default: return Icons.flag_rounded;
  }
}