import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';
import '../core/app_colors.dart';
import 'theme_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keySound = 'carrom_sound_enabled';
  static const String _keySfx = 'carrom_sfx_enabled';
  static const String _keyMusic = 'carrom_music_enabled';
  static const String _keyHaptics = 'carrom_haptics_enabled';
  static const String _keyTutorial = 'carrom_tutorial_seen';
  static const String _keyDifficulty = 'carrom_ai_difficulty';
  static const String _keyTheme = 'carrom_board_theme';
  static const String _keyPurchasedThemes = 'carrom_purchased_themes_v1';
  static const String _keyDevMockUnlockedThemes = 'carrom_dev_mock_unlocked_themes_v1';

  SharedPreferences? _prefs;

  Future<void> init({bool forceReload = false}) async {
    if (forceReload || _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Resets cached preferences for deterministic testing.
  void resetForTesting() {
    _prefs = null;
  }

  // --- Audio & Haptics Settings ---
  bool getSoundEnabled() {
    return _prefs?.getBool(_keySound) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_keySound, enabled);
    await setSfxEnabled(enabled);
  }

  bool getSfxEnabled() {
    return _prefs?.getBool(_keySfx) ?? getSoundEnabled();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    await _prefs?.setBool(_keySfx, enabled);
    await _prefs?.setBool(_keySound, enabled);
  }

  bool getMusicEnabled() {
    return _prefs?.getBool(_keyMusic) ?? true;
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs?.setBool(_keyMusic, enabled);
  }

  bool getHapticsEnabled() {
    return _prefs?.getBool(_keyHaptics) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyHaptics, enabled);
  }

  // --- Tutorial Status ---
  bool getTutorialSeen() {
    return _prefs?.getBool(_keyTutorial) ?? false;
  }

  Future<void> setTutorialSeen(bool seen) async {
    await _prefs?.setBool(_keyTutorial, seen);
  }

  // --- AI Difficulty ---
  AiDifficulty getAiDifficulty() {
    final str = _prefs?.getString(_keyDifficulty) ?? 'medium';
    switch (str) {
      case 'easy':
        return AiDifficulty.easy;
      case 'hard':
        return AiDifficulty.hard;
      default:
        return AiDifficulty.medium;
    }
  }

  Future<void> setAiDifficulty(AiDifficulty difficulty) async {
    await _prefs?.setString(_keyDifficulty, difficulty.name);
  }

  // --- Board Theme (Centralized through ThemeService) ---
  BoardThemeType getBoardTheme() {
    return ThemeService().getActiveTheme();
  }

  Future<bool> setBoardTheme(BoardThemeType theme) async {
    return ThemeService().selectTheme(theme);
  }

  BoardThemeType getBoardThemeRaw() {
    final str = _prefs?.getString(_keyTheme) ?? 'mahogany';
    try {
      return BoardThemeType.values.firstWhere((t) => t.name == str);
    } catch (_) {
      return BoardThemeType.mahogany;
    }
  }

  Future<void> setBoardThemeRaw(BoardThemeType theme) async {
    await _prefs?.setString(_keyTheme, theme.name);
  }

  // --- Theme Entitlements ---
  List<String> getPurchasedThemes() {
    return _prefs?.getStringList(_keyPurchasedThemes) ?? [];
  }

  Future<void> setPurchasedThemes(List<String> themes) async {
    await _prefs?.setStringList(_keyPurchasedThemes, themes);
  }

  // --- Developer Mock Unlocks (Separate from real purchases) ---
  List<String> getDevMockUnlockedThemes() {
    return _prefs?.getStringList(_keyDevMockUnlockedThemes) ?? [];
  }

  Future<void> setDevMockUnlockedThemes(List<String> themes) async {
    await _prefs?.setStringList(_keyDevMockUnlockedThemes, themes);
  }
}
