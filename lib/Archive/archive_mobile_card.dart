import 'package:flutter/material.dart';
import 'archive_colors.dart';
import '../request/Ditalis_Request/ditalis_request.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../request/editerequest.dart';

class ArchiveMobileCardWidget extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String priority;
  final String date;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final int documentsCount;

  const ArchiveMobileCardWidget({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.date,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.documentsCount,
  });

  @override
  State<ArchiveMobileCardWidget> createState() =>
      _ArchiveMobileCardWidgetState();
}

class _ArchiveMobileCardWidgetState extends State<ArchiveMobileCardWidget> {
  bool _isPressed = false;

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return ArchiveColors.accentRed;
      case 'medium': return ArchiveColors.accentYellow;
      case 'low':    return ArchiveColors.accentGreen;
      default:       return ArchiveColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(widget.priority);

    String displayPriority = widget.priority;
    if (widget.priority.toLowerCase() == 'high') {
      displayPriority = AppLocalizations.of(context)!.translate('high');
    } else if (widget.priority.toLowerCase() == 'medium') {
      displayPriority = AppLocalizations.of(context)!.translate('medium');
    } else if (widget.priority.toLowerCase() == 'low') {
      displayPriority = AppLocalizations.of(context)!.translate('low');
    }

    return GestureDetector(
      onTapDown:  (_) => setState(() => _isPressed = true),
      onTapUp:    (_) => setState(() => _isPressed = false),
      onTapCancel: ()  => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  CourseApprovalRequestPage(requestId: widget.id)),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: ArchiveColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ArchiveColors.statShadow.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: widget.statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: widget.statusColor, width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.statusIcon,
                            color: widget.statusColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ArchiveColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge (no border — matches dashboard)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Date ──────────────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: ArchiveColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 13,
                          color: ArchiveColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Chips + menu ───────────────────────────────────
                  Row(
                    children: [
                      _buildChip(widget.type, Icons.category_outlined,
                          ArchiveColors.primary),
                      const SizedBox(width: 6),
                      _buildChip(displayPriority, Icons.flag_outlined,
                          priorityColor),
                      const SizedBox(width: 6),
                      _buildDocumentsChip(context),
                      const Spacer(),
                      _buildActionsMenu(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, IconData icon, Color color) {
    final display = text.length > 10 ? '${text.substring(0, 10)}...' : text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            display,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsChip(BuildContext context) {
    final color = widget.documentsCount > 0
        ? ArchiveColors.accentBlue
        : ArchiveColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            widget.documentsCount.toString(),
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18, color: ArchiveColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'view') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CourseApprovalRequestPage(requestId: widget.id)),
          );
        } else if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditRequestPage(requestId: widget.id)),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 16, color: ArchiveColors.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('view_details'),
                style: TextStyle(
                    fontSize: 12,
                    color: ArchiveColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 16, color: ArchiveColors.accentYellow),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('edit'),
                style: TextStyle(
                    fontSize: 12,
                    color: ArchiveColors.accentYellow,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Legacy wrapper
// ─────────────────────────────────────────────────────────────────────────────

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
  return ArchiveMobileCardWidget(
    id: id,
    title: title,
    type: type,
    priority: priority,
    date: date,
    statusText: statusText,
    statusColor: statusColor,
    statusIcon: statusIcon,
    documentsCount: documentsCount,
  );
}
