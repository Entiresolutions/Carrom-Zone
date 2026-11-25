import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/screens/game_screen.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/screens/theme_collection_screen.dart';
import 'package:carrom_master/services/ad_manager.dart';
import 'package:carrom_master/services/audio_service.dart';
import 'package:carrom_master/services/storage_service.dart';
import 'package:carrom_master/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInterstitialHandle implements AdHandle {
  VoidCallback? _onDismissed;
  VoidCallback? _onShowed;
  void Function(String error)? _onFailedToShow;
  int showCount = 0;
  bool disposed = false;

  @override
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  }) async {
    showCount++;
    _onShowed = onShowed;
    _onDismissed = onDismissed;
    _onFailedToShow = onFailedToShow;
    _onShowed?.call();
  }

  void simulateDismiss() => _onDismissed?.call();

  void simulateFailToShow(String error) => _onFailedToShow?.call(error);

  @override
  void dispose() {
    disposed = true;
  }
}

class _FakeRewardedHandle implements RewardedAdHandle {
  VoidCallback? _onShowed;
  VoidCallback? _onUserEarnedReward;
  VoidCallback? _onDismissed;
  void Function(String error)? _onFailedToShow;
  int showCount = 0;
  bool disposed = false;

  @override
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  }) async {
    showCount++;
    _onShowed = onShowed;
    _onUserEarnedReward = onUserEarnedReward;
    _onDismissed = onDismissed;
    _onFailedToShow = onFailedToShow;
    _onShowed?.call();
  }

  void simulateCompleteWithReward() {
    _onUserEarnedReward?.call();
    _onDismissed?.call();
  }

  void simulateEarlyCloseWithoutReward() {
    _onDismissed?.call();
  }

  void simulateFailToShow(String error) => _onFailedToShow?.call(error);

  @override
  void dispose() {
    disposed = true;
  }
}

class _FakeAdGateway implements AdGateway {
  int initCalls = 0;
  int loadInterstitialCalls = 0;
  int loadRewardedCalls = 0;

  final List<_FakeInterstitialHandle> createdInterstitials = [];
  final List<_FakeRewardedHandle> createdRewardedAds = [];

  bool failInterstitialLoads = false;
  bool failRewardedLoads = false;
  bool hangRewardedLoads = false;

  @override
  Future<void> initializeSdk() async {
    initCalls++;
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  }) {
    loadInterstitialCalls++;
    if (failInterstitialLoads) {
      onFailed('Simulated offline error');
      return;
    }
    final handle = _FakeInterstitialHandle();
    createdInterstitials.add(handle);
    onLoaded(handle);
  }

  @override
  void loadRewarded({
    required String adUnitId,
    required void Function(RewardedAdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  }) {
    loadRewardedCalls++;
    if (hangRewardedLoads) {
      // Simulate slow/stalled network without completing
      return;
    }
    if (failRewardedLoads) {
      onFailed('Simulated no fill');
      return;
    }
    final handle = _FakeRewardedHandle();
    createdRewardedAds.add(handle);
    onLoaded(handle);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => 1,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService().resetForTesting();
    await StorageService().init(forceReload: true);
    AdManager().resetForTesting();
    AudioService().onAdClosed();
    AudioService().setGameplayActive(false);
    AudioService().sfxEnabled = true;
    AudioService().musicEnabled = true;
  });

  tearDown(() async {
    AdManager().resetForTesting();
    AudioService().onAdClosed();
    await AudioService().stopBgm();
    AudioService().stopAll();
  });

  group('AdMob Configuration & Unit IDs', () {
    test('switches cleanly between Debug Test IDs and Release Production IDs', () {
      expect(
        AdManager.resolveInterstitialAdUnitId(isRelease: false),
        'ca-app-pub-3940256099942544/1033173712',
      );
      expect(
        AdManager.resolveRewardedAdUnitId(isRelease: false),
        'ca-app-pub-3940256099942544/5224354917',
      );
      expect(
        AdManager.resolveInterstitialAdUnitId(isRelease: true),
        'ca-app-pub-3794659976212193/8131392910',
      );
      expect(
        AdManager.resolveRewardedAdUnitId(isRelease: true),
        'ca-app-pub-3794659976212193/1462042784',
      );
      expect(AdManager.interstitialCooldownSeconds, 0);
    });
  });

  group('AdManager Lifecycle, Locking, Audio Safety & Offline Fallbacks', () {
    test('preloads ads on initialize and reloads automatically after dismiss', () async {
      final gateway = _FakeAdGateway();
      AdManager().configureForTesting(gateway: gateway);

      await AdManager().initialize();
      expect(gateway.initCalls, 1);
      expect(gateway.loadInterstitialCalls, 1);
      expect(gateway.loadRewardedCalls, 1);
      expect(AdManager().isInterstitialReady, isTrue);
      expect(AdManager().isRewardedReady, isTrue);

      bool completed = false;
      AdManager().showInterstitial(onComplete: () => completed = true);
      expect(AdManager().isShowingAd, isTrue);
      expect(AudioService().isAdAudioPaused, isTrue);
      expect(completed, isFalse);

      // Concurrent trigger while an ad is already showing must execute fallback immediately
      bool concurrentCompleted = false;
      AdManager().showInterstitial(onComplete: () => concurrentCompleted = true);
      expect(concurrentCompleted, isTrue);
      expect(gateway.createdInterstitials.single.showCount, 1);

      // Dismiss active ad -> completes callback, restores audio, preloads next ad
      gateway.createdInterstitials.single.simulateDismiss();
      expect(completed, isTrue);
      expect(AdManager().isShowingAd, isFalse);
      expect(AudioService().isAdAudioPaused, isFalse);
      expect(gateway.loadInterstitialCalls, 2);
      expect(AdManager().isInterstitialReady, isTrue);
    });

    test('executes onComplete immediately when offline / no ad cached', () async {
      final gateway = _FakeAdGateway()..failInterstitialLoads = true;
      AdManager().configureForTesting(gateway: gateway);

      await AdManager().initialize();
      expect(AdManager().isInterstitialReady, isFalse);
      expect(AdManager().interstitialRetryAttempt, 1);

      bool completed = false;
      AdManager().showInterstitial(onComplete: () => completed = true);
      expect(completed, isTrue);
      expect(AdManager().isShowingAd, isFalse);
      expect(AudioService().isAdAudioPaused, isFalse);
    });

    test('uses exponential backoff retries capped at 30s on load failures', () async {
      final gateway = _FakeAdGateway()
        ..failInterstitialLoads = true
        ..failRewardedLoads = true;
      AdManager().configureForTesting(gateway: gateway);

      await AdManager().initialize();
      expect(AdManager.backoffDelaysSeconds, [3, 6, 15, 30]);
      expect(AdManager().interstitialRetryAttempt, 1);
      expect(AdManager().rewardedRetryAttempt, 1);
    });
  });

  group('Rewarded Theme Unlocks & Persistent Storage', () {
    test('Classic Birch is free; Heritage Club Teal (10 ads) & Royal Navy Lounge (15 ads) start locked', () {
      expect(ThemeService().isThemeFree(BoardThemeType.mahogany), isTrue);
      expect(ThemeService().isThemeUnlocked(BoardThemeType.mahogany), isTrue);

      expect(ThemeService().isThemeRewarded(BoardThemeType.emerald), isTrue);
      expect(ThemeService().getRequiredRewardedAds(BoardThemeType.emerald), 10);
      expect(ThemeService().isThemeUnlocked(BoardThemeType.emerald), isFalse);

      expect(ThemeService().isThemeRewarded(BoardThemeType.midnight), isTrue);
      expect(ThemeService().getRequiredRewardedAds(BoardThemeType.midnight), 15);
      expect(ThemeService().isThemeUnlocked(BoardThemeType.midnight), isFalse);
    });

    test('locked rewarded themes can never be equipped until threshold reached', () async {
      expect(await ThemeService().selectTheme(BoardThemeType.emerald), isFalse);
      expect(await ThemeService().selectTheme(BoardThemeType.midnight), isFalse);
      expect(ThemeService().getActiveTheme(), BoardThemeType.mahogany);

      // Watch 9 ads for Heritage Club Teal -> still locked
      for (int i = 0; i < 9; i++) {
        final unlockedNow =
            await ThemeService().recordRewardedAdWatch(BoardThemeType.emerald);
        expect(unlockedNow, isFalse);
      }
      expect(ThemeService().getWatchedRewardedAds(BoardThemeType.emerald), 9);
      expect(ThemeService().isThemeUnlocked(BoardThemeType.emerald), isFalse);
      expect(await ThemeService().selectTheme(BoardThemeType.emerald), isFalse);

      // 10th ad permanently unlocks Heritage Club Teal
      final unlockedOnTenth =
          await ThemeService().recordRewardedAdWatch(BoardThemeType.emerald);
      expect(unlockedOnTenth, isTrue);
      expect(ThemeService().isThemeUnlocked(BoardThemeType.emerald), isTrue);
      expect(await ThemeService().selectTheme(BoardThemeType.emerald), isTrue);
      expect(ThemeService().getActiveTheme(), BoardThemeType.emerald);

      // Verify exact SharedPreferences keys persist across reload
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_ad_progress_heritage_club_teal'), 10);
      expect(prefs.getBool('theme_unlocked_heritage_club_teal'), isTrue);

      StorageService().resetForTesting();
      await StorageService().init();
      expect(ThemeService().isThemeUnlocked(BoardThemeType.emerald), isTrue);
      expect(ThemeService().getActiveTheme(), BoardThemeType.emerald);
    });

    test('early dismissed Rewarded Ad does NOT increment watch counter', () async {
      final gateway = _FakeAdGateway();
      AdManager().configureForTesting(gateway: gateway);
      await AdManager().initialize();

      bool rewardGranted = false;
      bool dismissedCalled = false;
      bool dismissedSawReward = true;

      final showFuture = AdManager().showRewardedAd(
        onUserEarnedReward: () async {
          rewardGranted = true;
          await ThemeService().recordRewardedAdWatch(BoardThemeType.midnight);
        },
        onAdDismissed: (earned) {
          dismissedCalled = true;
          dismissedSawReward = earned;
        },
        onAdUnavailable: () => fail('Ad should be available'),
      );

      expect(AdManager().isShowingAd, isTrue);
      gateway.createdRewardedAds.single.simulateEarlyCloseWithoutReward();
      await showFuture;

      expect(rewardGranted, isFalse);
      expect(dismissedCalled, isTrue);
      expect(dismissedSawReward, isFalse);
      expect(ThemeService().getWatchedRewardedAds(BoardThemeType.midnight), 0);
      expect(AudioService().isAdAudioPaused, isFalse);
    });

    test('Rewarded Ad timeout triggers onAdUnavailable without freezing', () async {
      final gateway = _FakeAdGateway()..hangRewardedLoads = true;
      AdManager().configureForTesting(gateway: gateway);

      bool loadingStarted = false;
      bool loadingEnded = false;
      bool unavailableCalled = false;

      await AdManager().showRewardedAd(
        loadTimeout: const Duration(milliseconds: 50),
        onLoadingStart: () => loadingStarted = true,
        onLoadingEnd: () => loadingEnded = true,
        onUserEarnedReward: () => fail('Should not earn reward'),
        onAdDismissed: (_) => fail('Should not dismiss'),
        onAdUnavailable: () => unavailableCalled = true,
      );

      expect(loadingStarted, isTrue);
      expect(loadingEnded, isTrue);
      expect(unavailableCalled, isTrue);
      expect(AdManager().isShowingAd, isFalse);
    });
  });

  group('UI Integration — ThemeCollectionScreen & MenuScreen Placements', () {
    Future<void> pumpUi(WidgetTester tester, [int ms = 600]) async {
      await tester.pump();
      await tester.pump(Duration(milliseconds: ms));
    }

    void setMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets(
      'ThemeCollectionScreen displays locked rewarded UI, handles rewarded unlock without interstitial, and triggers interstitial on unlocked switch',
      (tester) async {
        setMobileViewport(tester);
        // Seed Heritage Club Teal at 9/10 watched ads so next watch unlocks it
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('theme_ad_progress_heritage_club_teal', 9);
        StorageService().resetForTesting();
        await StorageService().init(forceReload: true);

        final gateway = _FakeAdGateway();
        AdManager().configureForTesting(gateway: gateway);
        await AdManager().initialize();

        await tester.pumpWidget(
          const MaterialApp(home: ThemeCollectionScreen()),
        );
        await pumpUi(tester);

        expect(find.text('Classic Birch & Rosewood'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('Starter Table • Free Unlock'), findsOneWidget);
        expect(find.text('Watch 10 Ads to Unlock • 9/10'), findsOneWidget);
        expect(find.text('9/10'), findsOneWidget);
        expect(find.text('Watch 15 Ads to Unlock • 0/15'), findsOneWidget);
        expect(find.text('0/15'), findsOneWidget);

        // Tap Heritage Club Teal -> triggers Rewarded Ad (NOT Interstitial)
        await tester.tap(find.text('Heritage Club Teal'));
        await tester.pump();
        expect(gateway.createdRewardedAds.single.showCount, 1);
        expect(gateway.createdInterstitials.single.showCount, 0);

        // Complete rewarded ad -> unlocks & equips Heritage Club Teal with NO back-to-back interstitial
        gateway.createdRewardedAds.single.simulateCompleteWithReward();
        await pumpUi(tester);

        expect(ThemeService().isThemeUnlocked(BoardThemeType.emerald), isTrue);
        expect(ThemeService().getActiveTheme(), BoardThemeType.emerald);
        expect(find.text('Heritage Club Teal Unlocked!'), findsOneWidget);
        expect(find.text('Watch 10 Ads to Unlock • 9/10'), findsNothing);
        expect(find.text('FREE'), findsOneWidget);
        expect(gateway.createdInterstitials.single.showCount, 0);

        // Now tap unlocked Classic Birch & Rosewood -> triggers Placement 5 Interstitial
        await tester.tap(find.text('Classic Birch & Rosewood'));
        await tester.pump();
        expect(gateway.createdInterstitials.single.showCount, 1);
        // Active theme stays Heritage Club Teal until interstitial finishes
        expect(ThemeService().getActiveTheme(), BoardThemeType.emerald);

        gateway.createdInterstitials.single.simulateDismiss();
        await pumpUi(tester);
        expect(ThemeService().getActiveTheme(), BoardThemeType.mahogany);
      },
    );

    testWidgets(
      'MenuScreen Settings tap triggers Interstitial and opens Settings inside onComplete',
      (tester) async {
        setMobileViewport(tester);
        final gateway = _FakeAdGateway();
        AdManager().configureForTesting(gateway: gateway);
        await AdManager().initialize();

        await tester.pumpWidget(
          const MaterialApp(home: MenuScreen()),
        );
        await pumpUi(tester, 950);

        await tester.tap(find.text('SETTINGS'));
        await tester.pump();

        expect(gateway.createdInterstitials.single.showCount, 1);
        expect(find.text('CLUB SETTINGS'), findsNothing);

        gateway.createdInterstitials.single.simulateDismiss();
        await pumpUi(tester);

        expect(find.text('CLUB SETTINGS'), findsOneWidget);
      },
    );

    testWidgets(
      'MenuScreen Play buttons (Pass & Play, Practice) trigger Interstitial before entering GameScreen',
      (tester) async {
        setMobileViewport(tester);
        final gateway = _FakeAdGateway();
        AdManager().configureForTesting(gateway: gateway);
        await AdManager().initialize();

        await tester.pumpWidget(
          const MaterialApp(home: MenuScreen()),
        );
        await pumpUi(tester, 950);

        // PASS & PLAY
        await tester.tap(find.text('PASS & PLAY'));
        await tester.pump();
        expect(gateway.createdInterstitials.length, 1);
        expect(gateway.createdInterstitials.last.showCount, 1);
        expect(find.byType(GameScreen), findsNothing);

        gateway.createdInterstitials.last.simulateDismiss();
        await pumpUi(tester);
        expect(find.byType(GameScreen), findsOneWidget);
      },
    );

    testWidgets(
      'MenuScreen VS CPU Start Match triggers Interstitial before entering GameScreen',
      (tester) async {
        setMobileViewport(tester);
        final gateway = _FakeAdGateway();
        AdManager().configureForTesting(gateway: gateway);
        await AdManager().initialize();

        await tester.pumpWidget(
          const MaterialApp(home: MenuScreen()),
        );
        await pumpUi(tester, 950);

        await tester.tap(find.text('VS CPU'));
        await pumpUi(tester);
        expect(find.text('CHOOSE DIFFICULTY'), findsOneWidget);

        await tester.tap(find.textContaining('START MATCH'));
        await tester.pump();
        expect(gateway.createdInterstitials.last.showCount, 1);
        expect(find.byType(GameScreen), findsNothing);

        gateway.createdInterstitials.last.simulateDismiss();
        await pumpUi(tester);
        expect(find.byType(GameScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GameScreen Pause -> Resume triggers Interstitial and resumes only inside onComplete',
      semanticsEnabled: false,
      (tester) async {
        setMobileViewport(tester);
        AudioService().musicEnabled = false;
        final gateway = _FakeAdGateway();
        AdManager().configureForTesting(gateway: gateway);
        await AdManager().initialize();

        await tester.pumpWidget(
          const MaterialApp(
            home: GameScreen(gameMode: GameMode.practice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Open pause dialog via pause icon anchor
        await tester.tap(
          find.byIcon(Icons.pause_circle_filled_rounded),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('GAME PAUSED'), findsOneWidget);

        // Tap Resume -> triggers Interstitial; gameplay remains paused until dismiss
        await tester.tap(find.text('RESUME'), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('GAME PAUSED'), findsNothing);
        expect(gateway.createdInterstitials.last.showCount, 1);
        expect(AdManager().isShowingAd, isTrue);

        // Dismiss ad -> resumes gameplay cleanly
        gateway.createdInterstitials.last.simulateDismiss();
        await tester.pump();
        expect(AdManager().isShowingAd, isFalse);

        // Clean unmount
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
