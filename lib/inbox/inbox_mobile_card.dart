import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
import './inbox_helpers.dart';
import './inbox_formatters.dart';

class InboxMobileCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onForward;
  final VoidCallback onCancelForward;
  final VoidCallback onNeedChange;
  final VoidCallback onEditRequest;
  final VoidCallback? onEditResponse;
  final bool hasForwarded;
  final bool isForwardChecking;

  const InboxMobileCard({
    Key? key,
    required this.request,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
    required this.onForward,
    required this.onCancelForward,
    required this.hasForwarded,
    required this.onNeedChange,
    required this.onEditRequest,
    this.onEditResponse,
    this.isForwardChecking = false,
  }) : super(key: key);

  @override
  State<InboxMobileCard> createState() => _InboxMobileCardState();
}

class _InboxMobileCardState extends State<InboxMobileCard> {
  bool _isPressed = false;

  Widget _buildMobileChip(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.translate(text.toLowerCase()),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      );
    }

    if (isOutlined) {
      return Expanded(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: const Size(0, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.request["title"] ?? AppLocalizations.of(context)!.translate('no_title');
    final type = widget.request["type"]?["name"] ?? AppLocalizations.of(context)!.translate('n_a');
    final priority = widget.request["priority"] ?? AppLocalizations.of(context)!.translate('n_a');
    final createdAt = widget.request["createdAt"];
    final formattedDate = InboxFormatters.formatDate(context, createdAt);
    final forwardStatus = (widget.request['yourCurrentStatus'] ?? 'not-assigned').toString().toLowerCase();
    final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned' || forwardStatus == 'pending';
    final isApproved = forwardStatus == 'approved';
    final isRejected = forwardStatus == 'rejected';
    final needsChange = forwardStatus == 'needs_change' || forwardStatus == 'needs_editing' || forwardStatus == 'needs-editing';
    final fulfilled = widget.request["fulfilled"] == true;
    final isUpdating = widget.request['isUpdating'] == true;
    final documentsCount = widget.request["documentsCount"] ?? (widget.request["documents"] as List?)?.length ?? 0;
    
    final statusLabel = fulfilled
        ? AppLocalizations.of(context)!.translate('fulfilled')
        : (isApproved 
            ? AppLocalizations.of(context)!.translate('approved') 
            : (needsChange 
                ? AppLocalizations.of(context)!.translate('needs_change') 
                : (isPending 
                    ? AppLocalizations.of(context)!.translate('waiting') 
                    : AppLocalizations.of(context)!.translate('rejected'))));
                    
    final statusColor = fulfilled
        ? AppColors.statusFulfilled
        : (isApproved
            ? AppColors.statusApproved
            : (needsChange ? Colors.orange : (isPending ? AppColors.statusWaiting : AppColors.statusRejected)));
            
    final lastForwardSentTo = widget.request['lastForwardSentTo'];

    final showProcessingButtons = isPending && !widget.hasForwarded;
    final showForwardButton = !isPending && !widget.hasForwarded;

    IconData getStatusIcon() {
      if (fulfilled) return Icons.check_rounded;
      if (isApproved) return Icons.check_circle_rounded;
      if (isRejected) return Icons.cancel_rounded;
      if (needsChange) return Icons.edit_note_rounded;
      return Icons.hourglass_empty_rounded;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        transform: _isPressed ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.statShadow.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Title and status icon/label
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(getStatusIcon(), color: statusColor, size: 18),
                          ),
                          if (isUpdating)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 6,
                                    height: 6,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isUpdating)
                              Text(
                                AppLocalizations.of(context)!.translate('updating'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Created Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 13, 
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMobileChip(context, type, Icons.category_outlined, AppColors.primary),
                      _buildMobileChip(context, priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (documentsCount > 0 ? AppColors.accentBlue : AppColors.textMuted).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file_rounded, 
                              size: 13, 
                              color: documentsCount > 0 ? AppColors.accentBlue : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$documentsCount",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: documentsCount > 0 ? AppColors.accentBlue : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons section
                  if (widget.isForwardChecking) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.6)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '...',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isUpdating) ...[
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.translate('updating'),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (showProcessingButtons) ...[
                    Column(
                      children: [
                        Row(
                          children: [
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('reject'),
                              onPressed: widget.onReject,
                              color: AppColors.statusRejected,
                            ),
                            const SizedBox(width: 6),
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('approve'),
                              onPressed: widget.onApprove,
                              color: AppColors.statusApproved,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('need_change'),
                              onPressed: widget.onNeedChange,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('view'),
                              onPressed: widget.onViewDetails,
                              color: AppColors.primary,
                              isOutlined: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else if (widget.hasForwarded) ...[
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bodyBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.dividerColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.send_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${AppLocalizations.of(context)!.translate('forwarded_to_prefix')} ${lastForwardSentTo != null ? (lastForwardSentTo['receiverName'] ?? '') : ''}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textSecondary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'cancel',
                                    child: Text(AppLocalizations.of(context)!.translate('cancel_forward')),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'cancel') widget.onCancelForward();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('edit'),
                              onPressed: widget.onEditRequest,
                              color: Colors.blue,
                              isOutlined: true,
                            ),
                            const SizedBox(width: 6),
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('view'),
                              onPressed: widget.onViewDetails,
                              color: AppColors.primary,
                              isOutlined: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else if (showForwardButton) ...[
                    Column(
                      children: [
                        Row(
                          children: [
                            if (widget.onEditResponse != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onEditResponse,
                                  icon: const Icon(Icons.edit_rounded, size: 14),
                                  label: Text(
                                    AppLocalizations.of(context)!.translate('edit_response'), 
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                    side: const BorderSide(color: Colors.deepPurple),
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.onEditResponse != null) const SizedBox(width: 6),
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('forward'),
                              onPressed: widget.onForward,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('edit'),
                              onPressed: widget.onEditRequest,
                              color: Colors.blue,
                              isOutlined: true,
                            ),
                            const SizedBox(width: 6),
                            _buildMobileActionButton(
                              text: AppLocalizations.of(context)!.translate('view_details'),
                              onPressed: widget.onViewDetails,
                              color: AppColors.primary,
                              isOutlined: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      children: [
                        if (widget.onEditResponse != null && !isPending)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onEditResponse,
                                icon: const Icon(Icons.edit_rounded, size: 14),
                                label: Text(
                                  AppLocalizations.of(context)!.translate('edit_response'), 
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  side: const BorderSide(color: Colors.deepPurple),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onEditRequest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('edit_request'), 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onViewDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusFulfilled,
                              side: BorderSide(color: AppColors.statusFulfilled),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('view_details'), 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}