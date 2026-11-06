import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String bgmAsset = 'audio/Carrom_Zone_BGM_50s_Loop.mp3';
  static const double bgmDefaultVolume = 0.28;

  // New production sound effect assets
  static const String sfxTouchAsset = 'audio/touch_effect.mp3';
  static const String sfxCollisionAsset = 'audio/pieces_touch.mp3';
  static const String sfxPocketAsset = 'audio/port.mp3';

  // Independent toggles
  bool sfxEnabled = true;
  bool _musicEnabled = true;
  bool hapticsEnabled = true;

  bool get musicEnabled => _musicEnabled;
  set musicEnabled(bool val) {
    if (_musicEnabled == val) return;
    _musicEnabled = val;
    if (!val) {
      pauseBgm();
    } else {
      if (_isAppForeground && !_isGameplayPaused && !_isGameplayActive) {
        resumeBgm();
      }
    }
  }

  // Backwards compatibility property
  bool get soundEnabled => sfxEnabled;
  set soundEnabled(bool val) => sfxEnabled = val;

  // Pool of audio players for overlapping hit sound effects (avoids cutting off rapid collisions)
  final List<AudioPlayer> _hitPool = [
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _hitPoolIndex = 0;

  // Pool of audio players for piece pocket events
  final List<AudioPlayer> _pocketPool = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _pocketPoolIndex = 0;

  // Pool of audio players for UI touch / button interactions
  final List<AudioPlayer> _uiTouchPool = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _uiTouchPoolIndex = 0;

  final AudioPlayer _shootPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _foulPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _initialized = false;
  bool _isBgmPlaying = false;
  bool _isGameplayActive = false;
  bool _isGameplayPaused = false;
  bool _isAppForeground = true;
  bool _isObserverRegistered = false;

  bool get isBgmPlaying => _isBgmPlaying;
  bool get isGameplayActive => _isGameplayActive;
  bool get isGameplayPaused => _isGameplayPaused;
  bool get isAppForeground => _isAppForeground;

  // Sound rate limiting to prevent distortion during rapid cluster collisions or duplicate triggers
  int _lastHitTime = 0;
  int _lastPocketTime = 0;
  int _lastUiTouchTime = 0;

  static const int _minHitIntervalMs = 50;
  static const int _minPocketIntervalMs = 50;
  static const int _minUiTouchIntervalMs = 60;

  void _registerLifecycleObserver() {
    if (_isObserverRegistered) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    } catch (_) {}
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      _registerLifecycleObserver();

      // 1. Piece collision pool (pieces_touch.mp3)
      for (final p in _hitPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource(sfxCollisionAsset));
        await p.setVolume(0.85);
      }

      // 2. Pocket pool (port.mp3)
      for (final p in _pocketPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource(sfxPocketAsset));
        await p.setVolume(0.95);
      }

      // 3. UI touch pool (touch_effect.mp3)
      for (final p in _uiTouchPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource(sfxTouchAsset));
        await p.setVolume(0.75);
      }

      await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _winPlayer.setSource(AssetSource('audio/win.wav'));
      await _winPlayer.setVolume(0.95);

      await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(bgmDefaultVolume);
      await _bgmPlayer.setSource(AssetSource(bgmAsset));

      _initialized = true;
    } catch (e) {
      debugPrint('AudioService init note: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
      if (_musicEnabled && !_isGameplayPaused && !_isGameplayActive) {
        resumeBgm();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isAppForeground = false;
      pauseBgm();
      stopAllSfx();
    }
  }

  void setGameplayActive(bool active) {
    _registerLifecycleObserver();
    _isGameplayActive = active;
    if (active) {
      _isGameplayPaused = false;
      // Requirement: Automatically pause BGM when entering an active gameplay match.
      pauseBgm();
    } else {
      _isGameplayPaused = false;
      // Requirement: Resume BGM when returning to Home/Menu, without restarting the track.
      if (_musicEnabled && _isAppForeground) {
        resumeBgm();
      }
    }
  }

  void setGameplayPaused(bool paused) {
    _isGameplayPaused = paused;
    if (_isGameplayActive) {
      // In active gameplay, BGM remains paused even on the pause screen.
      pauseBgm();
      return;
    }
    if (paused) {
      pauseBgm();
    } else {
      if (_musicEnabled && _isAppForeground) {
        resumeBgm();
      }
    }
  }

  // --- Background Music (BGM) ---
  Future<void> playBgm() async {
    if (!_musicEnabled || !_isAppForeground || _isGameplayActive || _isGameplayPaused) {
      return;
    }
    if (_isBgmPlaying && _bgmPlayer.state == PlayerState.playing) {
      return;
    }
    _isBgmPlaying = true;
    try {
      await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(bgmDefaultVolume);
      if (_bgmPlayer.state == PlayerState.paused) {
        await _bgmPlayer.resume().timeout(const Duration(milliseconds: 500));
      } else {
        await _bgmPlayer.play(AssetSource(bgmAsset)).timeout(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('AudioService playBgm note: $e');
    }
  }

  Future<void> pauseBgm() async {
    if (!_isBgmPlaying && _bgmPlayer.state != PlayerState.playing) {
      return;
    }
    _isBgmPlaying = false;
    try {
      await _bgmPlayer.pause().timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('AudioService pauseBgm note: $e');
    }
  }

  Future<void> resumeBgm() async {
    if (!_musicEnabled || !_isAppForeground || _isGameplayActive || _isGameplayPaused) {
      return;
    }
    if (_isBgmPlaying && _bgmPlayer.state == PlayerState.playing) {
      return;
    }
    _isBgmPlaying = true;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(bgmDefaultVolume);
      if (_bgmPlayer.state == PlayerState.paused) {
        await _bgmPlayer.resume().timeout(const Duration(milliseconds: 500));
      } else {
        await _bgmPlayer.play(AssetSource(bgmAsset)).timeout(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('AudioService resumeBgm note: $e');
    }
  }

  Future<void> stopBgm() async {
    _isBgmPlaying = false;
    try {
      await _bgmPlayer.stop().timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('AudioService stopBgm note: $e');
    }
  }

  // --- Overlapping SFX with Rate Limiting & Physics Scaling ---
  void playUiTouch() {
    if (!sfxEnabled || !_isAppForeground) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUiTouchTime < _minUiTouchIntervalMs) return;
    _lastUiTouchTime = now;

    try {
      final player = _uiTouchPool[_uiTouchPoolIndex];
      _uiTouchPoolIndex = (_uiTouchPoolIndex + 1) % _uiTouchPool.length;
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  void playHit({double volumeScale = 1.0}) {
    if (!sfxEnabled || !_isAppForeground) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHitTime < _minHitIntervalMs) return;
    _lastHitTime = now;

    try {
      final player = _hitPool[_hitPoolIndex];
      _hitPoolIndex = (_hitPoolIndex + 1) % _hitPool.length;
      player.setVolume((0.85 * volumeScale).clamp(0.15, 1.0));
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  void playPieceCollision({double volumeScale = 1.0}) =>
      playHit(volumeScale: volumeScale);

  void playWall() {
    // Wall/cushion collision sound is removed as per specification.
    // Piece touch SFX is played exclusively on coin-coin and striker-coin impacts.
  }

  void playPocket() {
    if (!sfxEnabled || !_isAppForeground) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPocketTime < _minPocketIntervalMs) return;
    _lastPocketTime = now;

    try {
      final player = _pocketPool[_pocketPoolIndex];
      _pocketPoolIndex = (_pocketPoolIndex + 1) % _pocketPool.length;
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  void playQueenPocket() {
    playPocket();
    hapticHeavy();
  }

  void playQueenCover() {
    if (!sfxEnabled || !_isAppForeground) return;
    try {
      _winPlayer.seek(Duration.zero);
      _winPlayer.setVolume(0.9);
      _winPlayer.resume();
    } catch (_) {}
    hapticCelebration();
  }

  void playFoul() {
    if (!sfxEnabled || !_isAppForeground) return;
    try {
      _foulPlayer.seek(Duration.zero);
      _foulPlayer.resume();
    } catch (_) {}
    hapticFoul();
  }

  void playShoot() {
    if (!sfxEnabled || !_isAppForeground) return;
    try {
      _shootPlayer.seek(Duration.zero);
      _shootPlayer.resume();
    } catch (_) {}
  }

  void playWin() {
    if (!sfxEnabled || !_isAppForeground) return;
    try {
      _winPlayer.seek(Duration.zero);
      _winPlayer.resume();
    } catch (_) {}
  }

  void playDefeat() {
    if (!sfxEnabled || !_isAppForeground) return;
    hapticHeavy();
  }

  // --- Contextual Haptic Feedback ---
  int _lastHapticTime = 0;
  static const int _minHapticIntervalMs = 90;

  void hapticLight() {
    if (!hapticsEnabled) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticTime < _minHapticIntervalMs) return;
    _lastHapticTime = now;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void hapticTurnChange() => hapticLight();

  void hapticMedium() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void hapticHeavy() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void hapticSelection() {
    playUiTouch();
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void hapticCelebration() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (hapticsEnabled) HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 240), () {
        if (hapticsEnabled) HapticFeedback.lightImpact();
      });
    } catch (_) {}
  }

  void hapticFoul() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 90), () {
        if (hapticsEnabled) HapticFeedback.heavyImpact();
      });
    } catch (_) {}
  }

  void stopAllSfx() {
    for (final p in _hitPool) {
      try { p.stop(); } catch (_) {}
    }
    for (final p in _pocketPool) {
      try { p.stop(); } catch (_) {}
    }
    for (final p in _uiTouchPool) {
      try { p.stop(); } catch (_) {}
    }
    try { _shootPlayer.stop(); } catch (_) {}
    try { _winPlayer.stop(); } catch (_) {}
    try { _foulPlayer.stop(); } catch (_) {}
  }

  void stopAll() {
    stopAllSfx();
    try { _bgmPlayer.stop(); } catch (_) {}
    _isBgmPlaying = false;
  }

  void dispose() {
    if (_isObserverRegistered) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
      _isObserverRegistered = false;
    }
    for (final p in _hitPool) {
      p.dispose();
    }
    for (final p in _pocketPool) {
      p.dispose();
    }
    for (final p in _uiTouchPool) {
      p.dispose();
    }
    _shootPlayer.dispose();
    _winPlayer.dispose();
    _foulPlayer.dispose();
    _bgmPlayer.dispose();
    _initialized = false;
    _isBgmPlaying = false;
  }
}
