import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../home/dashboard.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../app_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isPasswordVisible = false;

  // 🎨 COLORS
  static const Color primaryColor = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);
  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color cardColor = Colors.white;

  // 🔹 جلب بيانات المستخدم
  Future<Map<String, dynamic>> _fetchUserData(
      String token, String username) async {
    try {
      final url = Uri.parse("${AppConfig.baseUrl}/users/$username");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          return data["user"] ?? {};
        }
        return data; // Fallback if no status wrapper
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return {};
  }

  // 🔹 LOGIN
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("${AppConfig.baseUrl}/auth");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          final token = data["token"];
          final username = emailController.text.trim();

          final userData = await _fetchUserData(token, username);
          final userGroup = userData["group"] ?? "user";

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', username);
          await prefs.setString('user_group', userGroup);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${AppLocalizations.of(context)!.translate('login_successful')}")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdministrativeDashboardPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "${AppLocalizations.of(context)!.translate('login_failed')} ❌")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ ${AppLocalizations.of(context)!.translate('connection_error')}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: max(16, screenWidth * 0.05),
              vertical: max(10, screenHeight * 0.02),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(screenWidth, 1000),
                maxHeight: min(screenHeight, 800),
              ),
              child: Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: screenWidth > 600 ? 5 : 2,
                child: Padding(
                  padding: EdgeInsets.all(max(16, screenWidth * 0.03)),
                  child: _buildResponsiveLayout(screenWidth, isPortrait),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(double screenWidth, bool isPortrait) {
    // نقاط التوقف للتصميم المتجاوب
    if (screenWidth > 900) {
      // كمبيوتر - شاشات كبيرة (الصورة على اليمين)
      return Row(
        children: [
          // الفورم على اليسار
          Expanded(
            flex: 2,
            child: buildForm(),
          ),
          const SizedBox(width: 40),
          // الصورة على اليمين
          Expanded(
            flex: 3,
            child: _buildImageSection(screenWidth, isPortrait),
          ),
        ],
      );
    } else if (screenWidth > 600) {
      // تابلت - شاشات متوسطة
      return isPortrait
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImageSection(screenWidth, isPortrait),
          const SizedBox(height: 30),
          buildForm(),
        ],
      )
          : Row(
        children: [
          // الفورم على اليسار للتابلت الأفقي
          Expanded(
            child: buildForm(),
          ),
          const SizedBox(width: 30),
          // الصورة على اليمين للتابلت الأفقي
          Expanded(
            child: _buildImageSection(screenWidth, isPortrait),
          ),
        ],
      );
    } else {
      // موبايل - شاشات صغيرة (الصورة أعلاه)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImageSection(screenWidth, isPortrait),
          const SizedBox(height: 20),
          buildForm(),
        ],
      );
    }
  }

  Widget _buildImageSection(double screenWidth, bool isPortrait) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/undraw_project-completed_fwjq.png',
            width: _getImageSize(screenWidth, isPortrait),
            height: _getImageSize(screenWidth, isPortrait) * 0.8,
            fit: BoxFit.contain,
          ),
          if (screenWidth < 600) const SizedBox(height: 10),
          if (screenWidth < 600)
            Text(
              AppLocalizations.of(context)!.translate('welcome_back'),
              style: TextStyle(
                fontSize: min(screenWidth * 0.045, 20),
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  double _getImageSize(double screenWidth, bool isPortrait) {
    if (screenWidth > 900) {
      return isPortrait ? 350 : 300;
    } else if (screenWidth > 600) {
      return isPortrait ? 280 : 250;
    } else {
      return min(screenWidth * 0.7, 250);
    }
  }

  Widget buildForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوان في المنتصف
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                screenWidth > 600 ? AppLocalizations.of(context)!.translate('app_name_long') : AppLocalizations.of(context)!.translate('app_name_short'),
                style: TextStyle(
                  fontSize: screenWidth > 600
                      ? min(screenWidth * 0.04, 28)
                      : min(screenWidth * 0.06, 24),
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (screenWidth > 600) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.translate('sign_in_subtitle'),
                  style: TextStyle(
                    fontSize: min(screenWidth * 0.025, 16),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: screenWidth > 600 ? 25 : 15),
            ],
          ),

          // باقي الحقول مع محاذاة لليسار
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('username'),
                style: TextStyle(
                  fontSize: min(screenWidth * 0.035, 16),
                  fontWeight: FontWeight.w500,
                  color: primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('enter_username_hint'),
                  prefixIcon: const Icon(Icons.person, color: primaryLight),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenWidth > 600 ? 18 : 16,
                    horizontal: 16,
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? AppLocalizations.of(context)!.translate('enter_username_error') : null,
              ),
              const SizedBox(height: 20),

              // Password
              Text(
                AppLocalizations.of(context)!.translate('password'),
                style: TextStyle(
                  fontSize: min(screenWidth * 0.035, 16),
                  fontWeight: FontWeight.w500,
                  color: primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('enter_password_hint'),
                  prefixIcon: const Icon(Icons.lock, color: primaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primaryLight,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenWidth > 600 ? 18 : 16,
                    horizontal: 16,
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? AppLocalizations.of(context)!.translate('enter_password_error') : null,
              ),
              const SizedBox(height: 30),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth > 600 ? 18 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    AppLocalizations.of(context)!.translate('sign_in_button'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: min(screenWidth * 0.04, 18),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
