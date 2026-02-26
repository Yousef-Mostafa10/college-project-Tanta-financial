import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import '../Ditalis_Request/ditalis_request.dart';
import '../editerequest.dart';
import '../RequestTracking/request_tracking.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'my_requests_api.dart';

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
  required MyRequestsApi api,
  required VoidCallback onForward,
}) {
  return MyRequestMobileCard(
    id: id,
    title: title,
    type: type,
    priority: priority,
    date: date,
    statusText: statusText,
    statusColor: statusColor,
    statusIcon: statusIcon,
    documentsCount: documentsCount,
    onDelete: onDelete,
    api: api,
    onForward: onForward,
  );
}

class MyRequestMobileCard extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String priority;
  final String date;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;
  final int documentsCount;
  final Function(String) onDelete;
  final MyRequestsApi api;
  final VoidCallback onForward;

  const MyRequestMobileCard({
    Key? key,
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.date,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    required this.documentsCount,
    required this.onDelete,
    required this.api,
    required this.onForward,
  }) : super(key: key);

  @override
  State<MyRequestMobileCard> createState() => _MyRequestMobileCardState();
}

class _MyRequestMobileCardState extends State<MyRequestMobileCard> {
  String? receiverName;
  String? forwardId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForwardInfo();
  }

  Future<void> _fetchForwardInfo() async {
    final data = await widget.api.fetchLastForwardData(widget.id);
    if (mounted) {
      setState(() {
        receiverName = data?['receiverName'];
        forwardId = data?['forwardId'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color getPriorityColor(String priority) {
      switch (priority.toLowerCase()) {
        case 'high': return MyRequestsColors.accentRed;
        case 'medium': return MyRequestsColors.accentYellow;
        case 'low': return MyRequestsColors.accentGreen;
        default: return MyRequestsColors.textMuted;
      }
    }

    final priorityColor = getPriorityColor(widget.priority);
    final priorityIcon = _getPriorityIcon(widget.priority);

    String displayPriority = widget.priority;
    if (widget.priority.toLowerCase() == 'high') displayPriority = AppLocalizations.of(context)!.translate('priority_high') ?? 'High';
    else if (widget.priority.toLowerCase() == 'medium') displayPriority = AppLocalizations.of(context)!.translate('priority_medium') ?? 'Medium';
    else if (widget.priority.toLowerCase() == 'low') displayPriority = AppLocalizations.of(context)!.translate('priority_low') ?? 'Low';

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
                      color: widget.statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.statusColor.withOpacity(0.3)),
                    ),
                    child: Icon(widget.statusIcon, color: widget.statusColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
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
                      color: widget.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.statusColor,
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
                      widget.date,
                      style: TextStyle(fontSize: 11, color: MyRequestsColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(MyRequestsColors.primary.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '...',
                        style: TextStyle(fontSize: 10, color: MyRequestsColors.textMuted),
                      ),
                    ],
                  ),
                )
              else if (receiverName != null)
                ForwardInfoWidget(
                  transactionId: widget.id,
                  api: widget.api,
                  receiverName: receiverName,
                  forwardId: forwardId,
                  onCancelled: () {
                    setState(() {
                      receiverName = null;
                      forwardId = null;
                    });
                  },
                ),
              
              const SizedBox(height: 6),

              // النوع والأولوية والمستندات
              Row(
                children: [
                  _buildMobileChip(widget.type, Icons.category_outlined, MyRequestsColors.primary),
                  const SizedBox(width: 4),
                  _buildMobileChip(displayPriority, priorityIcon, priorityColor),
                  const SizedBox(width: 4),
                  _buildMobileChip(
                    '${widget.documentsCount}',
                    Icons.attach_file_rounded,
                    widget.documentsCount > 0 ? MyRequestsColors.accentBlue : MyRequestsColors.textMuted,
                  ),
                  const Spacer(),

                  // Forward Button
                  if (!isLoading && receiverName == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton.icon(
                        onPressed: widget.onForward,
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: Text(AppLocalizations.of(context)!.translate('forward') ?? 'Forward', style: const TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: MyRequestsColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: MyRequestsColors.primary.withOpacity(0.05),
                        ),
                      ),
                    ),

                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: MyRequestsColors.textSecondary),
                    onSelected: (value) {
                      if (value == "details") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseApprovalRequestPage(requestId: widget.id),
                          ),
                        );
                      } else if (value == "edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditRequestPage(requestId: widget.id),
                          ),
                        );
                      } else if (value == "delete") {
                        widget.onDelete(widget.id);
                      } else if (value == "track") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionTrackingPage(transactionId: widget.id),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "details",
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 16, color: MyRequestsColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('view_details') ?? 'View Details', style: const TextStyle(fontSize: 12, color: MyRequestsColors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: MyRequestsColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('edit_request') ?? 'Edit Request', style: const TextStyle(fontSize: 12, color: MyRequestsColors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "track",
                        child: Row(
                          children: [
                            Icon(Icons.track_changes_outlined, size: 16, color: MyRequestsColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('track_request') ?? 'Track Request', style: const TextStyle(fontSize: 12, color: MyRequestsColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete_outlined, size: 16, color: MyRequestsColors.accentRed),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.translate('delete_button') ?? 'Delete', style: const TextStyle(fontSize: 12, color: MyRequestsColors.accentRed)),
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
}

class ForwardInfoWidget extends StatefulWidget {
  final String transactionId;
  final MyRequestsApi api;
  final String? receiverName;
  final String? forwardId;
  final VoidCallback onCancelled;

  const ForwardInfoWidget({
    Key? key, 
    required this.transactionId, 
    required this.api,
    this.receiverName,
    this.forwardId,
    required this.onCancelled,
  }) : super(key: key);

  @override
  State<ForwardInfoWidget> createState() => _ForwardInfoWidgetState();
}

class _ForwardInfoWidgetState extends State<ForwardInfoWidget> {
  Future<void> _onCancel() async {
    if (widget.forwardId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('cancel_forward_confirm_title') ?? 'Confirm Cancel'),
        content: Text(AppLocalizations.of(context)!.translate('cancel_forward_confirm_content') ?? 'Are you sure you want to cancel this forward?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.translate('no') ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.translate('yes') ?? 'Yes', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.api.cancelForward(widget.transactionId, widget.forwardId!);
      if (success) {
        if (mounted) {
          widget.onCancelled();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_success') ?? 'Forward cancelled successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('failed_cancel_forward') ?? 'Failed to cancel forward'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.receiverName == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: MyRequestsColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MyRequestsColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.send_rounded, size: 12, color: MyRequestsColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix') ?? 'Forwarded to:'} ${widget.receiverName}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 16, color: MyRequestsColors.textSecondary),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'cancel') _onCancel();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.translate('cancel_button') ?? 'Cancel', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildMobileActionButton({
  required VoidCallback onPressed,
  required String text,
  required IconData icon,
  required Color color,
  bool isOutlined = false,
}) {
  return TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 14, color: color),
    label: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      backgroundColor: isOutlined ? Colors.transparent : color.withOpacity(0.08),
      side: isOutlined ? BorderSide(color: color, width: 1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
