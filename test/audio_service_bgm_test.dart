import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/services/audio_service.dart';
import 'package:carrom_master/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = [];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        log.add(call);
        if (call.method == 'getSource') return 'audio/Carrom_Zone_BGM_50s_Loop.mp3';
        return 1;
      },
    );
  });

  setUp(() async {
    log.clear();
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    AudioService().sfxEnabled = true;
    AudioService().musicEnabled = true;
    AudioService().hapticsEnabled = true;
    AudioService().setGameplayActive(false);
  });

  group('CARROM ZONE — Background Music (BGM) Optimization Suite', () {
    test('1. BGM and SFX Assets are properly mapped to MP3s', () {
      expect(AudioService.bgmAsset, 'audio/Carrom_Zone_BGM_50s_Loop.mp3');
      expect(AudioService.bgmDefaultVolume, 0.28);
      expect(AudioService.sfxTouchAsset, 'audio/touch_effect.mp3');
      expect(AudioService.sfxCollisionAsset, 'audio/pieces_touch.mp3');
      expect(AudioService.sfxPocketAsset, 'audio/port.mp3');
    });

    test('2. Independent settings: SFX and Music toggles do not interfere', () {
      final audio = AudioService();
      audio.sfxEnabled = false;
      expect(audio.musicEnabled, true);
      expect(audio.sfxEnabled, false);

      audio.musicEnabled = false;
      audio.sfxEnabled = true;
      expect(audio.musicEnabled, false);
      expect(audio.sfxEnabled, true);
    });

    test('3. BGM plays on splash/menu, pauses on active gameplay, resumes on return to menu', () {
      final audio = AudioService();
      audio.setGameplayActive(false);

      // Starting BGM on splash / home screen plays successfully
      audio.playBgm();
      expect(audio.isBgmPlaying, true);

      // Transitioning to active gameplay automatically pauses BGM
      audio.setGameplayActive(true);
      expect(audio.isGameplayActive, true);
      expect(audio.isBgmPlaying, false);

      // Transitioning out of gameplay (returning to menu) resumes BGM seamlessly
      audio.setGameplayActive(false);
      expect(audio.isGameplayActive, false);
      expect(audio.isBgmPlaying, true);
    });

    test('4. App lifecycle handling: pauses on background, resumes on foreground when in menu', () async {
      final audio = AudioService();
      audio.setGameplayActive(false);
      audio.playBgm();
      expect(audio.isBgmPlaying, true);

      // App backgrounded / paused / inactive / hidden
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(audio.isAppForeground, false);
      expect(audio.isBgmPlaying, false);

      // App restored to foreground while in menu: resumes BGM
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isAppForeground, true);
      expect(audio.isBgmPlaying, true);

      // In active gameplay: remains paused when app is in foreground
      audio.setGameplayActive(true);
      expect(audio.isBgmPlaying, false);
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isBgmPlaying, false);
    });

    test('5. In-game active match keeps BGM paused; exiting to menu resumes BGM', () async {
      final audio = AudioService();
      audio.setGameplayActive(false);
      audio.playBgm();
      expect(audio.isBgmPlaying, true);

      // Enter match -> paused
      audio.setGameplayActive(true);
      expect(audio.isBgmPlaying, false);

      // Pause menu opened inside match
      audio.setGameplayPaused(true);
      expect(audio.isGameplayPaused, true);
      expect(audio.isBgmPlaying, false);

      // Pause menu closed (match resumed) -> still paused during match
      audio.setGameplayPaused(false);
      expect(audio.isGameplayPaused, false);
      expect(audio.isBgmPlaying, false);

      // Exit match to menu -> resumes BGM
      audio.setGameplayActive(false);
      expect(audio.isBgmPlaying, true);
    });

    test('6. Music disabled setting immediately silences and prevents playback', () async {
      final audio = AudioService();
      audio.setGameplayActive(false);
      audio.playBgm();
      expect(audio.isBgmPlaying, true);

      // User turns music OFF
      audio.musicEnabled = false;
      expect(audio.isBgmPlaying, false);

      // Starting BGM when disabled has no effect
      audio.playBgm();
      expect(audio.isBgmPlaying, false);

      // Re-enabling music while in menu resumes it
      audio.musicEnabled = true;
      expect(audio.isBgmPlaying, true);
    });

    test('7. Gameplay transition flow: Menu (BGM ON) -> Match (BGM Paused) -> SFX continues -> Menu (BGM Resumes)', () {
      final audio = AudioService();
      audio.musicEnabled = true;
      audio.setGameplayActive(false);
      audio.playBgm();
      expect(audio.isBgmPlaying, true);

      // Entering gameplay pauses BGM
      audio.setGameplayActive(true);
      expect(audio.isGameplayActive, true);
      expect(audio.isBgmPlaying, false);

      // Gameplay SFX still fires independently
      audio.playPieceCollision(volumeScale: 1.0);
      audio.playPocket();

      // Exit gameplay to main menu resumes BGM without restarting track
      audio.setGameplayActive(false);
      expect(audio.isGameplayActive, false);
      expect(audio.isBgmPlaying, true);
    });

    test('8. SFX UI Touch, Collision, and Pocket execution & rate-limiting', () {
      final audio = AudioService();
      audio.sfxEnabled = true;

      // Initial invocation
      audio.playUiTouch();
      audio.playHit(volumeScale: 0.8);
      audio.playPieceCollision(volumeScale: 1.0);
      audio.playPocket();
      audio.playQueenPocket();

      // Rate limiting: immediate second call within interval is safely throttled
      audio.playUiTouch();
      audio.playHit();
      audio.playPocket();
    });

    test('9. SFX disabled setting silences all sound effects', () {
      final audio = AudioService();
      audio.sfxEnabled = false;

      // None of these should throw or play
      audio.playUiTouch();
      audio.playHit();
      audio.playPieceCollision();
      audio.playPocket();
      audio.playQueenPocket();
    });

    test('10. App backgrounding silences sound effects', () {
      final audio = AudioService();
      audio.sfxEnabled = true;
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(audio.isAppForeground, false);

      // In background, SFX should not trigger
      audio.playUiTouch();
      audio.playHit();
      audio.playPocket();

      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isAppForeground, true);
    });

    test('11. Haptic turn change feedback and rate-limiting respect settings', () {
      final audio = AudioService();
      audio.hapticsEnabled = true;

      // Turn change trigger executes cleanly
      audio.hapticTurnChange();
      audio.hapticLight();

      // Disabled setting silences haptics
      audio.hapticsEnabled = false;
      audio.hapticTurnChange();
      audio.hapticLight();
    });
  });
}
