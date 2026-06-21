import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_project/core/app_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_theme_color.dart';
import 'package:college_project/request/Ditalis_Request/ditalis_request.dart';
import 'notifications_provider.dart';

class NotificationsPage extends StatefulWidget {
  final bool isAdmin;
  const NotificationsPage({super.key, this.isAdmin = false});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh notifications when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getNotificationIcon(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toUpperCase();
    final code = notification['code']?.toString().toUpperCase();
    final args = notification['args'] as Map? ?? {};
    final status = args['status']?.toString().toUpperCase();

    if (code == 'REQUEST_REJECTED') return Icons.cancel_rounded;
    if (code == 'REQUEST_APPROVED') return Icons.check_circle_rounded;
    if (code == 'TRANSACTION_FORWARD_RESPONDED') {
      if (status == 'REJECTED') return Icons.cancel_rounded;
      if (status == 'APPROVED') return Icons.check_circle_rounded;
      if (status == 'NEEDS_EDITING') return Icons.edit_rounded;
    }

    switch (type) {
      case 'BUDGET':
        return Icons.account_balance_wallet_rounded;
      case 'REQUEST':
        return Icons.description_rounded;
      case 'APPROVAL':
        return Icons.check_circle_rounded;
      case 'REJECTION':
        return Icons.cancel_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toUpperCase();
    final code = notification['code']?.toString().toUpperCase();
    final args = notification['args'] as Map? ?? {};
    final status = args['status']?.toString().toUpperCase();

    if (code == 'REQUEST_REJECTED') return AppColors.accentRed;
    if (code == 'REQUEST_APPROVED') return AppColors.accentGreen;
    if (code == 'TRANSACTION_FORWARD_RESPONDED') {
      if (status == 'REJECTED') return AppColors.accentRed;
      if (status == 'APPROVED') return AppColors.accentGreen;
      if (status == 'NEEDS_EDITING') return AppColors.accentOrange;
    }

    switch (type) {
      case 'BUDGET':
        return AppColors.accentYellow;
      case 'REQUEST':
        return AppColors.accentBlue;
      case 'APPROVAL':
        return AppColors.accentGreen;
      case 'REJECTION':
        return AppColors.accentRed;
      case 'WARNING':
        return AppColors.accentOrange;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(BuildContext context, String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      final local = AppLocalizations.of(context)!;
      if (diff.inMinutes < 1) return local.translate('now');
      if (diff.inHours < 1) return local.translate('minutes_ago').replaceAll('{minutes}', '${diff.inMinutes}');
      if (diff.inDays < 1) return local.translate('hours_ago').replaceAll('{hours}', '${diff.inHours}');
      if (diff.inDays < 7) return local.translate('days_ago').replaceAll('{days}', '${diff.inDays}');
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _getArgValue(dynamic arg) {
    if (arg == null) return '';
    if (arg is Map) {
      return arg['name']?.toString() ?? arg['title']?.toString() ?? arg['id']?.toString() ?? '';
    }
    return arg.toString();
  }

  String _buildMessage(BuildContext context, dynamic notification) {
    final code = notification['code']?.toString() ?? '';
    final args = notification['args'] as Map? ?? {};
    final local = AppLocalizations.of(context)!;

    switch (code) {
      case 'BUDGET_ALLOCATION_OVERFLOW_ATTEMPT':
        final cat = args['categoryName'] ?? args['budgetName'] ?? local.translate('unknown');
        final avail = args['availableAmount'] ?? args['available'] ?? '0';
        final req = args['requestedAmount'] ?? args['requested'] ?? '0';
        final user = args['attemptedBy'] ?? local.translate('unknown');
        final transaction = args['transactionId'] ?? local.translate('unknown');
        return local.translate('BUDGET_ALLOCATION_OVERFLOW_ATTEMPT')
            .replaceAll('{categoryName}', cat.toString())
            .replaceAll('{attemptedBy}', user.toString())
            .replaceAll('{transactionId}', transaction.toString())
            .replaceAll('{availableAmount}', avail.toString())
            .replaceAll('{requestedAmount}', req.toString());
      case 'INSUFFICIENT_BUDGET':
        final cat = args['categoryName'] ?? '';
        final avail = args['availableAmount'] ?? '0';
        final req = args['requestedAmount'] ?? '0';
        return local.translate('INSUFFICIENT_BUDGET')
            .replaceAll('{categoryName}', cat.toString())
            .replaceAll('{availableAmount}', avail.toString())
            .replaceAll('{requestedAmount}', req.toString());
      case 'REQUEST_APPROVED':
        final title = _getArgValue(args['transactionTitle'] ?? args['title'] ?? args['transactionName'] ?? args['transaction']);
        final id = _getArgValue(args['transactionId']);
        if (title.isNotEmpty || id.isNotEmpty) {
          final isAr = AppLocalizations.of(context)!.locale.languageCode == 'ar';
          if (isAr) {
            return 'تمت الموافقة على طلبك' + (title.isNotEmpty ? ' "$title"' : ' رقم ($id)');
          } else {
            return 'Your request' + (title.isNotEmpty ? ' "$title"' : ' ID: $id') + ' was approved';
          }
        }
        return local.translate('REQUEST_APPROVED');
      case 'REQUEST_REJECTED':
        final title = _getArgValue(args['transactionTitle'] ?? args['title'] ?? args['transactionName'] ?? args['transaction']);
        final id = _getArgValue(args['transactionId']);
        final reason = args['reason']?.toString() ?? '';
        if (title.isNotEmpty || id.isNotEmpty || reason.isNotEmpty) {
          final isAr = AppLocalizations.of(context)!.locale.languageCode == 'ar';
          if (isAr) {
            String msg = 'تم رفض طلبك';
            if (title.isNotEmpty) msg += ' "$title"';
            else if (id.isNotEmpty) msg += ' رقم ($id)';
            if (reason.isNotEmpty) msg += ': $reason';
            return msg;
          } else {
            String msg = 'Your request';
            if (title.isNotEmpty) msg += ' "$title"';
            else if (id.isNotEmpty) msg += ' ID: $id';
            msg += ' was rejected';
            if (reason.isNotEmpty) msg += ': $reason';
            return msg;
          }
        }
        return local.translate('REQUEST_REJECTED');
      case 'TRANSACTION_FORWARD_RECEIVED':
        final sender = _getArgValue(args['senderName'] ?? args['sender'] ?? args['forwardedBy']);
        final title = _getArgValue(args['transactionTitle'] ?? args['title'] ?? args['transactionName'] ?? args['transaction']);
        final id = _getArgValue(args['transactionId']);
        
        if (sender.isNotEmpty || title.isNotEmpty || id.isNotEmpty) {
          final isAr = AppLocalizations.of(context)!.locale.languageCode == 'ar';
          if (isAr) {
            String details = 'تم توجيه معاملة إليك';
            if (sender.isNotEmpty) details += ' من $sender';
            if (title.isNotEmpty) details += ' بخصوص "$title"';
            if (id.isNotEmpty && title.isEmpty) details += ' رقم ($id)';
            return details;
          } else {
            String details = 'A transaction was forwarded to you';
            if (sender.isNotEmpty) details += ' by $sender';
            if (title.isNotEmpty) details += ' regarding "$title"';
            if (id.isNotEmpty && title.isEmpty) details += ' ID: $id';
            return details;
          }
        }
        return local.translate('TRANSACTION_FORWARD_RECEIVED');
      case 'TRANSACTION_FORWARD_RESPONDED':
        final responder = _getArgValue(args['responderName'] ?? args['responder'] ?? args['receiverName'] ?? args['receiver']);
        final title = _getArgValue(args['transactionTitle'] ?? args['title'] ?? args['transactionName'] ?? args['transaction']);
        final id = _getArgValue(args['transactionId']);
        final status = _getArgValue(args['status']);
        
        if (responder.isNotEmpty || title.isNotEmpty || id.isNotEmpty || status.isNotEmpty) {
          final isAr = AppLocalizations.of(context)!.locale.languageCode == 'ar';
          String statusText = status;
          if (isAr) {
            if (status.toUpperCase() == 'APPROVED') statusText = 'موافقة';
            else if (status.toUpperCase() == 'REJECTED') statusText = 'رفض';
            else if (status.toUpperCase() == 'NEEDS_EDITING') statusText = 'طلب تعديل';
            
            String details = 'تم الرد على معاملة موجهة';
            if (responder.isNotEmpty) details += ' من قِبل $responder';
            if (statusText.isNotEmpty) details += ' بـ ($statusText)';
            if (title.isNotEmpty) details += ' بخصوص "$title"';
            if (id.isNotEmpty && title.isEmpty) details += ' رقم ($id)';
            return details;
          } else {
            String details = 'A forwarded transaction was responded to';
            if (responder.isNotEmpty) details += ' by $responder';
            if (statusText.isNotEmpty) details += ' with $statusText';
            if (title.isNotEmpty) details += ' regarding "$title"';
            if (id.isNotEmpty && title.isEmpty) details += ' ID: $id';
            return details;
          }
        }
        return local.translate('TRANSACTION_FORWARD_RESPONDED');
      default:
        if (code.isNotEmpty) {
          final translated = local.translate(code);
          if (translated != code) {
            var msg = translated;
            args.forEach((key, val) {
              msg = msg.replaceAll('{$key}', val.toString());
            });
            return msg;
          }
          if (args.isNotEmpty) {
            final argsStr = args.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('، ');
            return '$code ($argsStr)';
          }
          return code;
        }
        return notification['body']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? [
                  AppColors.background,
                  AppColors.primary.withOpacity(0.12),
                  AppColors.background,
                  AppColors.primary.withOpacity(0.08),
                ]
              : AppColors.themeColor == AppThemeColor.purple
                  ? [
                      const Color(0xFFD8C8FF),
                      const Color(0xFFF8F4FF),
                      const Color(0xFFF3EEFF),
                      const Color(0xFFC4AEF0),
                    ]
                  : [
                      const Color(0xFFC8E0FF),
                      const Color(0xFFF4F8FF),
                      const Color(0xFFEDF5FF),
                      const Color(0xFFBDD5F8),
                    ],
          stops: const [0.0, 0.38, 0.62, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('notifications'),
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textWhite),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final isAdmin = widget.isAdmin;
              final count = isAdmin ? provider.unreadCount : provider.unreadCountForNonAdmin;
              if (count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  // الـ codes المستثناة دائماً (Inbox)
                  const inboxCodes = {
                    'TRANSACTION_FORWARD_RECEIVED',
                    'TRANSACTION_FORWARD_RESPONDED',
                  };
                  // الـ codes المستثناة للغير Admin (Budget)
                  const budgetCodes = {
                    'BUDGET_ALLOCATION_OVERFLOW_ATTEMPT',
                    'INSUFFICIENT_BUDGET',
                    'BUDGET_WARNING',
                    'BUDGET_EXCEEDED',
                  };
                  final unread = provider.notifications.where((n) {
                    final code = n['code']?.toString() ?? '';
                    if (n['seen'] == true) return false;
                    if (inboxCodes.contains(code)) return false;
                    if (!isAdmin && budgetCodes.contains(code)) return false;
                    return true;
                  }).toList();
                  for (final n in unread) {
                    await provider.markAsSeen(n['id']);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all_rounded, size: 16, color: AppColors.textWhite.withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)?.translate('mark_all_as_read') ?? 'تحديد الكل كمقروء',
                        style: TextStyle(
                          color: AppColors.textWhite.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          // فلترة القائمة حسب الـ role
          final visibleNotifications = widget.isAdmin
              ? provider.notifications
              : provider.notificationsForNonAdmin;

          if (provider.isLoading && visibleNotifications.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (visibleNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 72,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)?.translate('no_notifications') ?? 'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.translate('no_notifications_subtitle') ?? 'عندما تتلقى إشعارات جديدة، ستظهر هنا.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isMobile ? 8 : 16,
            ),
            itemCount:
                visibleNotifications.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == visibleNotifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final notification = visibleNotifications[index];
              final isSeen = notification['seen'] == true;
              final type = notification['type']?.toString();
              final color = _getNotificationColor(notification);
              final icon = _getNotificationIcon(notification);
              final message = _buildMessage(context, notification);
              final time = _formatTime(context, notification['timestamp']);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Dismissible(
                  key: Key('notif_${notification['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.accentGreen,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    if (!isSeen) {
                      await provider.markAsSeen(notification['id']);
                    }
                    return false; // don't actually dismiss
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSeen
                          ? AppColors.cardBg
                          : AppColors.primary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: isSeen ? 0.3 : 0.8),
                        width: isSeen ? 1 : 1.5,
                      ),
                    boxShadow: isSeen
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: color.withValues(alpha: 0.08),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (!isSeen) {
                          provider.markAsSeen(notification['id']);
                        }
                        
                        final args = notification['args'] as Map? ?? {};
                        final String rawId = _getArgValue(args['transactionId'] ?? args['id'] ?? args['requestId']);
                        
                        if (rawId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseApprovalRequestPage(
                                requestId: rawId,
                              ),
                            ),
                          );
                        }
                      },
                      child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isSeen)
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(AppLocalizations.of(context)!.locale.languageCode == 'en' ? 16 : 0),
                                  right: Radius.circular(AppLocalizations.of(context)!.locale.languageCode == 'ar' ? 16 : 0),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12 : 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Icon(icon, color: color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.isNotEmpty
                                              ? message
                                              : (type ?? (AppLocalizations.of(context)?.translate('notification') ?? 'إشعار')),
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 15,
                                            fontWeight: isSeen
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            height: 1.5,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            if (type != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: color.withValues(alpha: 0.2),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  type,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            const Spacer(),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 14,
                                                  color: AppColors.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  time,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                   ),
                  ),
                ),
               ),
              );
            },
          );
        },
      ),
    ),
  );
}
}
