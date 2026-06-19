import 'dart:math';
import 'package:flutter/material.dart';
import '../home/dashboard.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../utils/app_error_handler.dart';
import 'package:provider/provider.dart';
import 'package:college_project/providers/theme_provider.dart';
import 'package:college_project/core/app_theme_color.dart';
import 'auth_service.dart';
import '../notifications/notifications_provider.dart';
import '../request/Myrequest/myrequest.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ── Floating Particle Data ──────────────────────────────────────────────────
class _Particle {
  double x, y, size, speedX, speedY, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

// ── Animated Background Orb Data ─────────────────────────────────────────────
class _OrbData {
  /// Center position as fraction of screen [0..1]
  final double cx, cy;
  /// Orbit radius as fraction of screen
  final double orbitRx, orbitRy;
  /// Starting phase in radians
  final double phase;
  /// Angular speed (radians per full animation cycle)
  final double speed;
  /// Orb radius in logical pixels
  final double radius;
  final Color color;
  final double opacity;

  const _OrbData({
    required this.cx,
    required this.cy,
    required this.orbitRx,
    required this.orbitRy,
    required this.phase,
    required this.speed,
    required this.radius,
    required this.color,
    required this.opacity,
  });
}

// ── Orbs Painter ─────────────────────────────────────────────────────────────
class _OrbsPainter extends CustomPainter {
  final double t; // 0..1 animation progress
  final List<_OrbData> orbs;

  _OrbsPainter({required this.t, required this.orbs});

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final angle = orb.phase + orb.speed * t * 2 * pi;
      final dx = orb.cx * size.width  + orb.orbitRx * size.width  * cos(angle);
      final dy = orb.cy * size.height + orb.orbitRy * size.height * sin(angle);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withOpacity(orb.opacity),
            orb.color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(dx, dy),
          radius: orb.radius,
        ));

      canvas.drawCircle(Offset(dx, dy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => old.t != t;
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;

  // ── Animation Controllers ────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late AnimationController _orbController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _gradientAnimation;

  List<_OrbData> _orbs = [];

  // ── Particles ────────────────────────────────────────────────────────────
  final List<_Particle> _particles = [];
  final Random _random = Random();

  // 🎨 COLORS
  static Color get primaryColor => AppColors.primary;
  static Color get labelColor => AppColors.textPrimary;
  static Color get iconColor => AppColors.textSecondary;
  static Color get borderColor => AppColors.borderColor;
  static Color get backgroundColor => AppColors.bodyBg;
  static Color get cardColor => AppColors.cardBg;

  @override
  void initState() {
    super.initState();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Slide up
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Pulsing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Button press scale
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Floating particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateParticles)..repeat();

    // Gradient shift
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );

    // Orb background animation (slow, continuous)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // Start entry animations with stagger
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });

    // Init particles
    _initParticles();
  }

  void _buildOrbs({required bool isDark, required bool isPurple}) {
    final Color c1 = isPurple ? const Color(0xFF613394) : const Color(0xFF007AFF);
    final Color c2 = isPurple ? const Color(0xFF3E3A6D) : const Color(0xFF005FD4);
    final Color c3 = isPurple ? const Color(0xFFA389D4) : const Color(0xFF3DA8FF);
    final double baseOpacity = isDark ? 0.38 : 0.28;
    _orbs = [
      // ── Large anchor orbs ─────────────────────────────────────────────
      _OrbData(cx: 0.15, cy: 0.18, orbitRx: 0.12, orbitRy: 0.10, phase: 0.0,  speed:  1.0,  radius: 420, color: c1, opacity: baseOpacity),
      _OrbData(cx: 0.85, cy: 0.15, orbitRx: 0.10, orbitRy: 0.14, phase: 2.1,  speed: -0.7,  radius: 380, color: c2, opacity: baseOpacity * 0.9),
      _OrbData(cx: 0.72, cy: 0.82, orbitRx: 0.13, orbitRy: 0.09, phase: 4.2,  speed:  0.85, radius: 450, color: c3, opacity: baseOpacity * 0.80),
      _OrbData(cx: 0.10, cy: 0.78, orbitRx: 0.09, orbitRy: 0.12, phase: 1.0,  speed: -1.1,  radius: 360, color: c2, opacity: baseOpacity * 0.85),
      // ── Center bloom ─────────────────────────────────────────────────
      _OrbData(cx: 0.50, cy: 0.48, orbitRx: 0.07, orbitRy: 0.07, phase: 3.14, speed:  0.6,  radius: 500, color: c1, opacity: baseOpacity * 0.35),
      // ── Mid-size accent orbs ──────────────────────────────────────────
      _OrbData(cx: 0.30, cy: 0.55, orbitRx: 0.14, orbitRy: 0.08, phase: 5.0,  speed: -0.9,  radius: 320, color: c3, opacity: baseOpacity * 0.70),
      _OrbData(cx: 0.68, cy: 0.40, orbitRx: 0.08, orbitRy: 0.13, phase: 1.6,  speed:  1.2,  radius: 300, color: c1, opacity: baseOpacity * 0.65),
      // ── Small sparkle orbs ────────────────────────────────────────────
      _OrbData(cx: 0.90, cy: 0.60, orbitRx: 0.06, orbitRy: 0.10, phase: 0.8,  speed: -1.4,  radius: 220, color: c3, opacity: baseOpacity * 0.60),
      _OrbData(cx: 0.25, cy: 0.88, orbitRx: 0.11, orbitRy: 0.06, phase: 2.8,  speed:  0.75, radius: 250, color: c2, opacity: baseOpacity * 0.55),
    ];

  }

  void _initParticles() {
    for (int i = 0; i < 45; i++) {
      // Bias distribution towards edges (avoiding the exact center)
      double x = _random.nextDouble();
      double y = _random.nextDouble();
      
      // Push 70% of particles to the left/right edges
      if (_random.nextDouble() > 0.3) {
        x = _random.nextBool() ? _random.nextDouble() * 0.25 : 0.75 + _random.nextDouble() * 0.25;
      }
      // Push 70% of particles to the top/bottom edges
      if (_random.nextDouble() > 0.3) {
        y = _random.nextBool() ? _random.nextDouble() * 0.25 : 0.75 + _random.nextDouble() * 0.25;
      }

      _particles.add(_Particle(
        x: x,
        y: y,
        size: _random.nextDouble() * 8 + 4, // Increased size (was 4 + 2)
        speedX: (_random.nextDouble() - 0.5) * 0.0004, // Slower speed to stay on edges longer
        speedY: (_random.nextDouble() - 0.5) * 0.0004,
        opacity: _random.nextDouble() * 0.4 + 0.2, // Slightly more opaque
      ));
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.speedX;
        p.y += p.speedY;
        if (p.x < 0) p.x = 1;
        if (p.x > 1) p.x = 0;
        if (p.y < 0) p.y = 1;
        if (p.y > 1) p.y = 0;
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    _gradientController.dispose();
    _orbController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🔹 LOGIN
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    _buttonController.forward().then((_) => _buttonController.reverse());

    try {
      final result = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final userRole = result['data']['user']?['role'] ?? 'user';

        Provider.of<NotificationProvider>(context, listen: false).init();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${AppLocalizations.of(context)!.translate('login_successful')}"),
            backgroundColor: primaryColor,
          ),
        );

        if (userRole.toUpperCase() == 'ADMIN') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdministrativeDashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyRequestsPage()),
          );
        }
      } else {
        final errorKey = result['errorKey'] as String? ?? result['error']?.toString() ?? 'login_failed';
        final errorMessage = AppErrorHandler.translateKey(context, errorKey);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = AppErrorHandler.translateException(context, e);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
        final isDark = AppColors.isDark;
        final isPurple = AppColors.themeColor == AppThemeColor.purple;

        // Build orbs with current theme
        if (_orbs.isEmpty) _buildOrbs(isDark: isDark, isPurple: isPurple);

        // Gradient colors based on theme
        final Color g1 = isDark
            ? (isPurple ? const Color(0xFF161432) : const Color(0xFF060912))
            : (isPurple ? const Color(0xFFF3EEFF) : const Color(0xFFEFF6FF));
        final Color g2 = isDark
            ? (isPurple ? const Color(0xFF211D45) : const Color(0xFF0D1C35))
            : (isPurple ? const Color(0xFFE8D5FF) : const Color(0xFFDBEAFE));
        final Color particleColor = AppColors.primary;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.topRight,
                      _gradientAnimation.value,
                    )!,
                    end: Alignment.lerp(
                      Alignment.bottomRight,
                      Alignment.bottomLeft,
                      _gradientAnimation.value,
                    )!,
                    colors: [g1, g2, g1],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // ── Animated Orbs Background ────────────────────────
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _orbController,
                        builder: (context, _) => CustomPaint(
                          painter: _OrbsPainter(
                            t: _orbController.value,
                            orbs: _orbs,
                          ),
                        ),
                      ),
                    ),

                    // ── Floating Particles (on top of orbs) ─────────────
                    ..._particles.map((p) => Positioned(
                          left: p.x * screenWidth,
                          top: p.y * screenHeight,
                          child: Container(
                            width: p.size,
                            height: p.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: particleColor.withOpacity(p.opacity * (isDark ? 0.55 : 0.30)),
                            ),
                          ),
                        )),


                    // ── Main Content ────────────────────────────────────
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: max(16, screenWidth * 0.05),
                            vertical: max(10, screenHeight * 0.02),
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: min(screenWidth, 1200),
                                ),
                                child: AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          // Pulsing outer glow
                                          BoxShadow(
                                            color: primaryColor.withOpacity(
                                              0.12 + 0.12 * _glowAnimation.value,
                                            ),
                                            blurRadius: 28 + 20 * _glowAnimation.value,
                                            spreadRadius: 2 + 4 * _glowAnimation.value,
                                          ),
                                          // Base shadow
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Card(
                                    color: cardColor,
                                    surfaceTintColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: primaryColor.withOpacity(0.18),
                                        width: 1.2,
                                      ),
                                    ),
                                    elevation: 0,
                                    child: Padding(
                                      padding: EdgeInsets.all(max(20, screenWidth * 0.03)),
                                      child: _buildResponsiveLayout(screenWidth, isPortrait),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(double screenWidth, bool isPortrait) {
    if (screenWidth > 900) {
      return Row(
        children: [
          Expanded(flex: 3, child: buildForm()),
          const SizedBox(width: 50),
          Expanded(flex: 4, child: _buildImageSection(screenWidth, isPortrait)),
        ],
      );
    } else if (screenWidth > 600) {
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
                Expanded(child: buildForm()),
                const SizedBox(width: 30),
                Expanded(child: _buildImageSection(screenWidth, isPortrait)),
              ],
            );
    } else {
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.85 + 0.15 * value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _getLoginImage(),
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
      ),
    );
  }

  double _getImageSize(double screenWidth, bool isPortrait) {
    if (screenWidth > 1200) return isPortrait ? 600 : 550;
    else if (screenWidth > 900) return isPortrait ? 500 : 450;
    else if (screenWidth > 600) return isPortrait ? 280 : 250;
    else return min(screenWidth * 0.7, 250);
  }

  Widget buildForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          _AnimatedFormSection(
            delay: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Logo with glow
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2 + 0.15 * _glowAnimation.value),
                            blurRadius: 16 + 8 * _glowAnimation.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(Icons.account_balance, color: primaryColor, size: 30),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  screenWidth > 600
                      ? AppLocalizations.of(context)!.translate('app_name_long')
                      : AppLocalizations.of(context)!.translate('app_name_short'),
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
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.translate('sign_in_subtitle'),
                    style: TextStyle(
                      fontSize: min(screenWidth * 0.025, 15),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: screenWidth > 600 ? 28 : 18),
              ],
            ),
          ),

          // ── Fields ────────────────────────────────────────────────────
          _AnimatedFormSection(
            delay: const Duration(milliseconds: 350),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  AppLocalizations.of(context)!.translate('username'),
                  style: TextStyle(
                    fontSize: min(screenWidth * 0.035, 15),
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                _AnimatedField(
                  child: TextFormField(
                    controller: emailController,
                    style: TextStyle(color: labelColor),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_username_hint'),
                      hintStyle: TextStyle(color: iconColor.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.person_outline_rounded, color: iconColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceElevated.withOpacity(0.5),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenWidth > 600 ? 18 : 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? AppLocalizations.of(context)!.translate('enter_username_error')
                            : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                Text(
                  AppLocalizations.of(context)!.translate('password'),
                  style: TextStyle(
                    fontSize: min(screenWidth * 0.035, 15),
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                _AnimatedField(
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: TextStyle(color: labelColor),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enter_password_hint'),
                      hintStyle: TextStyle(color: iconColor.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: iconColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: iconColor,
                        ),
                        onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceElevated.withOpacity(0.5),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenWidth > 600 ? 18 : 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? AppLocalizations.of(context)!.translate('enter_password_error')
                            : null,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // ── Login Button ──────────────────────────────────────────────
          _AnimatedFormSection(
            delay: const Duration(milliseconds: 500),
            child: AnimatedBuilder(
              animation: _buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isLoading
                        ? null
                        : LinearGradient(
                            colors: [
                              primaryColor,
                              AppColors.primaryHover,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth > 600 ? 18 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('sign_in_button'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: min(screenWidth * 0.04, 17),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLoginImage() {
    final bool isDark = AppColors.isDark;
    final AppThemeColor theme = AppColors.themeColor;

    if (theme == AppThemeColor.purple) {
      return isDark
          ? 'assets/images/login_dark_purple.png' // الصورة الجديدة
          : 'assets/images/Gemini_Generated_Image_sllkiisllkiisllk.png';
    } else {
      return isDark
          ? 'assets/images/Gemini_Generated_Image_14gt8u14gt8u14gt.png'
          : 'assets/images/Gemini_Generated_Image_ff5fu5ff5fu5ff5f (1).png';
    }
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

/// Fades + slides in a form section with a configurable delay
class _AnimatedFormSection extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFormSection({required this.child, required this.delay});

  @override
  State<_AnimatedFormSection> createState() => _AnimatedFormSectionState();
}

class _AnimatedFormSectionState extends State<_AnimatedFormSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Scales up slightly on focus
class _AnimatedField extends StatefulWidget {
  final Widget child;
  const _AnimatedField({required this.child});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _ctrl.forward();
        } else {
          _ctrl.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
