import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Distinct emblem styles engraved or inlaid onto the striker's center.
enum StrikerEmblemType {
  /// Traditional 8-point precision nautical compass star.
  compass,

  /// Elegant floral/sunburst medallion for imperial/botanical themes.
  rosette,

  /// Crisp nautical wave-compass emblem for coastal themes.
  wave,

  /// Concentric targeting reticle with optic crosshairs for futuristic themes.
  cyber,

  /// Four-point pulsar diamond star with micro-rays for celestial themes.
  celestial,
}

/// Comprehensive, single-source-of-truth visual styling configuration
/// for carrom pieces, queen, and striker tailored to each board theme.
class ThemePieceStyle {
  final BoardThemeType theme;

  // ─── White Piece Styling ──────────────────────────────────────────
  final List<Color> whiteGradient;
  final Color whiteRim;
  final Color whiteGroove;
  final Color whiteCenter;
  final Color whiteHighlight;

  // ─── Black Piece Styling ──────────────────────────────────────────
  final List<Color> blackGradient;
  final Color blackRim;
  final Color blackGroove;
  final Color blackCenter;
  final Color blackHighlight;

  // ─── Queen Styling ────────────────────────────────────────────────
  final List<Color> queenGradient;
  final Color queenOuterRing;
  final Color queenStarColor;
  final Color queenCenterPip;
  final Color queenCenterRing;
  final int queenStarPoints;

  // ─── Striker Styling ──────────────────────────────────────────────
  final String strikerMaterialName;
  final List<Color> strikerGradient;
  final Color strikerOuterRim;
  final Color strikerBezelRing;
  final Color strikerAccentRing;
  final Color strikerEmblemColor;
  final Color strikerGemCore;
  final Color strikerGemRim;
  final Color strikerGlow;
  final int strikerStarPoints;
  final StrikerEmblemType strikerEmblemType;

  // ─── Striker VFX & Animation Identity ─────────────────────────────
  final Color launchEffectColor;
  final Color impactFlashColor;
  final Color trailColor;
  final Color powerRingColor;

  const ThemePieceStyle({
    required this.theme,
    required this.whiteGradient,
    required this.whiteRim,
    required this.whiteGroove,
    required this.whiteCenter,
    required this.whiteHighlight,
    required this.blackGradient,
    required this.blackRim,
    required this.blackGroove,
    required this.blackCenter,
    required this.blackHighlight,
    required this.queenGradient,
    required this.queenOuterRing,
    required this.queenStarColor,
    required this.queenCenterPip,
    required this.queenCenterRing,
    this.queenStarPoints = 8,
    required this.strikerMaterialName,
    required this.strikerGradient,
    required this.strikerOuterRim,
    required this.strikerBezelRing,
    required this.strikerAccentRing,
    required this.strikerEmblemColor,
    required this.strikerGemCore,
    required this.strikerGemRim,
    required this.strikerGlow,
    this.strikerStarPoints = 8,
    this.strikerEmblemType = StrikerEmblemType.compass,
    required this.launchEffectColor,
    required this.impactFlashColor,
    required this.trailColor,
    required this.powerRingColor,
  });

  /// Factory lookup returning the exact cohesive piece styling for any theme.
  static ThemePieceStyle of(BoardThemeType theme) {
    switch (theme) {
      // ── 1. Classic Birch & Rosewood ──────────────────────────────
      case BoardThemeType.mahogany:
        return const ThemePieceStyle(
          theme: BoardThemeType.mahogany,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFBF7F0),
            Color(0xFFEFE7DA),
            Color(0xFFDDD2BC),
          ],
          whiteRim: Color(0xFF5A4432),
          whiteGroove: Color(0xFFA6937C),
          whiteCenter: Color(0xFFC7BBA2),
          whiteHighlight: Color(0x99FFFFFF),
          blackGradient: [
            Color(0xFF323232),
            Color(0xFF222222),
            Color(0xFF161616),
            Color(0xFF080808),
          ],
          blackRim: Color(0xFF888888),
          blackGroove: Color(0xFF262626),
          blackCenter: Color(0xFF141414),
          blackHighlight: Color(0x30FFFFFF),
          queenGradient: [
            Color(0xFFEB2C41),
            Color(0xFFD41E33),
            Color(0xFFB51224),
            Color(0xFF6B0612),
          ],
          queenOuterRing: Color(0xFF7A0716),
          queenStarColor: Color(0xFF7A0716),
          queenCenterPip: Color(0xFFD92437),
          queenCenterRing: Color(0xFF56040E),
          queenStarPoints: 8,
          strikerMaterialName: 'Pearl Ivory and Rosewood',
          strikerGradient: [
            Color(0xFFFFFDF8),
            Color(0xFFF7F1E4),
            Color(0xFFEBE0CD),
            Color(0xFFD9CBB2),
          ],
          strikerOuterRim: Color(0xFF3E2D1F),
          strikerBezelRing: Color(0xFF8A7966),
          strikerAccentRing: Color(0xFF9E8B75),
          strikerEmblemColor: Color(0xFF7A6854),
          strikerGemCore: Color(0xFFDED0B9),
          strikerGemRim: Color(0xFF8A7966),
          strikerGlow: Color(0x228A7966),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.compass,
          launchEffectColor: Color(0xFFC7BBA2),
          impactFlashColor: Color(0xFFDDD2BC),
          trailColor: Color(0x40DDD2BC),
          powerRingColor: Color(0xFF8A7966),
        );

      // ── 2. Heritage Club Teal ────────────────────────────────────
      case BoardThemeType.emerald:
        return const ThemePieceStyle(
          theme: BoardThemeType.emerald,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F3ED),
            Color(0xFFE5DFD1),
            Color(0xFFCFC6B3),
          ],
          whiteRim: Color(0xFF26332E),
          whiteGroove: Color(0xFF8F8069),
          whiteCenter: Color(0xFFAFA28D),
          whiteHighlight: Color(0xD9FFFFFF),
          blackGradient: [
            Color(0xFF252A28),
            Color(0xFF171B19),
            Color(0xFF0F1211),
            Color(0xFF070808),
          ],
          blackRim: Color(0xFFE2E8F0),
          blackGroove: Color(0xFF94A3B8),
          blackCenter: Color(0xFF1B201E),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF3859),
            Color(0xFFD61836),
            Color(0xFF930D23),
            Color(0xFF560413),
          ],
          queenOuterRing: Color(0xFFD4AF37),
          queenStarColor: Color(0xFFFDE047),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFD4AF37),
          queenStarPoints: 8,
          strikerMaterialName: 'Silver and Teal',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF4EEE4),
            Color(0xFFDFD4C3),
            Color(0xFFC4B49F),
          ],
          strikerOuterRim: Color(0xFF282018),
          strikerBezelRing: Color(0xFFCBD5E1),
          strikerAccentRing: Color(0xFF185449),
          strikerEmblemColor: Color(0xFF94A3B8),
          strikerGemCore: Color(0xFF059669),
          strikerGemRim: Color(0xFFE2E8F0),
          strikerGlow: Color(0xFF48B693),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.compass,
          launchEffectColor: Color(0xFF48B693),
          impactFlashColor: Color(0xFF6EE7B7),
          trailColor: Color(0x9948B693),
          powerRingColor: Color(0xFF34D399),
        );

      // ── 3. Royal Navy Lounge ─────────────────────────────────────
      case BoardThemeType.midnight:
        return const ThemePieceStyle(
          theme: BoardThemeType.midnight,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF2F5F8),
            Color(0xFFDFE6ED),
            Color(0xFFC6D2DE),
          ],
          whiteRim: Color(0xFF1E293B),
          whiteGroove: Color(0xFF6B849E),
          whiteCenter: Color(0xFF93A8BE),
          whiteHighlight: Color(0xE6FFFFFF),
          blackGradient: [
            Color(0xFF232832),
            Color(0xFF151920),
            Color(0xFF0D0F14),
            Color(0xFF06070A),
          ],
          blackRim: Color(0xFFF0C767),
          blackGroove: Color(0xFFD4AF37),
          blackCenter: Color(0xFF181C24),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF3352),
            Color(0xFFD61435),
            Color(0xFF910921),
            Color(0xFF550412),
          ],
          queenOuterRing: Color(0xFFECCB7A),
          queenStarColor: Color(0xFFFDE68A),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFECCB7A),
          queenStarPoints: 8,
          strikerMaterialName: 'Midnight Blue and Gold',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFEDF2F7),
            Color(0xFFD2DEEA),
            Color(0xFFB1C4D7),
          ],
          strikerOuterRim: Color(0xFF111722),
          strikerBezelRing: Color(0xFFDFC27D),
          strikerAccentRing: Color(0xFF1A2D48),
          strikerEmblemColor: Color(0xFFC8A962),
          strikerGemCore: Color(0xFFD41B3B),
          strikerGemRim: Color(0xFFF2DCA0),
          strikerGlow: Color(0xFF60A5FA),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.compass,
          launchEffectColor: Color(0xFF60A5FA),
          impactFlashColor: Color(0xFFDFC27D),
          trailColor: Color(0x9960A5FA),
          powerRingColor: Color(0xFFDFC27D),
        );

      // ── 4. Walnut Club ───────────────────────────────────────────
      case BoardThemeType.walnutClub:
        return const ThemePieceStyle(
          theme: BoardThemeType.walnutClub,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFBF4E8),
            Color(0xFFEFE2CF),
            Color(0xFFDBCBB3),
          ],
          whiteRim: Color(0xFF381F0E),
          whiteGroove: Color(0xFF9E6838),
          whiteCenter: Color(0xFFC79768),
          whiteHighlight: Color(0xD9FFFFFF),
          blackGradient: [
            Color(0xFF2C221C),
            Color(0xFF1C1410),
            Color(0xFF110B08),
            Color(0xFF070403),
          ],
          blackRim: Color(0xFFF59E0B),
          blackGroove: Color(0xFFD97706),
          blackCenter: Color(0xFF1F1612),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF3D47),
            Color(0xFFD61A28),
            Color(0xFF940E19),
            Color(0xFF59060E),
          ],
          queenOuterRing: Color(0xFFE5A93C),
          queenStarColor: Color(0xFFFDE68A),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFD49A3D),
          queenStarPoints: 8,
          strikerMaterialName: 'Walnut Wood and Brass',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF8EDE0),
            Color(0xFFE8D2B0),
            Color(0xFFCDB085),
          ],
          strikerOuterRim: Color(0xFF2C180C),
          strikerBezelRing: Color(0xFFD49A3D),
          strikerAccentRing: Color(0xFF8A531C),
          strikerEmblemColor: Color(0xFFD49A3D),
          strikerGemCore: Color(0xFFC02626),
          strikerGemRim: Color(0xFFF5CF75),
          strikerGlow: Color(0xFFF59E0B),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.compass,
          launchEffectColor: Color(0xFFF59E0B),
          impactFlashColor: Color(0xFFD49A3D),
          trailColor: Color(0x99F59E0B),
          powerRingColor: Color(0xFFD49A3D),
        );

      // ── 5. Royal Indigo ──────────────────────────────────────────
      case BoardThemeType.royalIndigo:
        return const ThemePieceStyle(
          theme: BoardThemeType.royalIndigo,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F6FE),
            Color(0xFFE2E5FB),
            Color(0xFFC9CFF5),
          ],
          whiteRim: Color(0xFF1E1B4B),
          whiteGroove: Color(0xFF6366F1),
          whiteCenter: Color(0xFF98A0F2),
          whiteHighlight: Color(0xE6FFFFFF),
          blackGradient: [
            Color(0xFF242332),
            Color(0xFF151420),
            Color(0xFF0D0C14),
            Color(0xFF06060A),
          ],
          blackRim: Color(0xFFE2E8F0),
          blackGroove: Color(0xFFA5B4FC),
          blackCenter: Color(0xFF191826),
          blackHighlight: Color(0x73FFFFFF),
          queenGradient: [
            Color(0xFFFF336E),
            Color(0xFFD8104D),
            Color(0xFF940833),
            Color(0xFF57031D),
          ],
          queenOuterRing: Color(0xFFE2E8F0),
          queenStarColor: Color(0xFFF8FAFC),
          queenCenterPip: Color(0xFFFFFFFF),
          queenCenterRing: Color(0xFFCBD5E1),
          queenStarPoints: 8,
          strikerMaterialName: 'Sapphire and Platinum',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFEEF0FD),
            Color(0xFFD5DBFA),
            Color(0xFFAEB8FC),
          ],
          strikerOuterRim: Color(0xFF16153E),
          strikerBezelRing: Color(0xFFE2E8F0),
          strikerAccentRing: Color(0xFF4338CA),
          strikerEmblemColor: Color(0xFF818CF8),
          strikerGemCore: Color(0xFFE11D62),
          strikerGemRim: Color(0xFFF1F5F9),
          strikerGlow: Color(0xFF818CF8),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.celestial,
          launchEffectColor: Color(0xFF818CF8),
          impactFlashColor: Color(0xFFE2E8F0),
          trailColor: Color(0x99818CF8),
          powerRingColor: Color(0xFF818CF8),
        );

      // ── 6. Emerald Lounge ────────────────────────────────────────
      case BoardThemeType.emeraldLounge:
        return const ThemePieceStyle(
          theme: BoardThemeType.emeraldLounge,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF2FBF5),
            Color(0xFFDDF5E6),
            Color(0xFFC2E8CE),
          ],
          whiteRim: Color(0xFF064E3B),
          whiteGroove: Color(0xFF059669),
          whiteCenter: Color(0xFF6EE7B7),
          whiteHighlight: Color(0xD9FFFFFF),
          blackGradient: [
            Color(0xFF222926),
            Color(0xFF141A17),
            Color(0xFF0B100E),
            Color(0xFF050706),
          ],
          blackRim: Color(0xFFF59E0B),
          blackGroove: Color(0xFFD97706),
          blackCenter: Color(0xFF151D19),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF335A),
            Color(0xFFD6123A),
            Color(0xFF920A24),
            Color(0xFF560414),
          ],
          queenOuterRing: Color(0xFFF59E0B),
          queenStarColor: Color(0xFFFDE68A),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFF59E0B),
          queenStarPoints: 8,
          strikerMaterialName: 'Emerald and Antique Gold',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF0FDF5),
            Color(0xFFD3F8E4),
            Color(0xFFA7EFC7),
          ],
          strikerOuterRim: Color(0xFF064E3B),
          strikerBezelRing: Color(0xFFF59E0B),
          strikerAccentRing: Color(0xFF047857),
          strikerEmblemColor: Color(0xFFD97706),
          strikerGemCore: Color(0xFFDC2626),
          strikerGemRim: Color(0xFFFDE68A),
          strikerGlow: Color(0xFF34D399),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.rosette,
          launchEffectColor: Color(0xFF34D399),
          impactFlashColor: Color(0xFFF59E0B),
          trailColor: Color(0x9934D399),
          powerRingColor: Color(0xFF10B981),
        );

      // ── 7. Ocean Breeze ──────────────────────────────────────────
      case BoardThemeType.oceanBreeze:
        return const ThemePieceStyle(
          theme: BoardThemeType.oceanBreeze,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF0FDFB),
            Color(0xFFD6F6F2),
            Color(0xFFBCEAE4),
          ],
          whiteRim: Color(0xFF0E3A42),
          whiteGroove: Color(0xFF0D9488),
          whiteCenter: Color(0xFF5EEAD4),
          whiteHighlight: Color(0xE6FFFFFF),
          blackGradient: [
            Color(0xFF20262B),
            Color(0xFF13181C),
            Color(0xFF0A0E11),
            Color(0xFF040608),
          ],
          blackRim: Color(0xFF99F6E4),
          blackGroove: Color(0xFF2DD4BF),
          blackCenter: Color(0xFF151C21),
          blackHighlight: Color(0x6BFFFFFF),
          queenGradient: [
            Color(0xFFFF334C),
            Color(0xFFD61430),
            Color(0xFF910A1F),
            Color(0xFF560411),
          ],
          queenOuterRing: Color(0xFFBAE6FD),
          queenStarColor: Color(0xFFE0F2FE),
          queenCenterPip: Color(0xFFF0FDF4),
          queenCenterRing: Color(0xFF7DD3FC),
          queenStarPoints: 8,
          strikerMaterialName: 'Aquamarine and Silver',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFECFEFF),
            Color(0xFFCFFAFE),
            Color(0xFFA0EAF3),
          ],
          strikerOuterRim: Color(0xFF083340),
          strikerBezelRing: Color(0xFF94A3B8),
          strikerAccentRing: Color(0xFF0891B2),
          strikerEmblemColor: Color(0xFF06B6D4),
          strikerGemCore: Color(0xFFE11D48),
          strikerGemRim: Color(0xFFE0F2FE),
          strikerGlow: Color(0xFF22D3EE),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.wave,
          launchEffectColor: Color(0xFF22D3EE),
          impactFlashColor: Color(0xFF67E8F9),
          trailColor: Color(0x9922D3EE),
          powerRingColor: Color(0xFF06B6D4),
        );

      // ── 8. Sakura Studio ─────────────────────────────────────────
      case BoardThemeType.sakuraStudio:
        return const ThemePieceStyle(
          theme: BoardThemeType.sakuraStudio,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF9F9),
            Color(0xFFFBF1F2),
            Color(0xFFF2DEE1),
          ],
          whiteRim: Color(0xFF3D262C),
          whiteGroove: Color(0xFFC08A93),
          whiteCenter: Color(0xFFE2B4BC),
          whiteHighlight: Color(0xD9FFFFFF),
          blackGradient: [
            Color(0xFF292527),
            Color(0xFF1A1718),
            Color(0xFF0F0D0E),
            Color(0xFF070607),
          ],
          blackRim: Color(0xFFFBCFE8),
          blackGroove: Color(0xFFF472B6),
          blackCenter: Color(0xFF1C181A),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF2E5B),
            Color(0xFFD8103F),
            Color(0xFF940728),
            Color(0xFF550316),
          ],
          queenOuterRing: Color(0xFFFDE047),
          queenStarColor: Color(0xFFFEF08A),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFFCD34D),
          queenStarPoints: 8,
          strikerMaterialName: 'Porcelain Pink and Rose Gold',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF5F5),
            Color(0xFFFFE4E6),
            Color(0xFFFED0D6),
          ],
          strikerOuterRim: Color(0xFF4C0519),
          strikerBezelRing: Color(0xFFFB7185),
          strikerAccentRing: Color(0xFFF43F5E),
          strikerEmblemColor: Color(0xFFE11D48),
          strikerGemCore: Color(0xFFE11D48),
          strikerGemRim: Color(0xFFFEE2E2),
          strikerGlow: Color(0xFFFB7185),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.rosette,
          launchEffectColor: Color(0xFFFB7185),
          impactFlashColor: Color(0xFFFDA4AF),
          trailColor: Color(0x99FB7185),
          powerRingColor: Color(0xFFF43F5E),
        );

      // ── 9. Neon Arena ────────────────────────────────────────────
      case BoardThemeType.neonArena:
        return const ThemePieceStyle(
          theme: BoardThemeType.neonArena,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF0FDFA),
            Color(0xFFDCF8F8),
            Color(0xFFBCEFF2),
          ],
          whiteRim: Color(0xFF18181B),
          whiteGroove: Color(0xFF06B6D4),
          whiteCenter: Color(0xFF67E8F9),
          whiteHighlight: Color(0xF2FFFFFF),
          blackGradient: [
            Color(0xFF222228),
            Color(0xFF15151A),
            Color(0xFF0A0A0E),
            Color(0xFF040406),
          ],
          blackRim: Color(0xFF00F0FF),
          blackGroove: Color(0xFF38BDF8),
          blackCenter: Color(0xFF181820),
          blackHighlight: Color(0x7AFFFFFF),
          queenGradient: [
            Color(0xFFFF1A66),
            Color(0xFFE0004D),
            Color(0xFF9E0033),
            Color(0xFF5E001D),
          ],
          queenOuterRing: Color(0xFFFFD700),
          queenStarColor: Color(0xFF00F0FF),
          queenCenterPip: Color(0xFFFFFFFF),
          queenCenterRing: Color(0xFFFF1A66),
          queenStarPoints: 8,
          strikerMaterialName: 'Carbon Black and Cyan Neon',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF0FDF4),
            Color(0xFFE0E7FF),
            Color(0xFF93C5FD),
          ],
          strikerOuterRim: Color(0xFF09090B),
          strikerBezelRing: Color(0xFF06B6D4),
          strikerAccentRing: Color(0xFFD946EF),
          strikerEmblemColor: Color(0xFF00F0FF),
          strikerGemCore: Color(0xFFFF0055),
          strikerGemRim: Color(0xFF00F0FF),
          strikerGlow: Color(0xFFE879F9),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.cyber,
          launchEffectColor: Color(0xFF00F0FF),
          impactFlashColor: Color(0xFFFF0055),
          trailColor: Color(0x9900F0FF),
          powerRingColor: Color(0xFF06B6D4),
        );

      // ── 10. Golden Palace ────────────────────────────────────────
      case BoardThemeType.goldenPalace:
        return const ThemePieceStyle(
          theme: BoardThemeType.goldenPalace,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFFFBEB),
            Color(0xFFFEF3C7),
            Color(0xFFFCE799),
          ],
          whiteRim: Color(0xFF451A03),
          whiteGroove: Color(0xFFD97706),
          whiteCenter: Color(0xFFF59E0B),
          whiteHighlight: Color(0xE6FFFFFF),
          blackGradient: [
            Color(0xFF262322),
            Color(0xFF171514),
            Color(0xFF0D0B0A),
            Color(0xFF060505),
          ],
          blackRim: Color(0xFFF59E0B),
          blackGroove: Color(0xFFD4AF37),
          blackCenter: Color(0xFF191716),
          blackHighlight: Color(0x66FFFFFF),
          queenGradient: [
            Color(0xFFFF2A48),
            Color(0xFFD11232),
            Color(0xFF8E0A20),
            Color(0xFF540411),
          ],
          queenOuterRing: Color(0xFFF59E0B),
          queenStarColor: Color(0xFFFEF08A),
          queenCenterPip: Color(0xFFFFFBEB),
          queenCenterRing: Color(0xFFF59E0B),
          queenStarPoints: 8,
          strikerMaterialName: 'Ivory Marble and Polished Gold',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFEF9C3),
            Color(0xFFFDE047),
            Color(0xFFEAB308),
          ],
          strikerOuterRim: Color(0xFF450A0A),
          strikerBezelRing: Color(0xFFF59E0B),
          strikerAccentRing: Color(0xFF991B1B),
          strikerEmblemColor: Color(0xFFF59E0B),
          strikerGemCore: Color(0xFFDC2626),
          strikerGemRim: Color(0xFFFEF08A),
          strikerGlow: Color(0xFFFBBF24),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.rosette,
          launchEffectColor: Color(0xFFFBBF24),
          impactFlashColor: Color(0xFFFEF08A),
          trailColor: Color(0x99FBBF24),
          powerRingColor: Color(0xFFF59E0B),
        );

      // ── 11. Cosmic Elite ─────────────────────────────────────────
      case BoardThemeType.cosmicElite:
        return const ThemePieceStyle(
          theme: BoardThemeType.cosmicElite,
          whiteGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFFAF5FF),
            Color(0xFFEFE4FF),
            Color(0xFFDAC7F8),
          ],
          whiteRim: Color(0xFF1E1B4B),
          whiteGroove: Color(0xFF8B5CF6),
          whiteCenter: Color(0xFFC084FC),
          whiteHighlight: Color(0xE6FFFFFF),
          blackGradient: [
            Color(0xFF22202E),
            Color(0xFF14121E),
            Color(0xFF0B0912),
            Color(0xFF050409),
          ],
          blackRim: Color(0xFFC084FC),
          blackGroove: Color(0xFFA855F7),
          blackCenter: Color(0xFF171522),
          blackHighlight: Color(0x70FFFFFF),
          queenGradient: [
            Color(0xFFFF2675),
            Color(0xFFD40B56),
            Color(0xFF8F0538),
            Color(0xFF54021F),
          ],
          queenOuterRing: Color(0xFFDDD6FE),
          queenStarColor: Color(0xFFF5F3FF),
          queenCenterPip: Color(0xFFFFFFFF),
          queenCenterRing: Color(0xFFC4B5FD),
          queenStarPoints: 8,
          strikerMaterialName: 'Obsidian and Cosmic Violet',
          strikerGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F3FF),
            Color(0xFFEDE9FE),
            Color(0xFFC4B5FD),
          ],
          strikerOuterRim: Color(0xFF1E1B4B),
          strikerBezelRing: Color(0xFF8B5CF6),
          strikerAccentRing: Color(0xFF4C1D95),
          strikerEmblemColor: Color(0xFFA78BFA),
          strikerGemCore: Color(0xFFD9166F),
          strikerGemRim: Color(0xFFDDD6FE),
          strikerGlow: Color(0xFFA855F7),
          strikerStarPoints: 8,
          strikerEmblemType: StrikerEmblemType.celestial,
          launchEffectColor: Color(0xFFA855F7),
          impactFlashColor: Color(0xFFDDD6FE),
          trailColor: Color(0x99A855F7),
          powerRingColor: Color(0xFF8B5CF6),
        );
    }
  }
}
