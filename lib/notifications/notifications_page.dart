import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_project/core/app_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_theme_color.dart';
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

  IconData _getNotificationIcon(String? type) {
    switch (type?.toUpperCase()) {
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

  Color _getNotificationColor(String? type) {
    switch (type?.toUpperCase()) {
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
        return local.translate('REQUEST_APPROVED');
      case 'REQUEST_REJECTED':
        final reason = args['reason']?.toString() ?? '';
        if (reason.isNotEmpty) {
          return local.translate('REQUEST_REJECTED_WITH_REASON').replaceAll('{reason}', reason);
        }
        return local.translate('REQUEST_REJECTED');
      case 'TRANSACTION_FORWARD_RECEIVED':
        return local.translate('TRANSACTION_FORWARD_RECEIVED');
      case 'TRANSACTION_FORWARD_RESPONDED':
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
                child: Text(
                  AppLocalizations.of(context)?.translate('mark_all_as_read') ?? 'تحديد الكل كمقروء',
                  style: TextStyle(
                    color: AppColors.textWhite.withValues(alpha: 0.85),
                    fontSize: 13,
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
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 72,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.translate('no_notifications') ?? 'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
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
              final color = _getNotificationColor(type);
              final icon = _getNotificationIcon(type);
              final message = _buildMessage(context, notification);
              final time = _formatTime(context, notification['timestamp']);

              return Dismissible(
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
                child: GestureDetector(
                  onTap: () {
                    if (!isSeen) {
                      provider.markAsSeen(notification['id']);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSeen
                          ? AppColors.cardBg
                          : AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSeen
                            ? AppColors.borderColor
                            : AppColors.primary.withValues(alpha: 0.25),
                        width: isSeen ? 1 : 1.5,
                      ),
                      boxShadow: isSeen
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!isSeen)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(
                                            right: 6, top: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        message.isNotEmpty
                                            ? message
                                            : (type ?? (AppLocalizations.of(context)?.translate('notification') ?? 'إشعار')),
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 14,
                                          fontWeight: isSeen
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (type != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
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
