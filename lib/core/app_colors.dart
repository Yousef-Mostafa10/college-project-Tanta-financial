import 'package:flutter/material.dart';

/// 🎨 ملف الألوان الموحد للتطبيق كله
/// جميع الأجزاء (Dashboard, Inbox, Archive, Requests, Users) تستخدم هذه الألوان
class AppColors {
  // ─── Primary Colors ───────────────────────────────────────────
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF00796B);

  // ─── Sidebar Colors ───────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF0E6C62);
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarHover = Color(0xFF07584F);

  // ─── Background Colors ────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textMuted = Color(0xFFB0B0B0);

  // ─── Accent Colors ────────────────────────────────────────────
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentYellow = Color(0xFFFFB74D);

  // ─── Status Colors ────────────────────────────────────────────
  static const Color statusApproved = Color(0xFF27AE60);
  static const Color statusRejected = Color(0xFFE74C3C);
  static const Color statusWaiting = Color(0xFF1E88E5);
  static const Color statusPending = Color(0xFFFFB74D);
  static const Color statusNeedsChange = Color(0xFFFFB74D);
  static const Color statusNeedsEditing = Color(0xFFFFB74D);
  static const Color statusFulfilled = Color(0xFF009688);
  static const Color statusCompleted = Color(0xFF27AE60);

  // ─── Border Colors ────────────────────────────────────────────
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor = Color(0xFF00695C);

  // ─── Stat Colors ──────────────────────────────────────────────
  static const Color statBgLight = Color(0xFFF0F8F7);
  static const Color statBorder = Color(0xFFB2DFDB);
  static const Color statShadow = Color(0x1A00695C);

  // ─── Gradient Colors ──────────────────────────────────────────
  static const Color gradientStart = Color(0xFFE0F2F1);
  static const Color gradientEnd = Color(0xFFB2DFDB);

  // ─── Chart Colors ─────────────────────────────────────────────
  static const Color chartLine1 = Color(0xFF009688);
  static const Color chartLine2 = Color(0xFFFFB300);

  // ─── Role Colors ──────────────────────────────────────────────
  static const Color roleAdmin = Color(0xFFE74C3C);
  static const Color roleUser = Color(0xFF27AE60);

  // ─── Filter Colors ────────────────────────────────────────────
  static const Color filterSelectedBg = Color(0xFFE0F2F1);
  static const Color filterSelectedBorder = Color(0xFF00695C);

  // ─── Selection Colors ─────────────────────────────────────────
  static const Color selectionBg = Color(0xFFE0F2F1);
  static const Color selectionBorder = Color(0xFF00695C);
}
