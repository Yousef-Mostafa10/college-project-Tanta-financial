import 'package:flutter/material.dart';
import 'package:college_project/l10n/app_localizations.dart';
import './inbox_colors.dart';
import './inbox_helpers.dart';
import './inbox_formatters.dart';

class InboxMobileCard extends StatelessWidget {
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

  Widget _buildMobileChip(BuildContext context, String text, IconData icon, Color color) {
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
              AppLocalizations.of(context)!.translate(text.toLowerCase()),
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ));
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
          ),
          child: Text(text, style: const TextStyle(fontSize: 11)),
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
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = request["id"].toString();
    final title = request["title"] ?? AppLocalizations.of(context)!.translate('no_title');
    final type = request["type"]?["name"] ?? AppLocalizations.of(context)!.translate('n_a');
    final priority = request["priority"] ?? AppLocalizations.of(context)!.translate('n_a');
    final senderName = request["lastSenderName"] ?? request["creator"]?["name"] ?? AppLocalizations.of(context)!.translate('unknown');
    final createdAt = request["createdAt"];
    final formattedDate = InboxFormatters.formatDate(context, createdAt);
    final forwardStatus = (request['yourCurrentStatus'] ?? 'not-assigned').toString().toLowerCase();
    final isPending = forwardStatus == 'waiting' || forwardStatus == 'not-assigned' || forwardStatus == 'pending';
    final isApproved = forwardStatus == 'approved';
    final isRejected = forwardStatus == 'rejected';
    final needsChange = forwardStatus == 'needs_change' || forwardStatus == 'needs_editing' || forwardStatus == 'needs-editing';
    final fulfilled = request["fulfilled"] == true;
    final isUpdating = request['isUpdating'] == true;
    final documentsCount = request["documentsCount"] ?? (request["documents"] as List?)?.length ?? 0;
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
        ? InboxColors.statusFulfilled
        : (isApproved
        ? InboxColors.statusApproved
        : (needsChange ? Colors.orange : (isPending ? InboxColors.statusWaiting : InboxColors.statusRejected)));
    final lastForwardSentTo = request['lastForwardSentTo'];

    // 🔹 تحديد ما إذا كان يجب إظهار أزرار المعالجة (الموافقة/الرفض/طلب التعديل)
    // تظهر هذه الأزرار عندما تكون العملية في حالة pending وتعود إليك (لست المرسل الأخير)
    final showProcessingButtons = isPending && !hasForwarded;

    // 🔹 تحديد ما إذا كان يجب إظهار زر Forward
    // يظهر هذا الزر عندما تكون العملية ليست في حالة pending (موافق/مرفوض/طلب تعديل/مكتمل)
    // ولا يوجد توجيه نشط
    final showForwardButton = !isPending && !hasForwarded;

    IconData getStatusIcon() {
      if (fulfilled) return Icons.check_rounded;
      if (isApproved) return Icons.check_circle_rounded;
      if (isRejected) return Icons.cancel_rounded;
      if (needsChange) return Icons.edit_note_rounded;
      return Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: InboxColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: العنوان والحالة
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Icon(getStatusIcon(), color: statusColor, size: 16),
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
                            fontWeight: FontWeight.w600,
                            color: InboxColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUpdating)
                          Text(
                            AppLocalizations.of(context)!.translate('updating'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUpdating)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        if (isUpdating) const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 6),

              // التاريخ
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: InboxColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedDate.length > 16 ? formattedDate.substring(0, 16) : formattedDate,
                      style: TextStyle(fontSize: 11, color: InboxColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  _buildMobileChip(context, type, Icons.category_outlined, InboxColors.primary),
                  const SizedBox(width: 6),
                  _buildMobileChip(context, priority, Icons.flag_outlined, InboxHelpers.getPriorityColor(priority)),
                  const SizedBox(width: 6),
                  // عدد الملفات
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: InboxColors.textSecondary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: InboxColors.textSecondary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file_rounded, size: 12, color: InboxColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          documentsCount > 0 
                              ? "$documentsCount" 
                              : AppLocalizations.of(context)!.translate('no_attachments'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: InboxColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // أزرار الإجراءات
              if (isForwardChecking) ...[
                // 🔹 حالة: جاري التحقق من حالة الـ forward
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
                          valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '...',
                        style: TextStyle(fontSize: 11, color: InboxColors.textMuted),
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
                          valueColor: AlwaysStoppedAnimation<Color>(InboxColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.translate('updating'),
                        style: TextStyle(
                          color: InboxColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (showProcessingButtons) ...[
                // 🔹 أزرار المعالجة (عندما تعود العملية إليك في حالة pending)
                Column(
                  children: [
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('reject'),
                          onPressed: onReject,
                          color: InboxColors.accentRed,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('approve'),
                          onPressed: onApprove,
                          color: InboxColors.accentGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('need_change'),
                          onPressed: onNeedChange,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('view'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (hasForwarded) ...[
                // 🔹 حالة: أنت أرسلت العملية لشخص آخر (أنت المرسل الأخير)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: InboxColors.bodyBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: InboxColors.statBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.send_rounded, size: 14, color: InboxColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${AppLocalizations.of(context)!.translate('forwarded_to_prefix')} ${lastForwardSentTo['receiverName']}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: InboxColors.textPrimary,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 16, color: InboxColors.textSecondary),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text(AppLocalizations.of(context)!.translate('cancel_forward')),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'cancel') onCancelForward();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // فقط أزرار Edit و View
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('edit'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('view'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (showForwardButton) ...[
                // 🔹 حالة: العملية في حالة نهائية (موافق/مرفوض/طلب تعديل/مكتمل) ويمكن التوجيه
                Column(
                  children: [
                    Row(
                      children: [
                        if (onEditResponse != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEditResponse,
                              icon: Icon(Icons.edit_rounded, size: 14),
                              label: Text(AppLocalizations.of(context)!.translate('edit_response') ?? 'Edit Response', style: const TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                side: BorderSide(color: Colors.deepPurple),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: const Size(0, 30),
                              ),
                            ),
                          ),
                        if (onEditResponse != null) const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('forward'),
                          onPressed: onForward,
                          color: InboxColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('edit'),
                          onPressed: onEditRequest,
                          color: Colors.blue,
                          isOutlined: true,
                        ),
                        const SizedBox(width: 6),
                        _buildMobileActionButton(
                          text: AppLocalizations.of(context)!.translate('view_details'),
                          onPressed: onViewDetails,
                          color: InboxColors.primary,
                          isOutlined: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // 🔹 الحالات الأخرى
                Column(
                  children: [
                    if (onEditResponse != null && !isPending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onEditResponse,
                            icon: Icon(Icons.edit_rounded, size: 14),
                            label: Text(AppLocalizations.of(context)!.translate('edit_response') ?? 'Edit Response', style: const TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: BorderSide(color: Colors.deepPurple),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 30),
                            ),
                          ),
                        ),
                      ),
                    // زر Edit Request
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onEditRequest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('edit_request'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // زر View Details
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: InboxColors.statusFulfilled,
                          side: BorderSide(color: InboxColors.statusFulfilled),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(AppLocalizations.of(context)!.translate('view_details'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}