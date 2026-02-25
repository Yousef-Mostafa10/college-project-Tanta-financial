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
  required MyRequestsApi api, // Added api here
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

            // 2️⃣ التاريخ وعمليات التوجيه
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: MyRequestsColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(fontSize: 13, color: MyRequestsColors.textSecondary),
                ),
              ],
            ),
            
            // 🆕 إضافة مستطيل التوجيه هنا
            ForwardInfoWidget(transactionId: id, api: api),
            
            const SizedBox(height: 12),

            // 3️⃣ النوع والأولوية والمستندات
            Row(
              children: [
                _buildDesktopChip(type, Icons.category_outlined, MyRequestsColors.primary),
                const SizedBox(width: 8),
                _buildDesktopChip(displayPriority, priorityIcon, priorityColor),
                const SizedBox(width: 8),
                _buildDesktopChip(
                  '$documentsCount',
                  Icons.attach_file_rounded,
                  documentsCount > 0 ? MyRequestsColors.accentBlue : MyRequestsColors.textMuted,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: MyRequestsColors.textSecondary),
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
                    } else if (value == "track") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionTrackingPage(transactionId: id),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "details",
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 18, color: MyRequestsColors.primary),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.translate('view_details'), style: const TextStyle(fontSize: 14, color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: MyRequestsColors.primary),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.translate('edit_request'), style: const TextStyle(fontSize: 14, color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "track",
                      child: Row(
                        children: [
                          Icon(Icons.track_changes_outlined, size: 18, color: MyRequestsColors.primary),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.translate('track_request'), style: const TextStyle(fontSize: 14, color: MyRequestsColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 18, color: MyRequestsColors.accentRed),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.translate('delete_button'), style: const TextStyle(fontSize: 14, color: MyRequestsColors.accentRed)),
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

class ForwardInfoWidget extends StatefulWidget {
  final String transactionId;
  final MyRequestsApi api;

  const ForwardInfoWidget({Key? key, required this.transactionId, required this.api}) : super(key: key);

  @override
  State<ForwardInfoWidget> createState() => _ForwardInfoWidgetState();
}

class _ForwardInfoWidgetState extends State<ForwardInfoWidget> {
  String? receiverName;
  String? forwardId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    final data = await widget.api.fetchLastForwardData(widget.transactionId);
    if (mounted) {
      setState(() {
        receiverName = data?['receiverName'];
        forwardId = data?['forwardId'];
        isLoading = false;
      });
    }
  }

  Future<void> _onCancel() async {
    if (forwardId == null) return;

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
      final success = await widget.api.cancelForward(widget.transactionId, forwardId!);
      if (success) {
        if (mounted) {
          setState(() {
            receiverName = null;
            forwardId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_success') ?? 'Forward cancelled successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('forward_cancelled_failed') ?? 'Failed to cancel forward'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (receiverName == null) return const SizedBox.shrink();

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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix') ?? 'Forwarded to:'} $receiverName",
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
                    const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.translate('cancel_button') ?? 'Cancel', style: const TextStyle(color: Colors.red)),
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
