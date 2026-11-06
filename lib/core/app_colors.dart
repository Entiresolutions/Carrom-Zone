import 'package:flutter/material.dart';
import 'theme_piece_style.dart';

enum BoardThemeType {
  mahogany,
  emerald,
  midnight,
  walnutClub,
  royalIndigo,
  emeraldLounge,
  oceanBreeze,
  sakuraStudio,
  neonArena,
  goldenPalace,
  cosmicElite,
}

/// Centralized color tokens for the Modern Carrom Club design identity.
/// Light luxury theme combining warm alabaster/ivory surfaces, light wood tones,
/// polished antique gold accents, crisp dark typography, and soft modern shadows.
class AppColors {
  // ─── Primary Carrom Club Base (Warm Ivory, Rich Sandalwood & Alabaster) ─
  static const Color bgLight = Color(0xFFF5EFE6);
  static const Color bgLightGradientTop = Color(0xFFFAF6EE);
  static const Color bgLightGradientMid = Color(0xFFF2EBDD);
  static const Color bgLightGradientBottom = Color(0xFFE6DBC9);

  // Backward-compatible dark constants referenced by shaders/painters
  static const Color bgDark = Color(0xFF162030);
  static const Color bgGradientTop = Color(0xFFFAF6EE);
  static const Color bgGradientMid = Color(0xFFF2EBDD);
  static const Color bgGradientBottom = Color(0xFFE6DBC9);

  // ─── Club Surface & Card Tokens (Warm Ivory Satin with Brass Trim) ────────
  static const Color cardBg = Color(0xFFFAF6EF);
  static const Color cardBgLight = Color(0xFFF5EFE5);
  static const Color cardBgElevated = Color(0xFFEDE4D4);
  static const Color cardBgGlass = Color(0xF5FAF6EF);
  static const Color cardBorder = Color(0x3DD4C4AC);
  static const Color cardBorderSubtle = Color(0x20D4C4AC);

  // ─── Sophisticated Club Navy Tokens ───────────────────────────────────────
  static const Color navyPrimary = Color(0xFF14243B);
  static const Color navySurface = Color(0xFF1B3150);
  static const Color navyLight = Color(0xFF2A4A75);
  static const Color navyAccent = Color(0xFF38BDF8);

  // ─── Muted Heritage Teal & Natural Wood Accents ───────────────────────────
  static const Color tealPrimary = Color(0xFF137A6D);
  static const Color tealLight = Color(0xFF189686);
  static const Color tealDark = Color(0xFF0D5E54);
  static const Color tealSurface = Color(0xFFD6F5EE);

  static const Color woodLight = Color(0xFFB07348);
  static const Color woodPrimary = Color(0xFF7A4B2A);
  static const Color woodDark = Color(0xFF502E19);
  static const Color woodDeep = Color(0xFF361B0E);

  // ─── Warm Typography Hierarchy (Deep Club Charcoal & Slate) ───────────────
  static const Color ivory = Color(0xFF162030);
  static const Color ivoryWarm = Color(0xFF26374E);
  static const Color ivoryMuted = Color(0xFF4D5E75);

  static const Color textPrimary = Color(0xFF162030);
  static const Color textSecondary = Color(0xFF4D5E75);
  static const Color textMuted = Color(0xFF7E8EA4);

  // ─── High-Contrast Polished Antique Brass & Gold Accents ──────────────────
  static const Color gold = Color(0xFFC5993B);
  static const Color goldBright = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFB8851E);
  static const Color goldDark = Color(0xFF8B6415);
  static const Color goldDeep = Color(0xFF6B4B0C);
  static const Color dividerGold = Color(0x28B8851E);

  // ─── Mode Card Surface Gradients ──────────────────────────────────────────
  static const Color goldCardBorder = Color(0xFFD8AA42);
  static const Color blueCardBorder = Color(0xFF2B80B8);
  static const Color greenCardBorder = Color(0xFF208E69);

  // ─── Theme 1: Classic Club Wood (Rosewood Frame & Natural Birch Surface) ──
  static const Color boardSurface = Color(0xFFE8D3B0);
  static const Color boardSurfaceLight = Color(0xFFF4E6CC);
  static const Color boardSurfaceDark = Color(0xFFD4B98E);
  static const Color boardSurfaceHighlight = Color(0xFFC4A474);

  // ─── Theme 2: Emerald Championship (Muted Teal Baize & Walnut Frame) ──────
  static const Color emeraldSurface = Color(0xFF1B524C);
  static const Color emeraldSurfaceLight = Color(0xFF256B63);
  static const Color emeraldSurfaceDark = Color(0xFF113834);

  // ─── Theme 3: Midnight Club Lounge (Architectural Navy & Ebony Frame) ─────
  static const Color midnightSurface = Color(0xFF182438);
  static const Color midnightSurfaceLight = Color(0xFF22334E);
  static const Color midnightSurfaceDark = Color(0xFF0E1624);

  // ─── Theme 4: Walnut Club (American Walnut & Warm Honey Amber) ────────────
  static const Color walnutSurface = Color(0xFFE4C795);
  static const Color walnutSurfaceLight = Color(0xFFF0DCB4);
  static const Color walnutSurfaceDark = Color(0xFFCAAA73);

  // ─── Theme 5: Royal Indigo (Sapphire Velvet & Silver Platinum) ────────────
  static const Color royalIndigoSurface = Color(0xFF24225C);
  static const Color royalIndigoSurfaceLight = Color(0xFF312E81);
  static const Color royalIndigoSurfaceDark = Color(0xFF16153E);

  // ─── Theme 6: Emerald Lounge (Forest Velvet & Mahogany Gold) ─────────────
  static const Color emeraldLoungeSurface = Color(0xFF044E39);
  static const Color emeraldLoungeSurfaceLight = Color(0xFF065F46);
  static const Color emeraldLoungeSurfaceDark = Color(0xFF023426);

  // ─── Theme 7: Ocean Breeze (Turquoise Lagoon & Driftwood) ─────────────────
  static const Color oceanBreezeSurface = Color(0xFF0E4759);
  static const Color oceanBreezeSurfaceLight = Color(0xFF155E75);
  static const Color oceanBreezeSurfaceDark = Color(0xFF083340);

  // ─── Theme 8: Sakura Studio (Pale Cherry Blossom & Rosewood) ──────────────
  static const Color sakuraSurface = Color(0xFFF8D3DF);
  static const Color sakuraSurfaceLight = Color(0xFFFCE7F3);
  static const Color sakuraSurfaceDark = Color(0xFFE8AEBF);

  // ─── Theme 9: Neon Arena (Cyber Matte Carbon & Laser Neon) ────────────────
  static const Color neonArenaSurface = Color(0xFF131122);
  static const Color neonArenaSurfaceLight = Color(0xFF1E1B2E);
  static const Color neonArenaSurfaceDark = Color(0xFF0C0A17);

  // ─── Theme 10: Golden Palace (Imperial Silk & 24K Gold) ───────────────────
  static const Color goldenPalaceSurface = Color(0xFFFDE68A);
  static const Color goldenPalaceSurfaceLight = Color(0xFFFEF3C7);
  static const Color goldenPalaceSurfaceDark = Color(0xFFE6C862);

  // ─── Theme 11: Cosmic Elite (Nebula Violet & Celestial Titanium) ──────────
  static const Color cosmicEliteSurface = Color(0xFF1E0A45);
  static const Color cosmicEliteSurfaceLight = Color(0xFF2E1065);
  static const Color cosmicEliteSurfaceDark = Color(0xFF12052C);

  // ─── Pockets & Board Details ──────────────────────────────────────────────
  static const Color pocketHole = Color(0xFF090C10);
  static const Color pocketRing = Color(0xFF2C1910);
  static const Color pocketShadow = Color(0xFF000000);
  static const Color boardLineDark = Color(0xFF2B1D16);
  static const Color boardCrimson = Color(0xFFC83232);

  // ─── Carrom Coins & Striker ───────────────────────────────────────────────
  static const Color whitePiece = Color(0xFFFAF6EE);
  static const Color whitePieceRing = Color(0xFFC9B99F);
  static const Color blackPiece = Color(0xFF1E2229);
  static const Color blackPieceRing = Color(0xFF434B57);
  static const Color queenPiece = Color(0xFFD92638);
  static const Color queenPieceRing = Color(0xFF9E1926);

  static const Color strikerBody = Color(0xFFFCF8F0);
  static const Color strikerRing = Color(0xFFD4AF37);
  static const Color strikerGlow = Color(0xFFE6C665);

  // ─── Semantic Status Accents ──────────────────────────────────────────────
  static const Color accentGreen = Color(0xFF2EC486);
  static const Color accentRed = Color(0xFFE5484D);
  static const Color accentBlue = Color(0xFF4B96F3);
  static const Color accentAmber = Color(0xFFF5A623);

  // ─── Theme Metadata Helpers ───────────────────────────────────────────────
  static String getThemeName(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'Classic Birch & Rosewood';
      case BoardThemeType.emerald:
        return 'Heritage Club Teal';
      case BoardThemeType.midnight:
        return 'Royal Navy Lounge';
      case BoardThemeType.walnutClub:
        return 'Walnut Club';
      case BoardThemeType.royalIndigo:
        return 'Royal Indigo';
      case BoardThemeType.emeraldLounge:
        return 'Emerald Lounge';
      case BoardThemeType.oceanBreeze:
        return 'Ocean Breeze';
      case BoardThemeType.sakuraStudio:
        return 'Sakura Studio';
      case BoardThemeType.neonArena:
        return 'Neon Arena';
      case BoardThemeType.goldenPalace:
        return 'Golden Palace';
      case BoardThemeType.cosmicElite:
        return 'Cosmic Elite';
    }
  }

  static String getThemeSubtitle(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'Classic Wood';
      case BoardThemeType.emerald:
        return 'Club Teal';
      case BoardThemeType.midnight:
        return 'Dark Lounge';
      case BoardThemeType.walnutClub:
        return 'Amber Wood';
      case BoardThemeType.royalIndigo:
        return 'Velvet Sapphire';
      case BoardThemeType.emeraldLounge:
        return 'Opulent Emerald';
      case BoardThemeType.oceanBreeze:
        return 'Coastal Turquoise';
      case BoardThemeType.sakuraStudio:
        return 'Cherry Blossom';
      case BoardThemeType.neonArena:
        return 'Cyber Carbon';
      case BoardThemeType.goldenPalace:
        return 'Imperial Silk';
      case BoardThemeType.cosmicElite:
        return 'Starlight Nebula';
    }
  }

  static String getThemeDescription(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'Warm natural birchwood surface with hand-rubbed rosewood frame';
      case BoardThemeType.emerald:
        return 'Tournament muted teal baize with walnut & brushed brass trim';
      case BoardThemeType.midnight:
        return 'Deep architectural navy slate with espresso ebony & gold inlay';
      case BoardThemeType.walnutClub:
        return 'Handcrafted dark American walnut tabletop with polished brass brackets';
      case BoardThemeType.royalIndigo:
        return 'Deep royal sapphire-indigo velvet baize with platinum silver trim';
      case BoardThemeType.emeraldLounge:
        return 'Opulent deep forest emerald green felt with antique gold filigree';
      case BoardThemeType.oceanBreeze:
        return 'Aquamarine and turquoise lagoon surface with bleached driftwood frame';
      case BoardThemeType.sakuraStudio:
        return 'Soft warm rosewood and pale cherry blossom ivory baize';
      case BoardThemeType.neonArena:
        return 'High-contrast cyber matte carbon fiber with laser neon vector conduits';
      case BoardThemeType.goldenPalace:
        return 'Imperial champagne silk baize with solid 24k polished gold trim';
      case BoardThemeType.cosmicElite:
        return 'Deep nebula stardust surface with etched starlight constellations';
    }
  }

  static bool isThemePremium(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
      case BoardThemeType.emerald:
      case BoardThemeType.midnight:
        return false;
      default:
        return true;
    }
  }

  static String getThemeAsset(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'assets/images/themes/mahogany.webp';
      case BoardThemeType.emerald:
        return 'assets/images/themes/emerald.webp';
      case BoardThemeType.midnight:
        return 'assets/images/themes/midnight.webp';
      case BoardThemeType.walnutClub:
        return 'assets/images/themes/walnut_club.webp';
      case BoardThemeType.royalIndigo:
        return 'assets/images/themes/royal_indigo.webp';
      case BoardThemeType.emeraldLounge:
        return 'assets/images/themes/emerald_lounge.webp';
      case BoardThemeType.oceanBreeze:
        return 'assets/images/themes/ocean_breeze.webp';
      case BoardThemeType.sakuraStudio:
        return 'assets/images/themes/sakura_studio.webp';
      case BoardThemeType.neonArena:
        return 'assets/images/themes/neon_arena.webp';
      case BoardThemeType.goldenPalace:
        return 'assets/images/themes/golden_palace.webp';
      case BoardThemeType.cosmicElite:
        return 'assets/images/themes/cosmic_elite.webp';
    }
  }

  static String getThemeAssetKey(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'mahogany';
      case BoardThemeType.emerald:
        return 'emerald';
      case BoardThemeType.midnight:
        return 'midnight';
      case BoardThemeType.walnutClub:
        return 'walnut_club';
      case BoardThemeType.royalIndigo:
        return 'royal_indigo';
      case BoardThemeType.emeraldLounge:
        return 'emerald_lounge';
      case BoardThemeType.oceanBreeze:
        return 'ocean_breeze';
      case BoardThemeType.sakuraStudio:
        return 'sakura_studio';
      case BoardThemeType.neonArena:
        return 'neon_arena';
      case BoardThemeType.goldenPalace:
        return 'golden_palace';
      case BoardThemeType.cosmicElite:
        return 'cosmic_elite';
    }
  }

  static String getStrikerAsset(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return 'assets/images/strikers/striker_mahogany.webp';
      case BoardThemeType.emerald:
        return 'assets/images/strikers/striker_emerald.webp';
      case BoardThemeType.midnight:
        return 'assets/images/strikers/striker_midnight.webp';
      case BoardThemeType.walnutClub:
        return 'assets/images/strikers/striker_walnut_club.webp';
      case BoardThemeType.royalIndigo:
        return 'assets/images/strikers/striker_royal_indigo.webp';
      case BoardThemeType.emeraldLounge:
        return 'assets/images/strikers/striker_emerald_lounge.webp';
      case BoardThemeType.oceanBreeze:
        return 'assets/images/strikers/striker_ocean_breeze.webp';
      case BoardThemeType.sakuraStudio:
        return 'assets/images/strikers/striker_sakura_studio.webp';
      case BoardThemeType.neonArena:
        return 'assets/images/strikers/striker_neon_arena.webp';
      case BoardThemeType.goldenPalace:
        return 'assets/images/strikers/striker_golden_palace.webp';
      case BoardThemeType.cosmicElite:
        return 'assets/images/strikers/striker_cosmic_elite.webp';
    }
  }

  static Color getThemeAccent(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return gold;
      case BoardThemeType.emerald:
        return tealLight;
      case BoardThemeType.midnight:
        return accentBlue;
      case BoardThemeType.walnutClub:
        return const Color(0xFFD49A3D);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF6366F1);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF10B981);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF06B6D4);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFF43F5E);
      case BoardThemeType.neonArena:
        return const Color(0xFFD946EF);
      case BoardThemeType.goldenPalace:
        return const Color(0xFFF59E0B);
      case BoardThemeType.cosmicElite:
        return const Color(0xFF8B5CF6);
    }
  }

  static Color getThemePreviewSurface(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.mahogany:
        return boardSurface;
      case BoardThemeType.emerald:
        return emeraldSurface;
      case BoardThemeType.midnight:
        return midnightSurface;
      case BoardThemeType.walnutClub:
        return walnutSurface;
      case BoardThemeType.royalIndigo:
        return royalIndigoSurface;
      case BoardThemeType.emeraldLounge:
        return emeraldLoungeSurface;
      case BoardThemeType.oceanBreeze:
        return oceanBreezeSurface;
      case BoardThemeType.sakuraStudio:
        return sakuraSurface;
      case BoardThemeType.neonArena:
        return neonArenaSurface;
      case BoardThemeType.goldenPalace:
        return goldenPalaceSurface;
      case BoardThemeType.cosmicElite:
        return cosmicEliteSurface;
    }
  }

  /// Theme-specific piece visual styling configuration (Single Source of Truth).
  static ThemePieceStyle getPieceStyle(BoardThemeType theme) =>
      ThemePieceStyle.of(theme);
}
