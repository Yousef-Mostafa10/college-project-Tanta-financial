import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:college_project/l10n/app_localizations.dart';
import 'package:college_project/core/app_colors.dart';

class ContactDevelopersPage extends StatelessWidget {
  const ContactDevelopersPage({super.key});

  static const List<Map<String, dynamic>> _developers = [
    {
      'name': 'Yousef Mostafa',
      'jobKey': 'job_flutter',
      'phone': '201155474660',
      'roleColor': Color(0xFF007AFF),
      'roleIcon': Icons.phone_android_rounded,
    },
    {
      'name': 'Mohamed AlMahllawi',
      'jobKey': 'job_backend',
      'phone': '201553301209',
      'roleColor': Color(0xFF34C759),
      'roleIcon': Icons.dns_rounded,
    },
    {
      'name': 'Yusuf Naser',
      'jobKey': 'job_backend',
      'phone': '201040207200',
      'roleColor': Color(0xFF34C759),
      'roleIcon': Icons.dns_rounded,
    },
    {
      'name': 'Amr Ahmed',
      'jobKey': 'job_tester',
      'phone': '201116692492',
      'roleColor': Color(0xFFFF9500),
      'roleIcon': Icons.bug_report_rounded,
    },
    {
      'name': 'Sabry Elsawy',
      'jobKey': 'job_frontend',
      'phone': '201092608428',
      'roleColor': Color(0xFFAF52DE),
      'roleIcon': Icons.web_rounded,
    },
    {
      'name': 'Ziad Hamdy',
      'jobKey': 'job_frontend',
      'phone': '201140723214',
      'roleColor': Color(0xFFAF52DE),
      'roleIcon': Icons.web_rounded,
    },
    {
      'name': 'Ibrahim Ahmed',
      'jobKey': 'job_frontend',
      'phone': '201025760027',
      'roleColor': Color(0xFFAF52DE),
      'roleIcon': Icons.web_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.bodyBg,
      body: CustomScrollView(
        slivers: [
          // ── شريط علوي متدرج جميل ──
          SliverAppBar(
            expandedHeight: isMobile ? 170 : 210,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isMobile ? 24 : 32),
                      Container(
                        width: isMobile ? 60 : 72,
                        height: isMobile ? 60 : 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: isMobile ? 30 : 38,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        l10n.translate('contact_developers'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_developers.length} members',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── قائمة المطورين ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              isMobile ? 16 : 20,
              isMobile ? 12 : 16,
              32,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dev = _developers[index];
                  return _DeveloperCard(
                    dev: dev,
                    l10n: l10n,
                    index: index,
                    isMobile: isMobile,
                  );
                },
                childCount: _developers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة المطور ──
class _DeveloperCard extends StatelessWidget {
  final Map<String, dynamic> dev;
  final AppLocalizations l10n;
  final int index;
  final bool isMobile;

  const _DeveloperCard({
    required this.dev,
    required this.l10n,
    required this.index,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final Color roleColor = dev['roleColor'] as Color;
    final String initials = _getInitials(dev['name'] as String);
    final double avatarSize = isMobile ? 50.0 : 58.0;
    final double avatarFontSize = isMobile ? 17.0 : 20.0;
    final double nameFontSize = isMobile ? 14.0 : 16.0;
    final double cardPadding = isMobile ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: roleColor.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── صورة المطور ──
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor,
                        roleColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: avatarFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                // ── رقم المطور ──
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: isMobile ? 10 : 14),

            // ── معلومات المطور ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // ── Badge الوظيفة ──
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            dev['roleIcon'] as IconData,
                            size: 11,
                            color: roleColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.translate(dev['jobKey'] as String),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 11,
                                color: roleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '+${dev['phone']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: isMobile ? 8 : 10),
            // ── زر واتساب ──
            _WhatsAppButton(
              phone: dev['phone'] as String,
              color: roleColor,
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }
}

// ── زر الواتساب ──
class _WhatsAppButton extends StatefulWidget {
  final String phone;
  final Color color;
  final bool isMobile;

  const _WhatsAppButton({
    required this.phone,
    required this.color,
    required this.isMobile,
  });

  @override
  State<_WhatsAppButton> createState() => _WhatsAppButtonState();
}

class _WhatsAppButtonState extends State<_WhatsAppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    _ctrl.forward().then((_) => _ctrl.reverse());

    final cleanPhone = widget.phone.replaceAll(RegExp(r'[^0-9]'), '');

    // whatsapp:// scheme مسجل عند كلا التطبيقين (العادي والبيزنس)
    // → أندرويد/آيفون يعرض قائمة الاختيار الأصلية بأيقوناتهم من الجهاز
    // → إذا كان واحد فقط مثبتاً يفتح مباشرة بدون سؤال
    final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final Uri fallbackUri = Uri.parse('https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('واتساب غير مثبت على الجهاز'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double btnSize = widget.isMobile ? 42.0 : 48.0;
    final double iconSize = widget.isMobile ? 20.0 : 22.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openWhatsApp,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.chat_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
