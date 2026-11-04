import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Independent toggles
  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;

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

  final List<AudioPlayer> _wallPool = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _wallPoolIndex = 0;

  final AudioPlayer _pocketPlayer = AudioPlayer();
  final AudioPlayer _shootPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _foulPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _initialized = false;
  bool _isBgmPlaying = false;

  // Sound rate limiting to prevent distortion during rapid cluster collisions
  int _lastHitTime = 0;
  int _lastWallTime = 0;
  static const int _minHitIntervalMs = 40;
  static const int _minWallIntervalMs = 50;

  Future<void> init() async {
    if (_initialized) return;
    try {
      for (final p in _hitPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('audio/hit.wav'));
        await p.setVolume(0.85);
      }
      for (final p in _wallPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('audio/wall.wav'));
        await p.setVolume(0.75);
      }

      await _pocketPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _pocketPlayer.setSource(AssetSource('audio/pocket.wav'));
      await _pocketPlayer.setVolume(0.9);

      await _shootPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _shootPlayer.setSource(AssetSource('audio/shoot.wav'));
      await _shootPlayer.setVolume(0.8);

      await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _winPlayer.setSource(AssetSource('audio/win.wav'));
      await _winPlayer.setVolume(0.95);

      await _foulPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _foulPlayer.setSource(AssetSource('audio/wall.wav'));
      await _foulPlayer.setVolume(0.85);

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.25);

      _initialized = true;
    } catch (e) {
      debugPrint('AudioService init note: $e');
    }
  }

  // --- Background Music (BGM) ---
  Future<void> playBgm() async {
    if (!musicEnabled || _isBgmPlaying) return;
    try {
      _isBgmPlaying = true;
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    if (!_isBgmPlaying) return;
    try {
      await _bgmPlayer.pause();
      _isBgmPlaying = false;
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!musicEnabled || _isBgmPlaying) return;
    try {
      await _bgmPlayer.resume();
      _isBgmPlaying = true;
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (_) {}
  }

  // --- Overlapping SFX with Rate Limiting & Physics Scaling ---
  void playHit({double volumeScale = 1.0}) {
    if (!sfxEnabled) return;
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

  void playWall() {
    if (!sfxEnabled) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastWallTime < _minWallIntervalMs) return;
    _lastWallTime = now;

    try {
      final player = _wallPool[_wallPoolIndex];
      _wallPoolIndex = (_wallPoolIndex + 1) % _wallPool.length;
      player.seek(Duration.zero);
      player.resume();
    } catch (_) {}
  }

  void playPocket() {
    if (!sfxEnabled) return;
    try {
      _pocketPlayer.seek(Duration.zero);
      _pocketPlayer.resume();
    } catch (_) {}
  }

  void playQueenPocket() {
    if (!sfxEnabled) return;
    try {
      _pocketPlayer.seek(Duration.zero);
      _pocketPlayer.resume();
    } catch (_) {}
    hapticHeavy();
  }

  void playQueenCover() {
    if (!sfxEnabled) return;
    try {
      _winPlayer.seek(Duration.zero);
      _winPlayer.setVolume(0.9);
      _winPlayer.resume();
    } catch (_) {}
    hapticCelebration();
  }

  void playFoul() {
    if (!sfxEnabled) return;
    try {
      _foulPlayer.seek(Duration.zero);
      _foulPlayer.resume();
    } catch (_) {}
    hapticFoul();
  }

  void playShoot() {
    if (!sfxEnabled) return;
    try {
      _shootPlayer.seek(Duration.zero);
      _shootPlayer.resume();
    } catch (_) {}
  }

  void playWin() {
    if (!sfxEnabled) return;
    try {
      _winPlayer.seek(Duration.zero);
      _winPlayer.resume();
    } catch (_) {}
  }

  void playDefeat() {
    if (!sfxEnabled) return;
    try {
      _wallPool[0].seek(Duration.zero);
      _wallPool[0].resume();
    } catch (_) {}
  }

  // --- Contextual Haptic Feedback ---
  void hapticLight() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

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

  void stopAll() {
    for (final p in _hitPool) {
      try { p.stop(); } catch (_) {}
    }
    for (final p in _wallPool) {
      try { p.stop(); } catch (_) {}
    }
    try { _pocketPlayer.stop(); } catch (_) {}
    try { _shootPlayer.stop(); } catch (_) {}
    try { _winPlayer.stop(); } catch (_) {}
    try { _foulPlayer.stop(); } catch (_) {}
    try { _bgmPlayer.stop(); } catch (_) {}
    _isBgmPlaying = false;
  }

  void dispose() {
    for (final p in _hitPool) {
      p.dispose();
    }
    for (final p in _wallPool) {
      p.dispose();
    }
    _pocketPlayer.dispose();
    _shootPlayer.dispose();
    _winPlayer.dispose();
    _foulPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
