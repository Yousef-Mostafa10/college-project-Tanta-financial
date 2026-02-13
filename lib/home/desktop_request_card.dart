import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';
import 'dashboard_helpers.dart';

class DesktopRequestCard extends StatelessWidget {
  final String id;
  final String title;
  final String type;
  final String priority;
  final String creator;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final int documentsCount;
  final String createdAt;
  final VoidCallback onViewDetails;
  final VoidCallback onTrackRequest;
  final VoidCallback onEditRequest; // ✅ زر تعديل
  final VoidCallback onDeleteRequest;

  const DesktopRequestCard({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.creator,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.documentsCount,
    required this.createdAt,
    required this.onViewDetails,
    required this.onTrackRequest,
    required this.onEditRequest, // ✅
    required this.onDeleteRequest,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}'; // ✅ التاريخ الفعلي دائماً
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = DashboardHelpers.getPriorityColor(priority);
    final formattedDate = _formatDate(createdAt);

    // Translate priority
    String displayPriority = priority;
    if (priority.toLowerCase() == 'high') {
      displayPriority = AppLocalizations.of(context)!.translate('high');
    } else if (priority.toLowerCase() == 'medium') {
      displayPriority = AppLocalizations.of(context)!.translate('medium');
    } else if (priority.toLowerCase() == 'low') {
      displayPriority = AppLocalizations.of(context)!.translate('low');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBg,
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
                      color: AppColors.textPrimary,
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
                    AppLocalizations.of(context)!.translate(statusText.toLowerCase().replaceAll(' ', '_')),
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

            // 2️⃣ معلومات المرسل والتاريخ
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  "${AppLocalizations.of(context)!.translate('by')}: $creator",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3️⃣ النوع والأولوية وعدد المستندات
            Row(
              children: [
                _buildChip(type, Icons.category_outlined, AppColors.primary),
                const SizedBox(width: 8),
                _buildChip(displayPriority, Icons.flag_outlined, priorityColor),
                const SizedBox(width: 8),
                _buildDocumentsChip(),
                const Spacer(),

                // 4️⃣ أزرار الإجراءات
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == "details") {
                      onViewDetails();
                    } else if (value == "track") {
                      onTrackRequest();
                    } else if (value == "edit") {      // ✅ زر تعديل
                      onEditRequest();
                    } else if (value == "delete") {
                      onDeleteRequest();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "details",
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('view_details'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "track",
                      child: Row(
                        children: [
                          Icon(Icons.track_changes_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('track_request'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(                      // ✅ زر تعديل
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.accentYellow),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('edit'),
                            style: TextStyle(color: AppColors.accentYellow),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 18, color: AppColors.accentRed),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('delete'),
                            style: TextStyle(color: AppColors.accentRed),
                          ),
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
    );
  }

  Widget _buildChip(String text, IconData icon, Color color) {
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

  Widget _buildDocumentsChip() {
    final color = documentsCount > 0 ? AppColors.primary : AppColors.textMuted;
    final text = documentsCount > 0
        ? '$documentsCount ${documentsCount == 1 ? 'ملف' : 'ملفات'}'
        : 'لا يوجد مرفقات';

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
          Icon(Icons.attach_file_rounded, size: 14, color: color),
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
}