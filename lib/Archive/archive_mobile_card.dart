import 'package:flutter/material.dart';
import 'archive_colors.dart';
import '../request/Ditalis_Request/ditalis_request.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../request/editerequest.dart';

Widget buildArchiveMobileCard({
  required String id,
  required String title,
  required String type,
  required String priority,
  required String date,
  required String statusText,
  required Color statusColor,
  required IconData statusIcon,
  required int documentsCount,
  required BuildContext context,
}) {
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return ArchiveColors.accentRed;
      case 'medium':
        return ArchiveColors.accentYellow;
      case 'low':
        return ArchiveColors.accentGreen;
      default:
        return ArchiveColors.textMuted;
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      color: ArchiveColors.cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseApprovalRequestPage(requestId: id),
            ),
          );
        },
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
                    child: Icon(statusIcon, color: statusColor, size: 18), // 16 -> 18
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ArchiveColors.textPrimary,
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
                  Icon(Icons.calendar_today_rounded, size: 14, color: ArchiveColors.textSecondary), // 12 -> 14
                  const SizedBox(width: 6), // 4 -> 6
                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(fontSize: 13, color: ArchiveColors.textSecondary), // 11 -> 13
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // النوع والأولوية والمستندات وزر التفاصيل
              Row(
                children: [
                  _buildMobileChip(type, Icons.category_outlined, ArchiveColors.primary),
                  const SizedBox(width: 6),
                  _buildMobileChip(displayPriority, priorityIcon, priorityColor),
                  const SizedBox(width: 6),
                  _buildMobileChip(
                    '$documentsCount',
                    Icons.attach_file_rounded,
                    documentsCount > 0 ? ArchiveColors.accentBlue : ArchiveColors.textMuted,
                  ),
                  const Spacer(),
                  // القائمة المنبثقة (الثلاث نقاط)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditRequestPage(requestId: id),
                          ),
                        );
                      } else if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseApprovalRequestPage(requestId: id),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 20, color: ArchiveColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.translate('view_details'),
                              style: TextStyle(fontSize: 14, color: ArchiveColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20, color: ArchiveColors.accentYellow),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.translate('edit'),
                              style: TextStyle(fontSize: 14, color: ArchiveColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ArchiveColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ArchiveColors.primary.withOpacity(0.1)),
                      ),
                      child: Icon(Icons.more_vert_rounded, color: ArchiveColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildMobileChip(String text, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 6,2 -> 8,4
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color), // 10 -> 13
        const SizedBox(width: 4), // 2 -> 4
        Text(
          text.length > 8 ? text.substring(0, 8) + '...' : text, // 6 -> 8
          style: TextStyle(
            fontSize: 11, // 9 -> 11
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
