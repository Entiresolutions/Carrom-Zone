import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_service.dart';

/// Platform abstraction for full-screen ad lifecycle operations.
///
/// Allows [AdManager] to run natively via `google_mobile_ads` in production
/// while remaining 100% deterministic and testable in headless unit/widget tests.
abstract class AdGateway {
  Future<void> initializeSdk();

  void loadInterstitial({
    required String adUnitId,
    required void Function(AdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  });

  void loadRewarded({
    required String adUnitId,
    required void Function(RewardedAdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  });
}

/// Abstract handle over an interstitial ad instance.
abstract class AdHandle {
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  });

  void dispose();
}

/// Abstract handle over a rewarded ad instance.
abstract class RewardedAdHandle {
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  });

  void dispose();
}

class _GoogleMobileAdsGateway implements AdGateway {
  @override
  Future<void> initializeSdk() async {
    await MobileAds.instance.initialize();
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(_GoogleInterstitialHandle(ad)),
        onAdFailedToLoad: (error) => onFailed(error.message),
      ),
    );
  }

  @override
  void loadRewarded({
    required String adUnitId,
    required void Function(RewardedAdHandle ad) onLoaded,
    required void Function(String error) onFailed,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(_GoogleRewardedHandle(ad)),
        onAdFailedToLoad: (error) => onFailed(error.message),
      ),
    );
  }
}

class _GoogleInterstitialHandle implements AdHandle {
  final InterstitialAd _ad;
  _GoogleInterstitialHandle(this._ad);

  @override
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  }) async {
    _ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onFailedToShow(error.message);
      },
    );
    await _ad.show();
  }

  @override
  void dispose() {
    _ad.dispose();
  }
}

class _GoogleRewardedHandle implements RewardedAdHandle {
  final RewardedAd _ad;
  _GoogleRewardedHandle(this._ad);

  @override
  Future<void> show({
    required VoidCallback onShowed,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onDismissed,
    required void Function(String error) onFailedToShow,
  }) async {
    _ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onFailedToShow(error.message);
      },
    );
    await _ad.show(
      onUserEarnedReward: (_, _) => onUserEarnedReward(),
    );
  }

  @override
  void dispose() {
    _ad.dispose();
  }
}

/// Centralized, production-grade Google AdMob coordinator for Carrom Zone.
///
/// Features:
/// - Automatic Debug/Test vs Release/Production Ad Unit ID switching
/// - Non-blocking async initialization and preloading
/// - Exponential backoff on load failures (3s -> 6s -> 15s -> 30s max)
/// - Concurrency lock (`_isShowingAd`) preventing overlapping ads
/// - Strict non-blocking `showInterstitial` fallback when offline or unready
/// - Deterministic audio & BGM pause/restore around every full-screen ad
/// - Verified rewarded ad completion strictly inside `onUserEarnedReward`
class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  /// Configurable minimum cooldown (in seconds) between consecutive interstitials.
  /// Set to `0` so every configured placement triggers as specified; adjust from
  /// this single line if future throttling is desired.
  static const int interstitialCooldownSeconds = 0;

  // ─── Production Ad Unit IDs (Release Builds) ─────────────────────────────
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-3794659976212193/8131392910';
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-3794659976212193/1462042784';

  // ─── Official Google Test Ad Unit IDs (Debug / Profile Builds) ───────────
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static String get interstitialAdUnitId => resolveInterstitialAdUnitId();
  static String get rewardedAdUnitId => resolveRewardedAdUnitId();

  @visibleForTesting
  static String resolveInterstitialAdUnitId({bool isRelease = kReleaseMode}) =>
      isRelease ? _prodInterstitialAdUnitId : _testInterstitialAdUnitId;

  @visibleForTesting
  static String resolveRewardedAdUnitId({bool isRelease = kReleaseMode}) =>
      isRelease ? _prodRewardedAdUnitId : _testRewardedAdUnitId;

  static const List<int> backoffDelaysSeconds = [3, 6, 15, 30];

  AdGateway _gateway = _GoogleMobileAdsGateway();
  bool _forceEnableInTests = false;

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isShowingAd = false;

  AdHandle? _interstitialAd;
  bool _isLoadingInterstitial = false;
  int _interstitialRetryAttempt = 0;
  Timer? _interstitialRetryTimer;
  DateTime? _lastInterstitialDismissTime;

  RewardedAdHandle? _rewardedAd;
  bool _isLoadingRewarded = false;
  int _rewardedRetryAttempt = 0;
  Timer? _rewardedRetryTimer;
  final List<Completer<bool>> _rewardedLoadWaiters = [];

  bool get isInitialized => _isInitialized;
  bool get isShowingAd => _isShowingAd;
  bool get isInterstitialReady => _interstitialAd != null;
  bool get isRewardedReady => _rewardedAd != null;
  @visibleForTesting
  int get interstitialRetryAttempt => _interstitialRetryAttempt;
  @visibleForTesting
  int get rewardedRetryAttempt => _rewardedRetryAttempt;

  bool get _isPlatformSupported =>
      _forceEnableInTests ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  /// Injects a mock [AdGateway] and resets cached state for deterministic tests.
  @visibleForTesting
  void configureForTesting({
    required AdGateway gateway,
    bool enabled = true,
  }) {
    resetForTesting();
    _gateway = gateway;
    _forceEnableInTests = enabled;
  }

  /// Clears cached ads and cancels retry timers for clean test teardown.
  @visibleForTesting
  void resetForTesting() {
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _rewardedRetryTimer?.cancel();
    _rewardedRetryTimer = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    for (final completer in _rewardedLoadWaiters) {
      if (!completer.isCompleted) completer.complete(false);
    }
    _rewardedLoadWaiters.clear();
    _isInitialized = false;
    _isInitializing = false;
    _isShowingAd = false;
    _isLoadingInterstitial = false;
    _isLoadingRewarded = false;
    _interstitialRetryAttempt = 0;
    _rewardedRetryAttempt = 0;
    _lastInterstitialDismissTime = null;
    _gateway = _GoogleMobileAdsGateway();
    _forceEnableInTests = false;
  }

  /// Initializes the Mobile Ads SDK asynchronously without blocking UI rendering,
  /// then immediately preloads one Interstitial and one Rewarded ad.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing || !_isPlatformSupported) return;
    _isInitializing = true;
    try {
      await _gateway.initializeSdk();
      _isInitialized = true;
      loadInterstitial();
      loadRewarded();
    } catch (e) {
      debugPrint('AdManager initialize error (non-fatal): $e');
    } finally {
      _isInitializing = false;
    }
  }

  int _nextBackoffSeconds(int attempt) {
    final int idx = attempt.clamp(0, backoffDelaysSeconds.length - 1);
    return backoffDelaysSeconds[idx];
  }

  // ─── Interstitial Loading & Preload ───────────────────────────────────────

  void loadInterstitial({bool resetBackoff = false}) {
    if (!_isPlatformSupported) return;
    if (resetBackoff) {
      _interstitialRetryTimer?.cancel();
      _interstitialRetryTimer = null;
      _interstitialRetryAttempt = 0;
    }
    if (_interstitialAd != null ||
        _isLoadingInterstitial ||
        _interstitialRetryTimer?.isActive == true) {
      return;
    }

    _isLoadingInterstitial = true;
    try {
      _gateway.loadInterstitial(
        adUnitId: interstitialAdUnitId,
        onLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialRetryAttempt = 0;
          _interstitialRetryTimer?.cancel();
          _interstitialRetryTimer = null;
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onFailed: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          debugPrint('AdManager Interstitial load failed: $error');
          _scheduleInterstitialRetry();
        },
      );
    } catch (e) {
      _isLoadingInterstitial = false;
      _interstitialAd = null;
      debugPrint('AdManager Interstitial load exception: $e');
      _scheduleInterstitialRetry();
    }
  }

  void _scheduleInterstitialRetry() {
    if (!_isPlatformSupported) return;
    _interstitialRetryTimer?.cancel();
    final int delaySec = _nextBackoffSeconds(_interstitialRetryAttempt);
    _interstitialRetryAttempt++;
    _interstitialRetryTimer = Timer(Duration(seconds: delaySec), () {
      _interstitialRetryTimer = null;
      loadInterstitial();
    });
  }

  bool _isInInterstitialCooldown() {
    if (interstitialCooldownSeconds <= 0 || _lastInterstitialDismissTime == null) {
      return false;
    }
    final int elapsed =
        DateTime.now().difference(_lastInterstitialDismissTime!).inSeconds;
    return elapsed < interstitialCooldownSeconds;
  }

  /// Displays a preloaded Interstitial ad if ready and not locked/cooling down.
  ///
  /// Strictly non-blocking: if offline, unready, unsupported, or already showing
  /// an ad, [onComplete] executes immediately so navigation and gameplay never freeze.
  void showInterstitial({required VoidCallback onComplete}) {
    if (!_isPlatformSupported) {
      onComplete();
      return;
    }

    if (_isShowingAd || _isInInterstitialCooldown()) {
      onComplete();
      return;
    }

    final AdHandle? ad = _interstitialAd;
    if (ad == null) {
      // Trigger a background preload if not waiting, and continue immediately.
      loadInterstitial();
      onComplete();
      return;
    }

    _interstitialAd = null;
    _isShowingAd = true;
    bool completed = false;

    void finishOnce({required bool recordDismissTime}) {
      if (completed) return;
      completed = true;
      _isShowingAd = false;
      if (recordDismissTime) {
        _lastInterstitialDismissTime = DateTime.now();
      }
      AudioService().onAdClosed();
      loadInterstitial(resetBackoff: true);
      onComplete();
    }

    AudioService().onAdOpened();
    try {
      ad
          .show(
            onShowed: () => AudioService().onAdOpened(),
            onDismissed: () => finishOnce(recordDismissTime: true),
            onFailedToShow: (error) {
              debugPrint('AdManager Interstitial failed to show: $error');
              finishOnce(recordDismissTime: false);
            },
          )
          .catchError((Object e) {
        debugPrint('AdManager Interstitial show error: $e');
        ad.dispose();
        finishOnce(recordDismissTime: false);
      });
    } catch (e) {
      debugPrint('AdManager Interstitial show exception: $e');
      ad.dispose();
      finishOnce(recordDismissTime: false);
    }
  }

  // ─── Rewarded Loading & Verified Playback ─────────────────────────────────

  void loadRewarded({bool resetBackoff = false}) {
    if (!_isPlatformSupported) return;
    if (resetBackoff) {
      _rewardedRetryTimer?.cancel();
      _rewardedRetryTimer = null;
      _rewardedRetryAttempt = 0;
    }
    if (_rewardedAd != null ||
        _isLoadingRewarded ||
        (_rewardedRetryTimer?.isActive == true && !resetBackoff)) {
      return;
    }

    _isLoadingRewarded = true;
    try {
      _gateway.loadRewarded(
        adUnitId: rewardedAdUnitId,
        onLoaded: (ad) {
          _isLoadingRewarded = false;
          _rewardedRetryAttempt = 0;
          _rewardedRetryTimer?.cancel();
          _rewardedRetryTimer = null;
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _completeRewardedWaiters(true);
        },
        onFailed: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
          debugPrint('AdManager Rewarded load failed: $error');
          _completeRewardedWaiters(false);
          _scheduleRewardedRetry();
        },
      );
    } catch (e) {
      _isLoadingRewarded = false;
      _rewardedAd = null;
      debugPrint('AdManager Rewarded load exception: $e');
      _completeRewardedWaiters(false);
      _scheduleRewardedRetry();
    }
  }

  void _completeRewardedWaiters(bool loaded) {
    if (_rewardedLoadWaiters.isEmpty) return;
    final copy = List<Completer<bool>>.from(_rewardedLoadWaiters);
    _rewardedLoadWaiters.clear();
    for (final waiter in copy) {
      if (!waiter.isCompleted) waiter.complete(loaded);
    }
  }

  void _scheduleRewardedRetry() {
    if (!_isPlatformSupported) return;
    _rewardedRetryTimer?.cancel();
    final int delaySec = _nextBackoffSeconds(_rewardedRetryAttempt);
    _rewardedRetryAttempt++;
    _rewardedRetryTimer = Timer(Duration(seconds: delaySec), () {
      _rewardedRetryTimer = null;
      loadRewarded();
    });
  }

  Future<bool> _awaitRewardedLoad(Duration timeout) async {
    if (_rewardedAd != null) return true;
    final completer = Completer<bool>();
    _rewardedLoadWaiters.add(completer);

    // Force an immediate load attempt regardless of any previous backoff wait.
    loadRewarded(resetBackoff: true);

    try {
      final bool loaded = await completer.future.timeout(
        timeout,
        onTimeout: () {
          _rewardedLoadWaiters.remove(completer);
          return false;
        },
      );
      return loaded && _rewardedAd != null;
    } catch (_) {
      _rewardedLoadWaiters.remove(completer);
      return false;
    }
  }

  /// Presents a Rewarded Ad for unlocking a theme.
  ///
  /// - If no ad is currently cached, triggers an immediate load with up to
  ///   [loadTimeout] (~5 seconds), invoking [onLoadingStart] / [onLoadingEnd].
  /// - [onUserEarnedReward] is invoked strictly inside the official SDK reward callback.
  /// - [onAdDismissed] is invoked after the ad closes (or fails after reward), passing
  ///   whether a reward was earned so UI/toasts update visibly after dismissal.
  /// - [onAdUnavailable] is called if offline, timed out, or failed to show before reward.
  Future<void> showRewardedAd({
    required FutureOr<void> Function() onUserEarnedReward,
    required void Function(bool rewardEarned) onAdDismissed,
    required VoidCallback onAdUnavailable,
    VoidCallback? onLoadingStart,
    VoidCallback? onLoadingEnd,
    bool Function()? canPresent,
    Duration loadTimeout = const Duration(seconds: 5),
  }) async {
    if (!_isPlatformSupported || _isShowingAd) {
      onAdUnavailable();
      return;
    }

    if (_rewardedAd == null) {
      onLoadingStart?.call();
      final bool loaded = await _awaitRewardedLoad(loadTimeout);
      onLoadingEnd?.call();
      if (canPresent != null && !canPresent()) {
        return;
      }
      if (!loaded || _rewardedAd == null) {
        onAdUnavailable();
        return;
      }
    }

    if (canPresent != null && !canPresent()) {
      return;
    }

    final RewardedAdHandle? ad = _rewardedAd;
    if (ad == null) {
      onAdUnavailable();
      return;
    }

    _rewardedAd = null;
    _isShowingAd = true;
    bool rewardEarned = false;
    bool finished = false;
    Future<void>? pendingRewardPersist;

    Future<void> handleDismissed() async {
      if (finished) return;
      finished = true;
      if (pendingRewardPersist != null) {
        try {
          await pendingRewardPersist;
        } catch (_) {}
      }
      _isShowingAd = false;
      AudioService().onAdClosed();
      loadRewarded(resetBackoff: true);
      onAdDismissed(rewardEarned);
    }

    void handleFailedToShow() {
      if (finished) return;
      finished = true;
      _isShowingAd = false;
      AudioService().onAdClosed();
      loadRewarded(resetBackoff: true);
      if (rewardEarned) {
        onAdDismissed(true);
      } else {
        onAdUnavailable();
      }
    }

    AudioService().onAdOpened();
    try {
      await ad.show(
        onShowed: () => AudioService().onAdOpened(),
        onUserEarnedReward: () {
          if (rewardEarned) return;
          rewardEarned = true;
          final FutureOr<void> result = onUserEarnedReward();
          if (result is Future<void>) {
            pendingRewardPersist = result;
          }
        },
        onDismissed: () {
          unawaited(handleDismissed());
        },
        onFailedToShow: (error) {
          debugPrint('AdManager Rewarded failed to show: $error');
          handleFailedToShow();
        },
      );
    } catch (e) {
      debugPrint('AdManager Rewarded show exception: $e');
      ad.dispose();
      handleFailedToShow();
    }
  }
}
