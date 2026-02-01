import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import '../Ditalis_Request/ditalis_request.dart';
import '../editerequest.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildDesktopRequestCard({
  required String id,
  required String title,
  required String type,
  required String priority,
  required String date,
  required String statusText,
  required Color statusColor,
  required IconData statusIcon,
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
    margin: const EdgeInsets.only(bottom: 12),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: MyRequestsColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1️⃣ الصف العلوي: العنوان والحالة
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyRequestsColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2️⃣ التاريخ
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: MyRequestsColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(fontSize: 13, color: MyRequestsColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3️⃣ النوع والأولوية والأزرار
            Row(
              children: [
                _buildDesktopChip(type, Icons.category_outlined, MyRequestsColors.primary),
                const SizedBox(width: 8),
                _buildDesktopChip(displayPriority, priorityIcon, priorityColor),
                const Spacer(),

                // 4️⃣ أزرار الإجراءات
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: MyRequestsColors.textSecondary),
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
                          Icon(Icons.remove_red_eye_outlined, size: 18, color: MyRequestsColors.primary),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('view_details'), style: TextStyle(color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: MyRequestsColors.primary),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('edit_request'), style: TextStyle(color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 18, color: MyRequestsColors.accentRed),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('delete_button'), style: TextStyle(color: MyRequestsColors.accentRed)),
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

Widget _buildDesktopChip(String text, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
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