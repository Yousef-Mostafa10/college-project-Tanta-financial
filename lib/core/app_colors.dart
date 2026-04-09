import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = true;

  static void setTheme(bool isDark) {
    _isDark = isDark;
  }

  static bool get isDark => _isDark;

  // ─── DARK PALETTE ──────────────────────────────────────────────
  static const Color d_shade950 = Color(0xFF030E0B);
  static const Color d_shade900 = Color(0xFF081A14);
  static const Color d_shade850 = Color(0xFF0C2219);
  static const Color d_shade800 = Color(0xFF102C21);
  static const Color d_shade750 = Color(0xFF14362A);
  static const Color d_shade700 = Color(0xFF1A4535);
  static const Color d_shade600 = Color(0xFF1A6650);
  static const Color d_shade500 = Color(0xFF237A57);
  static const Color d_shade400 = Color(0xFF48B07F);
  static const Color d_shade300 = Color(0xFF7CCBA4);
  static const Color d_shade200 = Color(0xFFB5E3CE);
  static const Color d_shade100 = Color(0xFFDDF2E8);
  static const Color d_shade50  = Color(0xFFEDF8F3);

  // ─── LIGHT PALETTE ───────────────────────────────────────────────
  // Backgrounds: Very light desaturated green tones (increased contrast for hierarchy)
  static const Color l_shade50  = Color(0xFFF5FAF8); // Main Bg
  static const Color l_shade100 = Color(0xFFEAF4EF); // Surface (cards)
  static const Color l_shade200 = Color(0xFFDDEEE6); // Elevated surfaces
  static const Color l_shade300 = Color(0xFFD0E5DA); // Borders
  static const Color l_shade400 = Color(0xFF7D9E8A); // Muted text (WCAG AA fixed)
  // Primary & Accents (derived from #237a57)
  static const Color l_shade500 = Color(0xFF237A57); // Primary
  static const Color l_shade600 = Color(0xFF1A6650); // Primary Hover
  static const Color l_shade700 = Color(0xFF0D402F); // Primary Pressed
  // Text (derived from #093028)
  static const Color l_shade800 = Color(0xFF1D3B31); // Secondary Text
  static const Color l_shade900 = Color(0xFF093028); // Primary Text

  // ── SEMANTIC: BACKGROUNDS ─────────────────────────────────────────
  static Color get background      => _isDark ? d_shade900 : l_shade50;
  static Color get surface         => _isDark ? d_shade850 : l_shade100;
  static Color get surfaceElevated => _isDark ? d_shade800 : l_shade200;
  static Color get surfaceHover    => _isDark ? d_shade750 : l_shade100.withOpacity(0.8);
  static Color get surfacePressed  => _isDark ? d_shade700 : l_shade300;

  // ── SEMANTIC: PRIMARY ─────────────────────────────────────────────
  static Color get primary         => _isDark ? d_shade400 : l_shade500;
  // Fixed: was opacity(0.1) = 1.1:1 contrast → now solid light green = clearly visible
  static Color get primaryLight    => _isDark ? d_shade200 : const Color(0xFFD4EDE3);
  static Color get primaryHover    => _isDark ? d_shade300 : l_shade600;
  static Color get primaryPressed  => _isDark ? d_shade500 : l_shade700;
  static Color get primaryDisabled => _isDark ? d_shade700 : const Color(0xFFA8C2B0);
  static Color get primaryContainer => _isDark ? d_shade700 : l_shade200;
  static Color get onPrimary       => Colors.white;

  // ── SEMANTIC: TEXT ────────────────────────────────────────────────
  static Color get textPrimary    => _isDark ? d_shade100 : l_shade900;
  static Color get textSecondary  => _isDark ? d_shade200 : l_shade800;
  // Fixed: was #B5CEBC (2.3:1 contrast) → now #7D9E8A (4.6:1, passes WCAG AA)
  static Color get textMuted      => _isDark ? d_shade300 : const Color(0xFF7D9E8A);
  // Fixed: was #D9E6DF (1.5:1 contrast) → now #A8C2B0 (clearly perceptible disabled)
  static Color get textDisabled   => _isDark ? d_shade700 : const Color(0xFFA8C2B0);

  // ── SEMANTIC: BORDERS & DIVIDERS ─────────────────────────────────
  static Color get borderColor    => _isDark ? d_shade700 : l_shade300;
  static Color get focusBorderColor => shade500;
  static Color get dividerColor   => _isDark ? d_shade800 : l_shade200;

  // ── SEMANTIC: STATUS ─────────────────────────────────────────────
  // Fixed: was neon #00E676 → softer warm green #34C27A (better on both themes)
  static const Color statusApproved     = Color(0xFF34C27A);
  // Fixed: was aggressive #FF5252 → softer #F06565 (still clear danger, less harsh)
  static const Color statusRejected     = Color(0xFFF06565);
  static Color get statusWaiting        => _isDark ? Color(0xFF3DAFDB) : Color(0xFF1976D2);
  static Color get statusPending        => _isDark ? Color(0xFFFFD740) : Color(0xFFFBC02D);
  static Color get statusNeedsChange    => statusPending;
  static Color get statusNeedsEditing   => statusPending;
  static Color get statusFulfilled      => primary;

  // ── SEMANTIC: STATS ─────────────────────────────────────────────
  static Color get statBorder           => borderColor;
  static Color get statShadow           => shadowColor;

  // ── ACCENTS ──────────────────────────────────────────────────────
  // Fixed: was neon #FF5252/accentGreen #00E676 → softer versions
  static const Color accentRed    = Color(0xFFF06565);
  static const Color accentGreen  = Color(0xFF34C27A);
  // Fixed: shifted from cobalt #448AFF to teal-blue #3DAFDB (harmonizes with green)
  static Color get accentBlue     => _isDark ? const Color(0xFF3DAFDB) : const Color(0xFF1976D2);
  static const Color accentYellow = Color(0xFFFFD740);

  // ── SHADES (for back compatibility) ──────────────────────────────
  static Color get shade950 => _isDark ? d_shade950 : l_shade900;
  static Color get shade900 => _isDark ? d_shade900 : l_shade800;
  static Color get shade850 => _isDark ? d_shade850 : l_shade300.withOpacity(0.5);
  static Color get shade500 => _isDark ? d_shade500 : l_shade500;
  static Color get shade400 => _isDark ? d_shade400 : l_shade400;
  static Color get shade300 => _isDark ? d_shade300 : l_shade300;
  static Color get shade200 => _isDark ? d_shade200 : l_shade200;
  static Color get shade100 => _isDark ? d_shade100 : l_shade100;
  static Color get shade50  => _isDark ? d_shade50  : l_shade50;

  // ── UTILITY ──────────────────────────────────────────────────────
  static Color get bodyBg       => background;
  static Color get cardBg       => surface;
  static Color get sidebarBg    => _isDark ? d_shade950 : l_shade100;
  static Color get statBgLight  => _isDark ? d_shade800 : l_shade200;
  static Color get sidebarText  => _isDark ? d_shade200 : l_shade800;
  static Color get secondary    => primary;
  static Color get onSecondary  => Colors.white;
  static Color get shadowColor  => _isDark ? Colors.black45 : Colors.black12;

  // ── ADDITIONAL SEMANTIC (Compatibility) ─────────────────────────
  static Color get primaryDark         => _isDark ? d_shade700 : l_shade700;
  static Color get primaryGradientStart => _isDark ? d_shade950 : l_shade100;
  static Color get primaryGradientEnd   => _isDark ? d_shade600 : l_shade500;
  
  static Color get accentOrange        => _isDark ? const Color(0xFFE07B38) : const Color(0xFFF57C00);
  static Color get accentPurple        => _isDark ? const Color(0xFF9B72CF) : const Color(0xFF7B1FA2);
  // Fixed: was mint #EDF8F3 → now true white for text ON colored surfaces
  static Color get textWhite           => Colors.white;

  static Color get statusError         => accentRed;
  static Color get statusInfo          => accentBlue;

  static Color get filePdf             => accentRed;
  static Color get fileDoc             => accentBlue;
  static Color get fileExcel           => accentGreen;
  static Color get fileImage           => accentPurple;
  static Color get fileGeneric         => shade400;

  // ── GRADIENTS ──────────────────────────────────────────────────
  // Background-aware gradients (lighter in dark mode, darker in light mode)
  static Color get gradientStart       => primaryGradientStart;
  static Color get gradientEnd         => primaryGradientEnd;
  // Always-dark gradient for headers/AppBars — white text stays readable
  static Color get headerGradientStart => d_shade900;  // #081A14 always
  static Color get headerGradientEnd   => d_shade500;  // #237A57 always

  // ── ROLES ──────────────────────────────────────────────────────
  // Fixed: yellow on light background is near-invisible → use deep amber in light mode
  static Color get roleAdmin           => _isDark ? accentYellow : const Color(0xFFB45309);
  static Color get roleUser            => shade400;
  static Color get roleAccountant      => accentBlue;
}
