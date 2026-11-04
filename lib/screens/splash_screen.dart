import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
    _initAppAndNavigate();
  }

  Future<void> _initAppAndNavigate() async {
    await StorageService().init();
    await AudioService().init();

    if (mounted) {
      await ClubBackground.precacheAll(context);
    }

    AudioService().sfxEnabled = StorageService().getSfxEnabled();
    AudioService().musicEnabled = StorageService().getMusicEnabled();
    AudioService().hapticsEnabled = StorageService().getHapticsEnabled();

    if (AudioService().musicEnabled) {
      AudioService().playBgm();
    }

    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;

    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context).pushReplacement(
      ClubPageRoute(
        page: const MenuScreen(),
        reducedMotion: reducedMotion,
        duration: const Duration(milliseconds: 480),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);

    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.splash,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double opacity =
                    reducedMotion ? 1.0 : _opacityAnimation.value;
                final double scale =
                    reducedMotion ? 1.0 : _scaleAnimation.value;
                final double progress =
                    reducedMotion ? 1.0 : _progressAnimation.value;

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Official 3D Carrom Zone Logo
                        const CarromZoneLogo(size: 216),

                        const SizedBox(height: 18),

                        // Subtle Tagline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.55),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'PLAY   •   COMPETE   •   MASTER',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),

                        const Spacer(flex: 6),

                        // Sleek Champagne-Gold Progress Bar
                        SizedBox(
                          width: 176,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 3.5,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD8CCBA),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.gold,
                                          AppColors.goldLight,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withOpacity(0.45),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'LOADING...',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
