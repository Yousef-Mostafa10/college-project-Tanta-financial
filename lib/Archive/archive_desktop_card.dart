import 'package:flutter/material.dart';
import 'archive_colors.dart';
import '../request/Ditalis_Request/ditalis_request.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../request/editerequest.dart';

class ArchiveDesktopCardWidget extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String priority;
  final String date;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final int documentsCount;

  const ArchiveDesktopCardWidget({
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
  State<ArchiveDesktopCardWidget> createState() =>
      _ArchiveDesktopCardWidgetState();
}

class _ArchiveDesktopCardWidgetState extends State<ArchiveDesktopCardWidget> {
  bool _isHovered = false;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: ArchiveColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.statusColor.withOpacity(0.2)
                  : ArchiveColors.statShadow.withOpacity(0.05),
              blurRadius:   _isHovered ? 20 : 10,
              spreadRadius: _isHovered ? 2  : 0,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: _isHovered
                ? widget.statusColor.withOpacity(0.5)
                : ArchiveColors.borderColor,
            width: _isHovered ? 1.5 : 1.0,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.statusIcon,
                            color: widget.statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ArchiveColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: widget.statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Date ─────────────────────────────────────────────
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
                  const SizedBox(height: 16),

                  // ── Chips + menu ─────────────────────────────────────
                  Row(
                    children: [
                      _buildChip(widget.type, Icons.category_outlined,
                          ArchiveColors.primary),
                      const SizedBox(width: 8),
                      _buildChip(displayPriority, Icons.flag_outlined,
                          priorityColor),
                      const SizedBox(width: 8),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
    final text = widget.documentsCount > 0
        ? '${widget.documentsCount} ${widget.documentsCount == 1 ? AppLocalizations.of(context)!.translate('file') : AppLocalizations.of(context)!.translate('files')}'
        : AppLocalizations.of(context)!.translate('no_attachments');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 20, color: ArchiveColors.textSecondary),
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
                  size: 18, color: ArchiveColors.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('view_details'),
                style: TextStyle(
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
                  size: 18, color: ArchiveColors.accentYellow),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('edit'),
                style: TextStyle(
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
//  Legacy function wrapper
// ─────────────────────────────────────────────────────────────────────────────

Widget buildArchiveDesktopCard({
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
  return ArchiveDesktopCardWidget(
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
