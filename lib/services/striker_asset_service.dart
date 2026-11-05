import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Centralized service for preloading, caching, and serving authentic
/// high-resolution 512x512 striker assets across gameplay and all UI screens.
class StrikerAssetService {
  static final StrikerAssetService instance = StrikerAssetService._internal();
  factory StrikerAssetService() => instance;
  StrikerAssetService._internal();

  final Map<BoardThemeType, ui.Image> _cachedImages = {};

  bool get isLoaded => _cachedImages.length == BoardThemeType.values.length;

  /// Returns the preloaded [ui.Image] for the given theme, or null if not yet loaded.
  ui.Image? getStriker(BoardThemeType theme) => _cachedImages[theme];

  /// Preloads all 11 striker textures into memory for zero-latency 60/120 FPS rendering.
  Future<void> preloadAll() async {
    for (final theme in BoardThemeType.values) {
      await preloadTheme(theme);
    }
  }

  /// Preloads an individual striker texture into memory.
  Future<void> preloadTheme(BoardThemeType theme) async {
    if (_cachedImages.containsKey(theme)) return;
    try {
      final String path = AppColors.getStrikerAsset(theme);
      final ByteData data = await rootBundle.load(path);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _cachedImages[theme] = frameInfo.image;
    } catch (_) {
      // In headless test environments or when rootBundle is mocked, fail safely
    }
  }

  /// Reusable widget rendering the identical striker asset thumbnail across
  /// theme selectors, dialogs, and cards.
  static Widget buildPreview({
    required BoardThemeType theme,
    double size = 48.0,
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
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: size * 0.15,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        AppColors.getStrikerAsset(theme),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.getThemeAccent(theme).withOpacity(0.2),
            border: Border.all(
              color: AppColors.getThemeAccent(theme),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

