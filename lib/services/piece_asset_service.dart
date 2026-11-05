import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../models/piece_model.dart';

/// Centralized service for preloading, caching, and serving authentic
/// high-resolution 512x512 carrom piece assets (White, Black, Queen)
/// across active gameplay, heads-up displays, and theme previews.
class PieceAssetService {
  static final PieceAssetService instance = PieceAssetService._internal();
  factory PieceAssetService() => instance;
  PieceAssetService._internal();

  final Map<String, ui.Image> _cachedImages = {};

  static String _cacheKey(BoardThemeType theme, PieceType type) =>
      '${theme.name}_${type.name}';

  /// Maps theme and piece type to its asset path in assets/images/pieces/{themeId}/{type}.png
  static String getPieceAsset(BoardThemeType theme, PieceType type) {
    final String themeFolder = AppColors.getThemeAssetKey(theme);
    final String pieceName = type == PieceType.queen
        ? 'queen'
        : (type == PieceType.white ? 'white' : 'black');
    return 'assets/images/pieces/$themeFolder/$pieceName.png';
  }

  /// Maps theme and piece type to its WebP asset path
  static String getPieceWebpAsset(BoardThemeType theme, PieceType type) {
    final String themeFolder = AppColors.getThemeAssetKey(theme);
    final String pieceName = type == PieceType.queen
        ? 'queen'
        : (type == PieceType.white ? 'white' : 'black');
    return 'assets/images/pieces/$themeFolder/$pieceName.webp';
  }

  /// Returns the preloaded [ui.Image] for the given theme and piece type, or null.
  ui.Image? getPiece(BoardThemeType theme, PieceType type) {
    return _cachedImages[_cacheKey(theme, type)];
  }

  /// Preloads all 33 piece textures (11 themes x 3 piece types) into GPU memory.
  Future<void> preloadAll() async {
    for (final theme in BoardThemeType.values) {
      await preloadTheme(theme);
    }
  }

  /// Preloads the 3 pieces (White, Black, Queen) for the designated board theme.
  Future<void> preloadTheme(BoardThemeType theme) async {
    for (final type in [PieceType.white, PieceType.black, PieceType.queen]) {
      final key = _cacheKey(theme, type);
      if (_cachedImages.containsKey(key)) continue;

      try {
        final String path = getPieceAsset(theme, type);
        final ByteData data = await rootBundle.load(path);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        _cachedImages[key] = frameInfo.image;
      } catch (_) {
        // Safe fallback in headless test environments
      }
    }
  }

  /// Reusable widget rendering the authentic piece thumbnail.
  static Widget buildPreview({
    required BoardThemeType theme,
    required PieceType type,
    double size = 36.0,
    bool showShadow = true,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: size * 0.15,
                  offset: Offset(0, size * 0.07),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        getPieceAsset(theme, type),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: type == PieceType.queen
                ? const Color(0xFFE5484D)
                : (type == PieceType.white
                    ? const Color(0xFFF5EFE6)
                    : const Color(0xFF1E293B)),
            border: Border.all(
              color: type == PieceType.queen
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF94A3B8),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

