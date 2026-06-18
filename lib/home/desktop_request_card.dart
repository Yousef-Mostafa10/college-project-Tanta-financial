import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'dashboard_colors.dart';
import 'dashboard_helpers.dart';
import 'package:intl/intl.dart';

class DesktopRequestCard extends StatefulWidget {
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
  final VoidCallback onEditRequest; 
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
    required this.onEditRequest,
    required this.onDeleteRequest,
  });

  @override
  State<DesktopRequestCard> createState() => _DesktopRequestCardState();
}

class _DesktopRequestCardState extends State<DesktopRequestCard> {
  bool _isHovered = false;

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return dateString.length > 10 ? dateString.substring(0, 10) : dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = DashboardHelpers.getPriorityColor(widget.priority);
    final formattedDate = _formatDate(widget.createdAt);

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
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _isHovered ? (Matrix4.identity()..translate(0.0, -4.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? widget.statusColor.withOpacity(0.2) 
                  : AppColors.statShadow.withOpacity(0.05),
              blurRadius: _isHovered ? 20 : 10,
              spreadRadius: _isHovered ? 2 : 0,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: _isHovered ? widget.statusColor.withOpacity(0.5) : AppColors.borderColor,
            width: _isHovered ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.statusColor,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.statusIcon, color: widget.statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate(widget.statusText.toLowerCase().replaceAll(' ', '_')),
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
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildChip(widget.type, Icons.category_outlined, AppColors.primary),
                      const SizedBox(width: 8),
                      _buildChip(displayPriority, Icons.flag_outlined, priorityColor),
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
    final color = widget.documentsCount > 0 ? AppColors.accentBlue : AppColors.textMuted;
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
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == "details") widget.onViewDetails();
        else if (value == "track") widget.onTrackRequest();
        else if (value == "edit") widget.onEditRequest();
        else if (value == "delete") widget.onDeleteRequest();
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
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
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
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: "edit",
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.accentYellow),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('edit'),
                style: TextStyle(color: AppColors.accentYellow, fontWeight: FontWeight.w600),
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
                style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}