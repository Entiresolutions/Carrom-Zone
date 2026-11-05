import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import '../services/audio_service.dart';
import '../services/piece_asset_service.dart';
import '../services/storage_service.dart';
import '../services/striker_asset_service.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
  });

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
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
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

    _progressAnimation = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
    if (widget.autoNavigate) {
      _initAppAndNavigate();
    }
  }

  Future<void> _initAppAndNavigate() async {
    await StorageService().init();
    await AudioService().init();
    await StrikerAssetService.instance.preloadAll();
    await PieceAssetService.instance.preloadAll();

    if (mounted) {
      await ClubBackground.precacheAll(context);
    }

    AudioService().sfxEnabled = StorageService().getSfxEnabled();
    AudioService().musicEnabled = StorageService().getMusicEnabled();
    AudioService().hapticsEnabled = StorageService().getHapticsEnabled();

    if (AudioService().musicEnabled) {
      AudioService().playBgm();
    }

    await Future.delayed(const Duration(milliseconds: 1800));
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
    final Size size = MediaQuery.of(context).size;
    final double logoSize = (size.width * 0.72).clamp(240.0, 320.0);
    final double loadingBarWidth = (size.width * 0.74).clamp(260.0, 360.0);

    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.splash,
        child: SafeArea(
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
                  child: Stack(
                    children: [
                      // Top Half: Grand Logo Area & Slogan Bar
                      Positioned(
                        top: size.height * 0.05,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grand Carrom Zone Logo with Ambient Radiant Glow
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Golden / Emerald ambient radial aura
                                Container(
                                  width: logoSize * 1.15,
                                  height: logoSize * 1.15,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0x60FFD700),
                                        Color(0x2800E676),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                                CarromZoneLogo(
                                  size: logoSize,
                                  showShadow: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Luxury Slogan Pill: "PLAY • COMPETE • MASTER"
                            _buildSloganPill(),
                          ],
                        ),
                      ),

                      // Bottom Half: Glowing Premium Loading Section (sitting on wooden board scene)
                      Positioned(
                        bottom: size.height * 0.045,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGlowingLoadingBar(loadingBarWidth, progress),
                            const SizedBox(height: 10),
                            _buildLoadingText(),
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
    );
  }

  Widget _buildSloganPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7.5),
      decoration: BoxDecoration(
        color: const Color(0xE6052014), // Deep emerald glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5C058), // Polished gold
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40C5993B),
            blurRadius: 14,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left Starburst Flare Glint
          _buildStarburstFlare(),
          const SizedBox(width: 8),
          Text(
            'PLAY  •  COMPETE  •  MASTER',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
              color: const Color(0xFFFFF2D1),
              shadows: const [
                Shadow(
                  color: Color(0x80D4AF37),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right Starburst Flare Glint
          _buildStarburstFlare(),
        ],
      ),
    );
  }

  Widget _buildStarburstFlare() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFF9E6),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFDF7A),
            blurRadius: 5,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingLoadingBar(double width, double progress) {
    const double barHeight = 17.0;

    return Container(
      width: width,
      height: barHeight,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        // Metallic Gold Beveled Frame
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFDF7A), // Bright gold highlight
            Color(0xFFD4AF37), // Classic gold
            Color(0xFF8C651A), // Deep gold shadow
          ],
        ),
        boxShadow: [
          // Ambient gold glow
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.35),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
          // Deep drop shadow onto wooden board
          const BoxShadow(
            color: Color(0x80000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF04120A), // Dark inner track
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.02, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // Radiant Neon Emerald Green Fill
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF69F0AE), // Mint highlight top
                  Color(0xFF00E676), // Vibrant neon emerald
                  Color(0xFF00B248), // Deep emerald base
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8800E676),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Glossy Highlight Reflection Streak
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: (barHeight - 4) * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle left gold horizontal taper line
        Container(
          width: 32,
          height: 1.2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x99D4AF37),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'LOADING...',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.8,
            color: const Color(0xFFF9E8B6),
            shadows: const [
              Shadow(
                color: Color(0x60000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Color(0x40D4AF37),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Subtle right gold horizontal taper line
        Container(
          width: 32,
          height: 1.2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x99D4AF37),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
