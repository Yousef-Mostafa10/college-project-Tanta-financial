import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import '../Ditalis_Request/ditalis_request.dart';
import '../editerequest.dart';
import '../RequestTracking/request_tracking.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'my_requests_api.dart';

Widget buildDesktopRequestCard({
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
  return MyRequestDesktopCard(
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

class MyRequestDesktopCard extends StatefulWidget {
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

  const MyRequestDesktopCard({
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
  State<MyRequestDesktopCard> createState() => _MyRequestDesktopCardState();
}

class _MyRequestDesktopCardState extends State<MyRequestDesktopCard> {
  bool _isHovered = false;
  String? receiverName;
  String? forwardId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForwardInfo();
  }

  @override
  void didUpdateWidget(MyRequestDesktopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.statusText != widget.statusText) {
      _fetchForwardInfo();
    }
  }

  Future<void> _fetchForwardInfo() async {
    setState(() => isLoading = true);
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: MyRequestsColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.statusColor.withOpacity(0.2)
                  : MyRequestsColors.statShadow.withOpacity(0.05),
              blurRadius:   _isHovered ? 20 : 10,
              spreadRadius: _isHovered ? 2  : 0,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: _isHovered
                ? widget.statusColor.withOpacity(0.5)
                : MyRequestsColors.borderColor,
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
                  // 1️⃣ Title + Status
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
                            color: MyRequestsColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

                  // 2️⃣ Date + Forward info
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: MyRequestsColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 13,
                          color: MyRequestsColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  MyRequestsColors.primary.withOpacity(0.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('...', style: TextStyle(
                              fontSize: 12,
                              color: MyRequestsColors.textMuted)),
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

                  const SizedBox(height: 16),

                  // 3️⃣ Chips + actions
                  Row(
                    children: [
                      _buildDesktopChip(widget.type,
                          Icons.category_outlined, MyRequestsColors.primary),
                      const SizedBox(width: 8),
                      _buildDesktopChip(
                          displayPriority, priorityIcon, priorityColor),
                      const SizedBox(width: 8),
                      _buildDesktopChip(
                        '${widget.documentsCount}',
                        Icons.attach_file_rounded,
                        widget.documentsCount > 0
                            ? MyRequestsColors.accentBlue
                            : MyRequestsColors.textMuted,
                      ),
                      const Spacer(),
                      if (!isLoading && receiverName == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextButton.icon(
                            onPressed: widget.onForward,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(AppLocalizations.of(context)!.translate('forward') ?? 'Forward'),
                            style: TextButton.styleFrom(
                              foregroundColor: MyRequestsColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor:
                                  MyRequestsColors.primary.withOpacity(0.05),
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            size: 20,
                            color: MyRequestsColors.textSecondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'details') {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    CourseApprovalRequestPage(
                                        requestId: widget.id)));
                          } else if (value == 'edit') {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) =>
                                    EditRequestPage(requestId: widget.id)));
                          } else if (value == 'delete') {
                            widget.onDelete(widget.id);
                          } else if (value == 'track') {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) =>
                                    TransactionTrackingPage(
                                        transactionId: widget.id)));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'details',
                            child: Row(children: [
                              Icon(Icons.remove_red_eye_outlined,
                                  size: 18, color: MyRequestsColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('view_details') ?? 'View Details',
                                style: TextStyle(
                                    color: MyRequestsColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  size: 18,
                                  color: MyRequestsColors.accentYellow),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('edit_request') ?? 'Edit',
                                style: TextStyle(
                                    color: MyRequestsColors.accentYellow,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'track',
                            child: Row(children: [
                              Icon(Icons.track_changes_outlined,
                                  size: 18, color: MyRequestsColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('track_request') ?? 'Track',
                                style: TextStyle(
                                    color: MyRequestsColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outlined,
                                  size: 18, color: MyRequestsColors.accentRed),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('delete_button') ?? 'Delete',
                                style: TextStyle(
                                    color: MyRequestsColors.accentRed,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                        ],
                      ),
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
            child: Text(AppLocalizations.of(context)!.translate('yes') ?? 'Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await widget.api.cancelForward(widget.transactionId, widget.forwardId!);
        if (success) {
          if (mounted) {
            widget.onCancelled();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_success') ?? 'Forward cancelled successfully'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errKey = e.toString().replaceAll('Exception: ', '');
          final errMsg = AppLocalizations.of(context)!.translate(errKey) ?? errKey;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: MyRequestsColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MyRequestsColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.send_rounded, size: 14, color: MyRequestsColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix') ?? 'Forwarded to:'} ${widget.receiverName}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: MyRequestsColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: MyRequestsColors.textSecondary),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'cancel') _onCancel();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.translate('cancel_button') ?? 'Cancel', style: TextStyle(color: Colors.red)),
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

Widget _buildDesktopActionButton({
  required VoidCallback onPressed,
  required String text,
  required IconData icon,
  required Color color,
  bool isOutlined = false,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16, color: isOutlined ? color : Colors.white),
    label: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isOutlined ? color : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: isOutlined ? Colors.transparent : color,
      side: isOutlined ? BorderSide(color: color, width: 1.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
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
        SizedBox(width: 6),
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
