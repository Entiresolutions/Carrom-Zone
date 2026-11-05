import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Design Tokens for the Championship Club design identity.
/// Warm cream/ivory surfaces, deep emerald green accents, brushed gold borders & highlights,
/// crisp dark-green typography, and soft warm drop shadows.
class ChampionshipColors {
  // ─── Surfaces & Backgrounds ───────────────────────────────────────────────
  /// Warm cream/ivory base screen background (#F7F1E3)
  static const Color background = Color(0xFFF7F1E3);

  /// Slightly richer warm ivory for subtle contrasts (#FAF5EA)
  static const Color backgroundAlt = Color(0xFFFAF5EB);

  /// Pure white card surface (#FFFFFF)
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Off-white subtle card surface (#FFFDF8)
  static const Color cardSurfaceAlt = Color(0xFFFFFDF8);

  /// Soft cream pill fill for badges (#FFFDF5)
  static const Color pillFill = Color(0xFFFFFDF5);

  /// Selected tab / active card tint (#FFFBF2)
  static const Color activeTint = Color(0xFFFFFBF2);

  // ─── Primary Emerald Green Tokens ─────────────────────────────────────────
  /// Deep emerald primary green (~#1B5E3C)
  static const Color primaryGreen = Color(0xFF1B5E3C);

  /// Deep emerald dark green gradient end (~#14492E)
  static const Color primaryGreenDark = Color(0xFF14492E);

  /// Light emerald tint for subtle borders/highlights
  static const Color primaryGreenLight = Color(0xFF267D52);

  /// Subtle translucent green for unselected outlines
  static const Color greenOutline = Color(0x331B5E3C);

  /// Standard green button/tile linear gradient
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E6742),
      Color(0xFF13452B),
    ],
  );

  /// Rich green gradient for circular play buttons
  static const LinearGradient playButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF206C46),
      Color(0xFF123E27),
    ],
  );

  // ─── Brushed Gold Accents & Neutral Borders ──────────────────────────────
  /// Warm gold accent for labels, highlights, "Your Way" (~#B88A2E / #A37820)
  static const Color gold = Color(0xFFB88A2E);

  /// Softer, deep antique gold for labels for optimal readability
  static const Color goldLabel = Color(0xFFA37820);

  /// Bright gold highlight for icons and focused elements (~#D4A745)
  static const Color goldBright = Color(0xFFD4A745);

  /// Gold border for gold badges and active tab indicator (~#D9B86A)
  static const Color goldBorder = Color(0xFFD9B86A);

  /// Clean light neutral card border (#E8E2D0) — softens UI and reduces gold
  static const Color cardBorder = Color(0xFFE8E2D0);

  /// Soft subtle neutral border for dividers and secondary outlines (#F0EBE0)
  static const Color cardBorderSubtle = Color(0xFFF0EBE0);

  /// Gold pill background tint (#FFF8E8)
  static const Color goldPillBg = Color(0xFFFFF8E8);

  /// Selected theme green border (2px emerald green)
  static const Color selectedGreenBorder = Color(0xFF1B5E3C);

  /// Switch control track colors
  static const Color switchTrackActive = Color(0xFF1B5E3C);
  static const Color switchTrackInactive = Color(0xFFDDD7C8);
  static const Color switchThumb = Color(0xFFFFFFFF);

  // ─── Typography & Text Colors ─────────────────────────────────────────────
  /// Primary text: very dark green / near-black (#12261B)
  static const Color textPrimary = Color(0xFF12261B);

  /// Secondary text: muted grey-brown (#6B6B60)
  static const Color textSecondary = Color(0xFF6B6B60);

  /// Muted label/helper text (#8C8C80)
  static const Color textMuted = Color(0xFF8C8C80);

  /// Gold text for labels and headings (deepened to #A37820 for readability)
  static const Color textGold = Color(0xFFA37820);

  /// Pure white text for buttons & green badges
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Light emerald subtitle text on green pills
  static const Color textGreenSubtle = Color(0xFFD2E8DA);

  // ─── Semantic & Indicator Tokens ──────────────────────────────────────────
  /// Notification dot red (#E53935)
  static const Color notificationRed = Color(0xFFE53935);

  // ─── Soft Warm Drop Shadows ───────────────────────────────────────────────
  /// Standard card elevation shadow (soft warm drop shadow)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x145C4418),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Floating bottom dock elevation shadow
  static const List<BoxShadow> floatingDockShadow = [
    BoxShadow(
      color: Color(0x1F47330F),
      blurRadius: 24,
      spreadRadius: 1,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  /// Emerald green button drop shadow
  static const List<BoxShadow> greenButtonShadow = [
    BoxShadow(
      color: Color(0x3D14492E),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  /// Subtle header icon button shadow
  static const List<BoxShadow> iconButtonShadow = [
    BoxShadow(
      color: Color(0x1247330F),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 3),
    ),
  ];
}

/// Centralized Typography System for Championship Club screens.
class ChampionshipTypography {
  /// Header brand title "CARROM ZONE" (Cinzel serif, letter-spaced, dark green)
  static TextStyle brandTitle({
    Color color = ChampionshipColors.textPrimary,
    double fontSize = 19,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.2,
      color: color,
      height: 1.1,
    );
  }

  /// Header brand subtitle "CHAMPIONSHIP CLUB EDITION"
  static TextStyle brandSubtitle({
    Color color = ChampionshipColors.gold,
    double fontSize = 9.0,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: color,
      height: 1.1,
    );
  }

  /// Hero heading line 1: "Play Carrom" (Playfair Display serif bold)
  static TextStyle heroDark({
    Color color = ChampionshipColors.textPrimary,
    double fontSize = 35,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: color,
      height: 1.08,
    );
  }

  /// Hero heading line 2: "Your Way" (Playfair Display serif bold, gold)
  static TextStyle heroGold({
    Color color = ChampionshipColors.gold,
    double fontSize = 35,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: color,
      height: 1.08,
    );
  }

  /// Tagline below hero
  static TextStyle heroTagline({
    Color color = ChampionshipColors.textSecondary,
    double fontSize = 13.5,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.35,
    );
  }

  /// Small caps category / overline label ("TABLE THEME", "SOLO PLAY • TACTICAL AI", etc.)
  static TextStyle overline({
    Color color = ChampionshipColors.textGold,
    double fontSize = 11,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: color,
    );
  }

  /// Card titles ("VS CPU", "PASS & PLAY", "PRACTICE ARENA"): bold, uppercase, dark green, ~22px
  static TextStyle cardTitle({
    Color color = ChampionshipColors.textPrimary,
    double fontSize = 21,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
      color: color,
      height: 1.15,
    );
  }

  /// Theme name ("Ocean Breeze")
  static TextStyle themeTitle({
    Color color = ChampionshipColors.textPrimary,
    double fontSize = 16.5,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: color,
      height: 1.2,
    );
  }

  /// Card / Theme subtitle ("Test your tactical skills against AI", etc.)
  static TextStyle subtitle({
    Color color = ChampionshipColors.textSecondary,
    double fontSize = 12.5,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.3,
    );
  }

  /// Mode segment title ("CLASSIC CARROM", "FREESTYLE POINTS")
  static TextStyle segmentTitle({
    required Color color,
    double fontSize = 11.5,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: color,
      height: 1.15,
    );
  }

  /// Mode segment subtitle ("White vs Black · +3 Queen")
  static TextStyle segmentSubtitle({
    required Color color,
    double fontSize = 9.5,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
    );
  }

  /// Explore pill button text ("EXPLORE ›")
  static TextStyle exploreButtonText({
    Color color = ChampionshipColors.textWhite,
    double fontSize = 11,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: color,
    );
  }

  /// Micro badge text ("PREMIUM", "EASY", etc.)
  static TextStyle microBadge({
    Color color = ChampionshipColors.gold,
    double fontSize = 9.0,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Bottom navigation label ("RULES", "THEMES", "SETTINGS")
  static TextStyle bottomNavLabel({
    required Color color,
    double fontSize = 10.0,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.9,
      color: color,
    );
  } 
}

