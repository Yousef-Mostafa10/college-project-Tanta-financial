import 'dart:ui';
import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

Widget buildDesktopStatsRow(
  BuildContext context,
  int total,
  int approved,
  int rejected,
  int waiting,
  int needsChange,
) {
  final stats = [
    {
      "label": AppLocalizations.of(context)!.translate('total_stat'),
      "value": total,
      "color": MyRequestsColors.primary,
      "icon": Icons.dashboard_rounded,
    },
    {
      "label": AppLocalizations.of(context)!.translate('status_approved'),
      "value": approved,
      "color": MyRequestsColors.statusApproved,
      "icon": Icons.check_circle_rounded,
    },
    {
      "label": AppLocalizations.of(context)!.translate('status_rejected'),
      "value": rejected,
      "color": MyRequestsColors.statusRejected,
      "icon": Icons.cancel_rounded,
    },
    {
      "label": AppLocalizations.of(context)!.translate('status_waiting'),
      "value": waiting,
      "color": MyRequestsColors.statusWaiting,
      "icon": Icons.hourglass_empty_rounded,
    },
    {
      "label": AppLocalizations.of(context)!.translate('needs_change_stat'),
      "value": needsChange,
      "color": MyRequestsColors.statusNeedsChange,
      "icon": Icons.edit_note_rounded,
    },
  ];

  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: MyRequestsColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: MyRequestsColors.isDark
                ? Colors.white.withOpacity(0.10)
                : MyRequestsColors.borderColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: MyRequestsColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) {
            final color = stat["color"] as Color;
            return _StatItem(
              label: stat["label"] as String,
              value: stat["value"] as int,
              color: color,
              icon: stat["icon"] as IconData,
            );
          }).toList(),
        ),
      ),
    ),
  );
}

class _StatItem extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.2),
                      widget.color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                widget.value.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MyRequestsColors.textSecondary,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}