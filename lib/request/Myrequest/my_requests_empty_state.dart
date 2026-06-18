import 'dart:ui';
import 'package:flutter/material.dart';
import 'my_requests_colors.dart';
import 'package:college_project/l10n/app_localizations.dart';

class MyRequestsEmptyState extends StatefulWidget {
  final bool isMobile;
  final VoidCallback? onResetFilters;
  final VoidCallback? onCreateRequest;

  const MyRequestsEmptyState({
    Key? key,
    required this.isMobile,
    this.onResetFilters,
    this.onCreateRequest,
  }) : super(key: key);

  @override
  State<MyRequestsEmptyState> createState() => _MyRequestsEmptyStateState();
}

class _MyRequestsEmptyStateState extends State<MyRequestsEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(widget.isMobile ? 24 : 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon ──────────────────────────────────────────────────
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: widget.isMobile ? 90 : 110,
                    height: widget.isMobile ? 90 : 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          MyRequestsColors.primary.withOpacity(0.18),
                          MyRequestsColors.primary.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: MyRequestsColors.primary.withOpacity(0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MyRequestsColors.primary.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: widget.isMobile ? 44 : 54,
                      color: MyRequestsColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: widget.isMobile ? 20 : 28),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  AppLocalizations.of(context)!
                      .translate('no_transactions_found'),
                  style: TextStyle(
                    fontSize: widget.isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    color: MyRequestsColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  AppLocalizations.of(context)!.translate('try_adjust_filters'),
                  style: TextStyle(
                    fontSize: widget.isMobile ? 13 : 14,
                    color: MyRequestsColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: widget.isMobile ? 24 : 32),

                // ── Actions ───────────────────────────────────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.onResetFilters != null)
                      _ActionButton(
                        label: AppLocalizations.of(context)!
                            .translate('reset_filters'),
                        icon: Icons.filter_list_off_rounded,
                        isPrimary: false,
                        onTap: widget.onResetFilters!,
                        primaryColor: MyRequestsColors.primary,
                      ),
                    if (widget.onCreateRequest != null)
                      _ActionButton(
                        label: AppLocalizations.of(context)!
                            .translate('create_request'),
                        icon: Icons.add_circle_outline_rounded,
                        isPrimary: true,
                        onTap: widget.onCreateRequest!,
                        primaryColor: MyRequestsColors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Legacy function wrapper for backward compatibility
// ─────────────────────────────────────────────────────────────────────────────

Widget buildEmptyState(
  BuildContext context,
  bool isMobile, {
  VoidCallback? onResetFilters,
  VoidCallback? onCreateRequest,
}) {
  return MyRequestsEmptyState(
    isMobile: isMobile,
    onResetFilters: onResetFilters,
    onCreateRequest: onCreateRequest,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()
          ..scale(_hovered ? 1.03 : 1.0),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isPrimary
                  ? null
                  : widget.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: widget.primaryColor.withOpacity(0.3),
                    ),
              boxShadow: widget.isPrimary && _hovered
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isPrimary
                      ? Colors.white
                      : widget.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isPrimary
                        ? Colors.white
                        : widget.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}