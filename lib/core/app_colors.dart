import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
//   C I R C U I T   B L U E
//   ─────────────────────────────────────────────────────────────────────────
//   A color system built like an electrical circuit.
//   Not layers. Not roles. ENERGY STATES.
//
//   Every color in this system is either:
//     ① A CONDUCTOR  — carries the signal without resistance (bg · surfaces)
//     ② THE SIGNAL   — the live current (primary · interactive)
//     ③ A RESISTOR   — slows the signal to readable (text · borders)
//     ④ A FREQUENCY  — the signal rendered as rhythm (gradients)
//     ⑤ A RESONANCE  — a tuned frequency for a specific emotion (status)
//
//   Typography: Poppins — geometric, confident, carries signal perfectly.
//   Palette:    90-step azure #F9FCFF → #000406, rebuilt from first principles.
//
//   Dark  → "Live Circuit" — energized, humming, the board is powered on
//   Light → "Blueprint"   — the schematic before power, crisp on white paper
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ─── FONT SYSTEM ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
//  CIRCUIT BLUE · Typography System
//  Font: Poppins (Google Fonts) — geometric, confident, zero-noise.
//  "The font carries the signal. The weight is the amplitude."
// ─────────────────────────────────────────────────────────────────────────────

class AppFonts {
  AppFonts._();

  // Weight constants (Poppins ships weights 100–900)
  static const FontWeight thin       = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light      = FontWeight.w300;
  static const FontWeight regular    = FontWeight.w400;
  static const FontWeight medium     = FontWeight.w500;
  static const FontWeight semiBold   = FontWeight.w600;
  static const FontWeight bold       = FontWeight.w700;
  static const FontWeight extraBold  = FontWeight.w800;
  static const FontWeight black      = FontWeight.w900;

  // ── Preset styles via google_fonts ─────────────────────────────────────
  // All styles are factory functions so color is passed at call site.
  // This keeps the design system decoupled from specific colors.

  /// Display — large numbers, totals, hero stats  (w900 · 32px)
  static TextStyle display({Color? color, double size = 32}) =>
      GoogleFonts.poppins(
        fontWeight: black, fontSize: size,
        letterSpacing: -1.2, height: 1.1, color: color,
      );

  /// Heading — page titles, section headers  (w700 · 20px)
  static TextStyle heading({Color? color, double size = 20}) =>
      GoogleFonts.poppins(
        fontWeight: bold, fontSize: size,
        letterSpacing: -0.4, height: 1.25, color: color,
      );

  /// Title — card titles, dialog headers  (w600 · 16px)
  static TextStyle title({Color? color, double size = 16}) =>
      GoogleFonts.poppins(
        fontWeight: semiBold, fontSize: size,
        letterSpacing: -0.2, height: 1.3, color: color,
      );

  /// Subtitle — secondary card info  (w500 · 14px)
  static TextStyle subtitle({Color? color, double size = 14}) =>
      GoogleFonts.poppins(
        fontWeight: medium, fontSize: size,
        letterSpacing: 0, height: 1.4, color: color,
      );

  /// Body — main reading voice  (w400 · 14px)
  static TextStyle body({Color? color, double size = 14}) =>
      GoogleFonts.poppins(
        fontWeight: regular, fontSize: size,
        letterSpacing: 0, height: 1.6, color: color,
      );

  /// Label — buttons, tabs, chips, nav items  (w500 · 13px)
  static TextStyle label({Color? color, double size = 13, bool upper = false}) =>
      GoogleFonts.poppins(
        fontWeight: medium, fontSize: size,
        letterSpacing: upper ? 0.8 : 0.1, height: 1.4, color: color,
      );

  /// Caption — timestamps, hints, metadata  (w300 · 11px)
  static TextStyle caption({Color? color, double size = 11}) =>
      GoogleFonts.poppins(
        fontWeight: light, fontSize: size,
        letterSpacing: 0.2, height: 1.5, color: color,
      );

  /// Number — financial amounts, counters  (w600 · 13px · tabular)
  static TextStyle number({Color? color, double size = 13}) =>
      GoogleFonts.poppins(
        fontWeight: semiBold, fontSize: size,
        letterSpacing: -0.3, height: 1.2, color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── Theme-level text theme (plug into ThemeData.textTheme) ──────────────
  /// Returns a complete TextTheme using Poppins for the given brightness.
  static TextTheme textTheme({required bool isDark}) {
    final primary   = isDark ? const Color(0xFFE4F1FB) : const Color(0xFF0F172A); // Slate 900
    final secondary = isDark ? const Color(0xFFBDD4E8) : const Color(0xFF334155); // Slate 700
    final muted     = isDark ? const Color(0xFF82AECE) : const Color(0xFF64748B); // Slate 500
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge : display(color: primary,   size: 57),
      displayMedium: display(color: primary,   size: 45),
      displaySmall : display(color: primary,   size: 36),
      headlineLarge: heading(color: primary,   size: 32),
      headlineMedium:heading(color: primary,   size: 28),
      headlineSmall: heading(color: primary,   size: 24),
      titleLarge   : title(color: primary,     size: 22),
      titleMedium  : title(color: primary,     size: 16),
      titleSmall   : title(color: secondary,   size: 14),
      bodyLarge    : body(color: primary,      size: 16),
      bodyMedium   : body(color: secondary,    size: 14),
      bodySmall    : body(color: muted,        size: 12),
      labelLarge   : label(color: primary,     size: 14),
      labelMedium  : label(color: secondary,   size: 12),
      labelSmall   : caption(color: muted,     size: 11),
    );
  }
}

// ─── COLOR SYSTEM ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static bool _isDark = true;
  static void setTheme(bool isDark) => _isDark = isDark;
  static bool get isDark => _isDark;

  // ══════════════════════════════════════════════════════════════════════════
  //  ① CONDUCTORS  — Raw material. Built fresh from the 90-step blue spectrum.
  //
  //  Dark conductors: violet-shifted navy.
  //  The hue drifts 8° toward violet (210° → 218°) as surfaces get deeper.
  //  This creates warmth — the live circuit is warmer than cold dead blue.
  //
  //  Light conductors: desaturated azure — Blueprint paper.
  //  Not white. The paper a naval architect uses. Slightly blue, slightly cool.
  // ══════════════════════════════════════════════════════════════════════════

  // ·· Dark Board (private, never touch in widgets) ··
  static const Color _board0 = Color(0xFF060912); // void — deepest ground plane
  static const Color _board1 = Color(0xFF091221); // substrate — main dark bg
  static const Color _board2 = Color(0xFF0D1C35); // trace layer — cards
  static const Color _board3 = Color(0xFF142847); // via — elevated surfaces
  static const Color _board4 = Color(0xFF1C3660); // bus — hover state
  static const Color _board5 = Color(0xFF254878); // junction — border / divider
  static const Color _board6 = Color(0xFF325E94); // connector — muted border
  static const Color _board7 = Color(0xFF4D7DB0); // lead — disabled / muted text
  static const Color _board8 = Color(0xFF82AECE); // surface trace — secondary text
  static const Color _board9 = Color(0xFFBDD4E8); // top copper — primary text dim
  static const Color _boardA = Color(0xFFE4F1FB); // solder mask — primary text bright

  // ·· Light Premium (Refined Blueprint) ··
  static const Color _paper0 = Color(0xFFF8FAFC); // Slate 50 — clean, crisp background
  static const Color _paper1 = Color(0xFFFFFFFF); // White — cards
  static const Color _paper2 = Color(0xFFF1F5F9); // Slate 100 — light tint / elevated
  static const Color _paper3 = Color(0xFFE2E8F0); // Slate 200 — grid line / hover
  static const Color _paper4 = Color(0xFFCBD5E1); // Slate 300 — construction line / border
  static const Color _paper5 = Color(0xFF64748B); // Slate 500 — clear prominent muted text
  static const Color _paper6 = Color(0xFF334155); // Slate 700 — deep secondary text
  static const Color _paper7 = Color(0xFF0F172A); // Slate 900 — crisp primary text

  // ══════════════════════════════════════════════════════════════════════════
  //  ② THE SIGNAL  — The live current. One chromatic event per focus zone.
  //
  //  "The signal does not need to shout.
  //   In a monochromatic circuit, even a whisper is thunder."
  // ══════════════════════════════════════════════════════════════════════════

  static const Color _live      = Color(0xFF007AFF); // the current — brand blue (slightly warm Azure)
  static const Color _liveGlow  = Color(0xFF3DA8FF); // energized — dark mode primary
  static const Color _liveHot   = Color(0xFF71C1FF); // overdriven — dark hover
  static const Color _liveDeep  = Color(0xFF005FD4); // grounded — light hover
  static const Color _liveSunk  = Color(0xFF0048AA); // shorted — light pressed

  // ══════════════════════════════════════════════════════════════════════════
  //  SEMANTIC CIRCUIT MAP
  //  Use these in every widget — never the private atoms above.
  //  Organized by energy state, not by visual zone.
  // ══════════════════════════════════════════════════════════════════════════

  // ── Ground plane (lowest energy — ambient space) ───────────────────────
  static Color get background      => _isDark ? _board1   : _paper0;
  static Color get surface         => _isDark ? _board2   : _paper1;
  static Color get surfaceElevated => _isDark ? _board3   : _paper1;
  static Color get surfaceHover    => _isDark ? _board4   : _paper2;
  static Color get surfacePressed  => _isDark ? _board5   : _paper3;
  static Color get sidebarBg       => _isDark ? _board0   : _paper1;

  // ── Live current (the signal — highest energy) ─────────────────────────
  static Color get primary          => _isDark ? _liveGlow : _live;
  static Color get primaryHover     => _isDark ? _liveHot  : _liveDeep;
  static Color get primaryPressed   => _isDark ? _live     : _liveSunk;
  static Color get primaryDisabled  => _isDark ? _board5   : _paper3;
  static Color get primaryContainer => _isDark ? _board4   : _paper2;
  static Color get primaryLight     => _isDark ? _board3   : _paper3;
  static Color get onPrimary        => Colors.white;
  static Color get focusBorderColor => _isDark ? _liveGlow : _live;

  // ── Voltage (potential difference — creates readable text) ─────────────
  static Color get textPrimary   => _isDark ? _boardA : _paper7;
  static Color get textSecondary => _isDark ? _board9 : _paper6;
  static Color get textMuted     => _isDark ? _board8 : _paper5;
  static Color get textDisabled  => _isDark ? _board6 : _paper4;
  static Color get textInverse   => _isDark ? _paper7 : Colors.white;
  static Color get textWhite     => Colors.white;
  static Color get sidebarText   => _isDark ? _board9 : _paper6;

  // ── Resistance (the structural skeleton) ───────────────────────────────
  static Color get borderColor   => _isDark ? _board5 : l_shade300; // Clear, visible premium blue
  static Color get dividerColor  => _isDark ? _board2 : _paper2;

  // ── Frequencies (gradients — the signal rendered as rhythm) ─────────────

  /// POWER ON — Signature hero gradient. The board lights up from left to right.
  /// Dark: cold void → electric corona. The moment a device wakes.
  /// Light: blueprint depth → the live signal. Authority becoming action.
  static LinearGradient get powerGradient => LinearGradient(
    colors: _isDark
        ? [const Color(0xFF002060), _liveGlow]
        : [_paper7, _live],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// AMBIENT FIELD — Background. Nearly invisible. The ground hum.
  static LinearGradient get fieldGradient => LinearGradient(
    colors: _isDark
        ? [_board2, _board1]
        : [_paper0, _paper2],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// ACTIVE PUSH — Button/FAB. The signal surging through a button.
  /// Creates internal luminosity — the element glows as if powered.
  static LinearGradient get pushGradient => LinearGradient(
    colors: _isDark
        ? [const Color(0xFF45B2FF), const Color(0xFF005ED4)]
        : [const Color(0xFF1A8FFF), const Color(0xFF004DBB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// HALO FIELD — Stat cards and chart headers. Electromagnetic aura above key data.
  static LinearGradient get haloGradient => LinearGradient(
    colors: [
      (_isDark ? _liveGlow : _live).withOpacity(_isDark ? 0.18 : 0.09),
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// TRACE SCAN — Skeleton shimmer. Signal scanning the circuit looking for data.
  static LinearGradient get scanGradient => LinearGradient(
    colors: _isDark
        ? [_board2, _board4, _board2]
        : [_paper2, Colors.white, _paper2],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// PANEL — Sidebar/drawer zone. A different electrical region of the circuit.
  static LinearGradient get panelGradient => LinearGradient(
    colors: _isDark
        ? [_board0, const Color(0xFF0B1828)]
        : [_paper1, _paper0],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  // Legacy gradient aliases — zero breaking changes
  static LinearGradient get primaryGradient    => pushGradient;
  static LinearGradient get heroGradient       => powerGradient;
  static LinearGradient get headerGradient     => powerGradient;
  static LinearGradient get interactionGradient=> pushGradient;
  static LinearGradient get backgroundGradient => fieldGradient;
  static LinearGradient get glowGradient       => haloGradient;
  static LinearGradient get sidebarGradient    => panelGradient;
  static LinearGradient get shimmerGradient    => scanGradient;
  static LinearGradient get accentGradient     => haloGradient;

  static Color get gradientStart        => _isDark ? const Color(0xFF002060) : _paper7;
  static Color get gradientEnd          => _isDark ? _liveGlow               : _live;
  static Color get primaryGradientStart => gradientStart;
  static Color get primaryGradientEnd   => gradientEnd;
  static Color get headerGradientStart  => _isDark ? _board1 : _paper7;
  static Color get headerGradientEnd    => _isDark ? _liveGlow : _live;

  // ── Resonances (status — tuned signal frequencies) ────────────────────
  //
  // Each status color is a DIFFERENT frequency. They must never feel similar.
  // Chosen for maximum differentiation AND legibility on both ground planes.
  //
  // ✅ 530nm — Emerald. Go. Confirmed. Alive. Not the cheap RGB green.
  static const Color statusApproved = Color(0xFF00A878); // 530nm shifted — teal-emerald
  static const Color statusSuccess  = Color(0xFF00A878);
  static const Color accentGreen    = Color(0xFF00A878);

  // ❌ 620nm — Vermillion. Urgent. Warm. Not alarm-red. Considered-red.
  static const Color statusRejected = Color(0xFFE83D3D);
  static const Color statusError    = Color(0xFFE83D3D);
  static const Color accentRed      = Color(0xFFE83D3D);

  // ⏳ 575nm — Amber. Deliberate.
  static Color get statusPending      => _isDark ? const Color(0xFFFABD2F) : const Color(0xFFD97706);
  static Color get statusNeedsChange  => statusPending;
  static Color get statusNeedsEditing => statusPending;
  static const Color accentYellow     = Color(0xFFF59E0B);

  // ℹ️ THE BRAND — Information IS the signal. When waiting: show the live current.
  static Color get statusWaiting   => _isDark ? _liveGlow : _live;
  static Color get statusInfo      => statusWaiting;
  static Color get statusFulfilled => primary;

  // ── Companion accents ─────────────────────────────────────────────────
  static Color get accentBlue   => _isDark ? _liveGlow : _live;
  static Color get accentOrange => _isDark ? const Color(0xFFFF9444) : const Color(0xFFD95E00);
  static Color get accentPurple => _isDark ? const Color(0xFFAB8FFF) : const Color(0xFF5433C8);

  // ── Role badges ───────────────────────────────────────────────────────
  static Color get roleAdmin      => _isDark ? const Color(0xFFFABD2F) : const Color(0xFF9A5F00);
  static Color get roleUser       => _isDark ? _board7                  : _paper5;
  static Color get roleAccountant => accentBlue;

  // ── File type identifiers ─────────────────────────────────────────────
  static Color get filePdf     => statusRejected;
  static Color get fileDoc     => accentBlue;
  static Color get fileExcel   => statusApproved;
  static Color get fileImage   => accentPurple;
  static Color get fileGeneric => _isDark ? _board7 : _paper5;

  // ── System utilities ──────────────────────────────────────────────────
  static Color get bodyBg       => background;
  static Color get cardBg       => surface;
  static Color get statBgLight  => surfaceElevated;
  static Color get secondary    => primary;
  static Color get onSecondary  => Colors.white;
  static Color get shadowColor  => _isDark
      ? Colors.black.withOpacity(0.65)
      : const Color(0xFF0B3570).withOpacity(0.10);
  static Color get statBorder   => borderColor;
  static Color get statShadow   => shadowColor;
  static Color get primaryDark  => _isDark ? const Color(0xFF002060) : _liveSunk;

  // ── Shade bridge (legacy numeric refs — silently remapped) ────────────
  static Color get shade950 => _isDark ? _board0 : _paper7;
  static Color get shade900 => _isDark ? _board1 : _paper6;
  static Color get shade850 => _isDark ? _board3 : _paper3;
  static Color get shade500 => _isDark ? _liveGlow : _live;
  static Color get shade400 => _isDark ? _board7 : _paper5;
  static Color get shade300 => _isDark ? _board8 : _paper4;
  static Color get shade200 => _isDark ? _boardA : _paper3;
  static Color get shade100 => _isDark ? _board3 : _paper2;
  static Color get shade50  => _isDark ? _board1 : _paper0;

  // ── Raw scale constants (for any component that references them directly)
  static const Color d_shade950 = Color(0xFF060912);
  static const Color d_shade900 = Color(0xFF091221);
  static const Color d_shade850 = Color(0xFF0D1C35);
  static const Color d_shade800 = Color(0xFF142847);
  static const Color d_shade750 = Color(0xFF1C3660);
  static const Color d_shade700 = Color(0xFF254878);
  static const Color d_shade600 = Color(0xFF325E94);
  static const Color d_shade500 = Color(0xFF3DA8FF);
  static const Color d_shade400 = Color(0xFF71C1FF);
  static const Color d_shade300 = Color(0xFF82AECE);
  static const Color d_shade200 = Color(0xFFBDD4E8);
  static const Color d_shade100 = Color(0xFFE4F1FB);
  static const Color d_shade50  = Color(0xFFF0F8FF);

  static const Color l_shade50  = Color(0xFFF5F9FF);
  static const Color l_shade100 = Color(0xFFEAF3FF);
  static const Color l_shade200 = Color(0xFFD3E8FF);
  static const Color l_shade300 = Color(0xFFB5D5F8);
  static const Color l_shade400 = Color(0xFF7AAED8);
  static const Color l_shade500 = Color(0xFF007AFF);
  static const Color l_shade600 = Color(0xFF005FD4);
  static const Color l_shade700 = Color(0xFF0048AA);
  static const Color l_shade800 = Color(0xFF1E5BA8);
  static const Color l_shade900 = Color(0xFF0B3570);

  static const Color p50   = Color(0xFFF5F9FF);
  static const Color p100  = Color(0xFFEAF3FF);
  static const Color p200  = Color(0xFFD3E8FF);
  static const Color p300  = Color(0xFFB5D5F8);
  static const Color p400  = Color(0xFF71C1FF);
  static const Color p500  = Color(0xFF3DA8FF);
  static const Color p600  = Color(0xFF007AFF);
  static const Color p700  = Color(0xFF005FD4);
  static const Color p800  = Color(0xFF0048AA);
  static const Color p900  = Color(0xFF0B3570);
  static const Color p950  = Color(0xFF060912);
  static const Color pTint = Color(0xFFEAF3FF);
}
