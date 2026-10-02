import 'package:flutter/material.dart';

/// DEFINITIVE INSUREX COLOR PALETTE (LOCKED)
/// 1. MERINO — MAIN BACKGROUND: #F5EEDD (60%)
/// 2. ROCK BLUE — SECONDARY BLUE: #84B3CE (25%)
/// 3. VENICE BLUE — PRIMARY DARK: #16587B (15%)
class InsureXColors {
  // 1. MERINO — Main application background (60%)
  static const Color merino = Color(0xFFF5EEDD);

  // 2. ROCK BLUE — Secondary Blue (25%)
  static const Color rockBlue = Color(0xFF84B3CE);

  // 3. VENICE BLUE — Primary Dark (15%)
  static const Color veniceBlue = Color(0xFF16587B);

  // Restrained semantic status colors (Used sparingly for status only)
  static const Color success = Color(0xFF2E8B57);
  static const Color warning = Color(0xFFC98A00);
  static const Color error = Color(0xFFB54747);

  // Typography
  static const Color heading = Color(0xFF16587B);
  static const Color body = Color(0xFF2F4553);
  static const Color secondaryText = Color(0xFF5F7480);
}

/// Centralized Theme Colors mapping to InsureXColors
class AppColors {
  // Page backgrounds (Pure White per user specification)
  static const Color background = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFFAF6EE); // Slightly beige
  static const Color backgroundSubtle = Color(0xFFFAF6EE);
  static const Color beigeSubtle = Color(0xFFFAF6EE);
  static const Color beigeBorder = Color(0xFFEADBCE);

  // Surface & Cards
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMid = Color(0xFFFAF6EE);
  static const Color surfaceDark = InsureXColors.veniceBlue;

  // Primary Dark (15% Venice Blue)
  static const Color primary = InsureXColors.veniceBlue;
  static const Color primaryBlue = InsureXColors.veniceBlue;
  static const Color brightBlue = InsureXColors.veniceBlue;
  static const Color primaryDark = Color(0xFF0F415C);
  static const Color primaryLight = InsureXColors.rockBlue;
  static const Color primaryContainer = Color(0xFFD6E6F0);

  // Secondary Blue (25% Rock Blue)
  static const Color rockBlue = InsureXColors.rockBlue;
  static const Color rockBlueLight = Color(0xFFB0CFE0);
  static const Color rockBlueDark = Color(0xFF5E94B3);
  static const Color accent = InsureXColors.rockBlue;
  static const Color purple = InsureXColors.rockBlue; // Replaced violet with Rock Blue
  static const Color lightBlue = Color(0xFFDCEAF2);
  static const Color lightPurple = Color(0xFFEFE8D6);

  // Venice Blue & Merino Core Names
  static const Color veniceBlue = InsureXColors.veniceBlue;
  static const Color veniceBlueDark = Color(0xFF0F415C);
  static const Color veniceBlueLight = Color(0xFF216F9A);
  static const Color merino = InsureXColors.merino;
  static const Color merinoLight = Color(0xFFFCFAF5);
  static const Color merinoDark = Color(0xFFEFE8D6);

  // Typography
  static const Color textPrimary = InsureXColors.heading;
  static const Color textDark = InsureXColors.heading;
  static const Color textBody = InsureXColors.body;
  static const Color textSecondary = InsureXColors.secondaryText;
  static const Color textMuted = Color(0xFF8B9FA8);
  static const Color textHint = Color(0xFF8B9FA8);

  // Borders & Dividers (subtle variation of Rock Blue #84B3CE)
  static const Color border = Color(0xFFCDDFE9);
  static const Color borderLight = Color(0xFFE0ECF2);
  static const Color divider = Color(0xFFCDDFE9);

  // Semantic Status Colors
  static const Color success = InsureXColors.success;
  static const Color successLight = Color(0xFFE3F2E9);
  static const Color warning = InsureXColors.warning;
  static const Color warningLight = Color(0xFFFBF4E2);
  static const Color error = InsureXColors.error;
  static const Color danger = InsureXColors.error;
  static const Color dangerLight = Color(0xFFF9E8E8);
  static const Color info = InsureXColors.veniceBlue;
  static const Color infoLight = Color(0xFFDCEAF2);

  // Status Badge Backgrounds
  static const Color statusSubmittedBg = Color(0xFFDCEAF2);
  static const Color statusVerificationBg = Color(0xFFFBF4E2);
  static const Color statusApprovedBg = Color(0xFFE3F2E9);
  static const Color statusRejectedBg = Color(0xFFF9E8E8);
  static const Color statusPendingBg = Color(0xFFFBF4E2);
  static const Color statusMoreInfoBg = Color(0xFFEFE8D6);

  // NO GRADIENTS — Solid LinearGradients resolving to brand colors (NO blue/purple gradients)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [InsureXColors.veniceBlue, InsureXColors.veniceBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coverageGradient = LinearGradient(
    colors: [InsureXColors.veniceBlue, InsureXColors.veniceBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [InsureXColors.veniceBlue, InsureXColors.veniceBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [InsureXColors.success, InsureXColors.success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card & Overlay
  static const Color darkCardBg = InsureXColors.veniceBlue;
  static const Color darkCardText = InsureXColors.merino;
  static const Color darkCardSub = InsureXColors.rockBlue;
  static const Color overlay = Color(0x4016587B);
  static const Color shimmerBase = Color(0xFFEFE8D6);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);
}
