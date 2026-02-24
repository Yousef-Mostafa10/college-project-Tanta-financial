import 'package:college_project/request/creatrequest.dart';
import 'package:college_project/request/Myrequest/myrequest.dart';
import 'package:college_project/Archive/archive_page.dart';
import 'package:college_project/users/Adduser.dart';
import 'package:college_project/users/viewUser/viewuser.dart';
import 'package:flutter/material.dart';
import 'package:college_project/Notefecation/inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:college_project/providers/language_provider.dart';
import 'package:college_project/l10n/app_localizations.dart';

import 'Department/DepartmentsPage.dart';

// 🎨 COLOR PALETTE - Consistent with the whole application
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);
  static const Color primaryDark = Color(0xFF004D40);

  // Background Colors
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentYellow = Color(0xFFFFB74D);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFF9800);

  // Status Colors
  static const Color statusApproved = Color(0xFF27AE60);
  static const Color statusRejected = Color(0xFFE74C3C);
  static const Color statusWaiting = Color(0xFF1E88E5);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF00695C);
  static const Color gradientMiddle = Color(0xFF00796B);
  static const Color gradientEnd = Color(0xFFF5F6FA);

  // Menu Item Colors
  static const Color menuItemBg = Color(0xFFF8F9FA);
  static const Color menuItemBorder = Color(0xFFE9ECEF);

  // Drawer Background - لون أخضر فاتح مثل شريط الإحصائيات
  static const Color drawerBg = Color(0xFFF0F8F7); // أخضر فاتح جداً
  static const Color statBgLight = Color(0xFFF0F8F7); // نفس لون شريط الإحصائيات
}

class CustomDrawer extends StatefulWidget {
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.onLogout,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _userName = "User";
  String _userType = "user";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 جلب بيانات المستخدم من SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userName = prefs.getString('userName') ??
            prefs.getString('username') ??
            'User';

        // جلب نوع المستخدم من user_group
        _userType = prefs.getString('user_group') ?? 'user';

        _isLoading = false;
      });

      debugPrint("🔍 Drawer - User Group: $_userType, Name: $_userName");

    } catch (e) {
      debugPrint("❌ Error loading user data for drawer: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return Drawer(
      width: isMobile ? width * 0.8 :
      isTablet ? 320 :
      360,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.statBgLight, // استخدام لون شريط الإحصائيات
        ),
        child: _isLoading
            ? _buildLoadingState(isMobile)
            : ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // رأس الدراور مع اسم المستخدم فقط
            _buildDrawerHeader(isMobile, isTablet),

            SizedBox(height: isMobile ? 8 : 10),

            // قسم Management - يظهر فقط للادمن
            if (_userType.toLowerCase() == 'admin') ...[
              _buildSectionHeader(AppLocalizations.of(context)!.translate('management'), Icons.admin_panel_settings_rounded, isMobile),

              _buildMenuItem(
                icon: Icons.person_add_alt_1_rounded,
                title: AppLocalizations.of(context)!.translate('add_user'),
                color: AppColors.accentGreen,
                isMobile: isMobile,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AddUserPage()),
                  );
                },
              ),

              _buildMenuItem(
                icon: Icons.people_alt_rounded,
                title: AppLocalizations.of(context)!.translate('view_users'),
                color: AppColors.accentBlue,
                isMobile: isMobile,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ViewUsersPage()),
                  );
                },
              ),

              _buildMenuItem(
                icon: Icons.corporate_fare,
                title: AppLocalizations.of(context)!.translate('departments'),
                color: AppColors.accentGreen,
                isMobile: isMobile,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) =>  DepartmentsPage()),
                  );
                },
              ),

              Divider(
                height: isMobile ? 16 : 20,
                color: AppColors.primary.withOpacity(0.1),
                thickness: 1,
                indent: isMobile ? 20 : 24,
                endIndent: isMobile ? 20 : 24,
              ),
            ],

            _buildSectionHeader(AppLocalizations.of(context)!.translate('requests'), Icons.request_quote_rounded, isMobile),

            _buildMenuItem(
              icon: Icons.add_circle_outline_rounded,
              title: AppLocalizations.of(context)!.translate('create_request'),
              color: AppColors.primary,
              isBold: true,
              isMobile: isMobile,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CreateRequestPage()),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.list_alt_rounded,
              title: AppLocalizations.of(context)!.translate('my_requests'),
              color: AppColors.accentOrange,
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyRequestsPage()),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.archive_rounded,
              title: AppLocalizations.of(context)!.translate('archive'),
              color: AppColors.accentBlue,
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArchivePage()),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.notifications_active_rounded,
              title: AppLocalizations.of(context)!.translate('inbox_title'),
              color: AppColors.accentPurple,
              isMobile: isMobile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxPage()),
                );
              },
            ),

            Divider(
              height: isMobile ? 16 : 20,
              color: AppColors.primary.withOpacity(0.1),
              thickness: 1,
              indent: isMobile ? 20 : 24,
              endIndent: isMobile ? 20 : 24,
            ),

            _buildSectionHeader(AppLocalizations.of(context)!.translate('general'), Icons.settings_rounded, isMobile),

            // إعدادات اللغة (Language Settings)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 2 : 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                color: AppColors.cardBg,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: AppColors.textSecondary,
                      size: isMobile ? 20 : 22,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.translate('settings'),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 14 : 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // collapsedIconColor: AppColors.primary.withOpacity(0.5),
                  childrenPadding: const EdgeInsets.only(bottom: 10),
                  children: [
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Row(
                             children: [
                               Icon(Icons.language, color: AppColors.primary, size: 20),
                               const SizedBox(width: 10),
                               Text(
                                 AppLocalizations.of(context)!.translate('language'),
                                 style: TextStyle(
                                   color: AppColors.textPrimary,
                                   fontSize: 14,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ],
                           ),
                           Consumer<LanguageProvider>(
                             builder: (context, provider, child) {
                               return DropdownButton<String>(
                                 value: provider.currentLocale.languageCode,
                                 underline: const SizedBox(),
                                 icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                 onChanged: (String? newValue) {
                                   if (newValue != null) {
                                     provider.changeLanguage(Locale(newValue));
                                   }
                                 },
                                 items: const [
                                   DropdownMenuItem(value: 'en', child: Text('English')),
                                   DropdownMenuItem(value: 'ar', child: Text('العربية')),
                                 ],
                               );
                             },
                           ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
            ),

            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: AppLocalizations.of(context)!.translate('help_support'),
              color: AppColors.textSecondary,
              isMobile: isMobile,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(context);
              },
            ),

            SizedBox(height: isMobile ? 16 : 20),
            Divider(
              height: 1,
              color: AppColors.primary.withOpacity(0.1),
              thickness: 1,
            ),

            // تسجيل الخروج
            _buildLogoutButton(isMobile),

            SizedBox(height: isMobile ? 8 : 10),
          ],
        ),
      ),
    );
  }

  // 🔹 بناء الهيدر مع اسم المستخدم فقط
  Widget _buildDrawerHeader(bool isMobile, bool isTablet) {
    return Container(
      height: isMobile ? 160 :
      isTablet ? 180 :
      200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isMobile ? 16 : 20,
          right: isMobile ? 16 : 20,
          bottom: isMobile ? 20 : 30,
          top: isMobile ? 16 : 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة المستخدم
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isMobile ? 32 :
                isTablet ? 36 :
                40,
                backgroundColor: AppColors.cardBg,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: isMobile ? 35 :
                  isTablet ? 40 :
                  45,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 20),

            // اسم المستخدم الحقيقي فقط
            Text(
              _userName,
              style: TextStyle(
                fontSize: isMobile ? 18 :
                isTablet ? 22 :
                24,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 حالة التحميل
  Widget _buildLoadingState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            AppLocalizations.of(context)!.translate('loading_user_data'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 زر تسجيل الخروج
  Widget _buildLogoutButton(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.statusRejected.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: AppColors.statusRejected.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.statusRejected.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.logout_rounded,
            color: AppColors.statusRejected,
            size: isMobile ? 18 : 20,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('logout'),
          style: TextStyle(
            color: AppColors.statusRejected,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.statusRejected.withOpacity(0.6),
          size: isMobile ? 14 : 16,
        ),
        onTap: widget.onLogout,
      ),
    );
  }

  // دالة مساعدة لبناء عناصر القائمة
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
    bool isBold = false,
    int badgeCount = 0,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 2 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        color: AppColors.cardBg, // خلفية بيضاء للعناصر
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 4 : 8,
        ),
        leading: Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            color: color,
            size: isMobile ? 20 : 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: isMobile ? 14 : 16,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.statusRejected,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
          child: Text(
            badgeCount.toString(),
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.primary.withOpacity(0.5),
          size: isMobile ? 14 : 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // دالة مساعدة لبناء رؤوس الأقسام
  Widget _buildSectionHeader(String title, IconData icon, bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 24,
        isMobile ? 16 : 20,
        isMobile ? 20 : 24,
        isMobile ? 8 : 10,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 5 : 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isMobile ? 16 : 18,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 10),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لعرض رسالة "قريباً" للميزات غير المكتملة
  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('coming_soon'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}