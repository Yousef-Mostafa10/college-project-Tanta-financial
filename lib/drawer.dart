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
import 'package:college_project/providers/theme_provider.dart';
import 'package:college_project/core/app_colors.dart';
import 'package:college_project/core/app_theme_color.dart';

import 'Department/DepartmentsPage.dart';
import 'Budget/BudgetPage.dart';
import 'settings/contact_developers.dart';

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

            // قسم Management - يظهر للادمن وللمحاسب (بشكل محدود)
            if (_userType.toLowerCase() == 'admin' || _userType.toLowerCase() == 'accountant') ...[
              _buildSectionHeader(AppLocalizations.of(context)!.translate('management'), Icons.admin_panel_settings_rounded, isMobile),

              if (_userType.toLowerCase() == 'admin') ...[
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
                      MaterialPageRoute(builder: (context) => DepartmentsPage()),
                    );
                  },
                ),
              ],

              // المحاسب والادمن يشوفوا الميزانية
              _buildMenuItem(
                icon: Icons.account_balance_wallet_rounded,
                title: AppLocalizations.of(context)!.translate('budget_categories'),
                color: AppColors.accentYellow,
                isMobile: isMobile,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BudgetPage()),
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

            _buildSectionHeader(AppLocalizations.of(context)!.translate('settings'), Icons.settings_rounded, isMobile),

            _buildSettingsExpansionTile(isMobile),

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
            offset: Offset(0, 4),
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
                    offset: Offset(0, 4),
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
                    offset: Offset(1, 1),
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
            offset: Offset(0, 2),
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

  // 🔹 بناء قسم الإعدادات التوسعي
  Widget _buildSettingsExpansionTile(bool isMobile) {
    return Container(
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary.withOpacity(0.5),
          leading: Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.tune_rounded, // أيقونة إعدادات مميزة
              color: AppColors.primary,
              size: isMobile ? 20 : 22,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.translate('general') ?? 'General',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 14 : 16,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            // 1️⃣ اختيار اللغة
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final isArabic = languageProvider.currentLocale.languageCode == 'ar';
                return _buildSubExpansionTile(
                  title: AppLocalizations.of(context)!.translate('language'),
                  icon: Icons.language_rounded,
                  isMobile: isMobile,
                  children: [
                    _buildSelectionItem(
                      title: 'العربية',
                      isSelected: isArabic,
                      isMobile: isMobile,
                      onTap: () => languageProvider.changeLanguage(const Locale('ar')),
                    ),
                    _buildSelectionItem(
                      title: 'English',
                      isSelected: !isArabic,
                      isMobile: isMobile,
                      onTap: () => languageProvider.changeLanguage(const Locale('en')),
                    ),
                  ],
                );
              },
            ),

            // 2️⃣ اختيار الإضاءة / الوضع
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSubExpansionTile(
                  title: themeProvider.isDarkMode 
                      ? AppLocalizations.of(context)!.translate('dark_mode')
                      : AppLocalizations.of(context)!.translate('light_mode'),
                  icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  isMobile: isMobile,
                  children: [
                    _buildSelectionItem(
                      title: AppLocalizations.of(context)!.translate('dark_mode'),
                      icon: Icons.dark_mode_rounded,
                      isSelected: themeProvider.isDarkMode,
                      isMobile: isMobile,
                      onTap: () => themeProvider.toggleTheme(true),
                    ),
                    _buildSelectionItem(
                      title: AppLocalizations.of(context)!.translate('light_mode'),
                      icon: Icons.light_mode_rounded,
                      isSelected: !themeProvider.isDarkMode,
                      isMobile: isMobile,
                      onTap: () => themeProvider.toggleTheme(false),
                    ),
                  ],
                );
              },
            ),

            // اختيار لون السيم (Theme Color)
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSubExpansionTile(
                  title: AppLocalizations.of(context)!.translate('theme_color') ?? 'Theme Color',
                  icon: Icons.palette_rounded,
                  isMobile: isMobile,
                  children: [
                    _buildColorItem(
                      title: 'Default Blue',
                      color: const Color(0xFF007AFF),
                      isSelected: themeProvider.themeColor == AppThemeColor.defaultBlue,
                      isMobile: isMobile,
                      onTap: () => themeProvider.setThemeColor(AppThemeColor.defaultBlue),
                    ),
                    _buildColorItem(
                      title: 'Deep Purple',
                      color: const Color(0xFF6E00B2),
                      isSelected: themeProvider.themeColor == AppThemeColor.purple,
                      isMobile: isMobile,
                      onTap: () => themeProvider.setThemeColor(AppThemeColor.purple),
                    ),
                  ],
                );
              },
            ),

            // تواصل مع المطورين
            _buildMenuItem(
              icon: Icons.contact_support_rounded,
              title: AppLocalizations.of(context)!.translate('contact_developers'),
              color: AppColors.primary,
              isMobile: isMobile,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ContactDevelopersPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء عناصر اختيار اللون
  Widget _buildColorItem({
    required String title,
    required Color color,
    required bool isSelected,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: isMobile ? 40 : 48, right: isMobile ? 16 : 24),
      onTap: onTap,
      leading: Container(
        width: isMobile ? 16 : 20,
        height: isMobile ? 16 : 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 12 : 14,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: AppColors.primary, size: isMobile ? 16 : 18) : null,
    );
  }

  // دالة مساعدة لبناء العناصر الفرعية التوسعية
  Widget _buildSubExpansionTile({
    required String title,
    required IconData icon,
    required bool isMobile,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        leading: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: isMobile ? 18 : 20),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary.withOpacity(0.5),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            color: AppColors.textPrimary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        children: children,
      ),
    );
  }

  // دالة مساعدة لبناء عناصر الاختيار النهائي
  Widget _buildSelectionItem({
    required String title,
    IconData? icon,
    required bool isSelected,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 32, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        leading: icon != null 
            ? Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary) 
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16) 
            : null,
        onTap: onTap,
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