import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'splash_screen.dart';

/// Fullscreen startup intro displaying the ES Game Studio opening animation.
///
/// Converts smoothly to Carrom Zone's splash screen upon video completion
/// or skip tap.
class IntroScreen extends StatefulWidget {
  final bool autoNavigate;

  const IntroScreen({
    super.key,
    this.autoNavigate = true,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  VideoPlayerController? _controller;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Immersive fullscreen for opening video
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}

    try {
      final controller = VideoPlayerController.asset('assets/intro_portrait.mp4');
      _controller = controller;

      await controller.initialize();
      // Permanently muted
      await controller.setVolume(0.0);
      await controller.setLooping(false);

      if (!mounted) return;

      controller.addListener(_videoListener);
      await controller.play();

      if (mounted) {
        setState(() {});
      }

      // Safety fallback timer if playback completes without trigger
      final totalDuration = controller.value.duration;
      if (totalDuration > Duration.zero) {
        _fallbackTimer = Timer(totalDuration + const Duration(milliseconds: 300), () {
          _proceedToSplash();
        });
      }
    } catch (_) {
      // Graceful error recovery: proceed immediately to Splash
      _proceedToSplash();
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    // Trigger transition when video finishes
    if (duration > Duration.zero && position >= duration) {
      _proceedToSplash();
    }
  }

  void _proceedToSplash() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _fallbackTimer?.cancel();
    _controller?.removeListener(_videoListener);

    // Restore standard status and nav bars
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (_) {}

    if (!widget.autoNavigate) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        key: const ValueKey('intro_gesture_detector'),
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToSplash,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: isReady
              ? Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
