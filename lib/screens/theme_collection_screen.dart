import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/championship_theme.dart';
import '../core/championship_widgets.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'settings_screen.dart';
import 'tutorial_dialog.dart';

/// Redesigned Theme Collection Screen for "Carrom Zone".
/// Pure UI/UX redesign: Championship Club cream background, white cards,
/// 60-30-10 color balance, 2-column responsive theme grid, active theme showcase,
/// and fixed floating bottom navigation dock (Themes tab active).
/// ZERO changes to game logic or service layers.
class ThemeCollectionScreen extends StatefulWidget {
  const ThemeCollectionScreen({super.key});

  @override
  State<ThemeCollectionScreen> createState() => _ThemeCollectionScreenState();
}

class _ThemeCollectionScreenState extends State<ThemeCollectionScreen>
    with SingleTickerProviderStateMixin {
  late BoardThemeType _selectedTheme;
  AnimationController? _entranceController;

  @override
  void initState() {
    super.initState();
    _loadState();
    _initEntranceController();
  }

  void _initEntranceController() {
    _entranceController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    super.dispose();
  }

  void _loadState() {
    _selectedTheme = StorageService().getBoardTheme();
  }

  void _selectTheme(ThemeCatalogItem item) {
    if (!item.isUnlocked) {
      AudioService().hapticSelection();
      _showPurchaseUnavailableDialog(item);
      return;
    }

    AudioService().hapticSelection();
    AudioService().playHit();
    StorageService().setBoardTheme(item.theme);
    setState(() {
      _selectedTheme = item.theme;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ChampionshipColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ChampionshipColors.cardBorder, width: 1.0),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} activated for play!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPurchaseUnavailableDialog(ThemeCatalogItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 370),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ChampionshipColors.cardSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ChampionshipColors.cardBorder, width: 1.2),
            boxShadow: ChampionshipColors.floatingDockShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemeBoardPreview(
                theme: item.theme,
                size: 78,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 14),
              Text(
                item.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: ChampionshipTypography.brandTitle(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'PREMIUM TABLE THEME • ${item.priceDisplay}',
                style: ChampionshipTypography.overline(
                  fontSize: 11,
                  color: ChampionshipColors.goldLabel,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: ChampionshipTypography.subtitle(
                  fontSize: 12.5,
                  color: ChampionshipColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: ChampionshipColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChampionshipColors.cardBorderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: ChampionshipColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'In-app purchases are coming soon! Google Play Billing integration is currently in preparation.',
                        style: ChampionshipTypography.subtitle(
                          fontSize: 11,
                          color: ChampionshipColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ChampionshipColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CLOSE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ChampionshipColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (DevOptions.enabled) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ChampionshipColors.greenGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await ThemeService().devUnlockTheme(item.theme);
                            await StorageService().setBoardTheme(item.theme);
                            setState(_loadState);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'DEV UNLOCK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTutorial() {
    AudioService().hapticSelection();
    TutorialDialog.show(context);
  }

  void _openSettings() {
    AudioService().hapticSelection();
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context).pushReplacement(
      ClubPageRoute(
        page: const SettingsScreen(),
        reducedMotion: reducedMotion,
      ),
    );
  }

  Widget _animatedItem({required int index, required Widget child}) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final controller = _entranceController;
    if (reducedMotion || controller == null) return child;

    final double start = (index * 0.08).clamp(0.0, 0.75);
    final double end = math.min(1.0, start + 0.45);
    final Animation<double> curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - curved.value) * 16.0),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    _initEntranceController();
    final List<ThemeCatalogItem> items = ThemeService().getCatalogItems();
    final freeItems = items.where((i) => i.isFree).toList();
    final premiumItems = items.where((i) => i.isPremium).toList();
    final currentItem = items.firstWhere(
      (i) => i.theme == _selectedTheme,
      orElse: () => items.first,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ChampionshipColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: ChampionshipBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Scrollable Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        // Shared Page Header
                        _animatedItem(
                          index: 0,
                          child: ChampionshipAppHeader(
                            title: 'THEME COLLECTION',
                            subtitle: '11 CHAMPIONSHIP TABLE THEMES',
                            onBack: () => Navigator.of(context).pop(),
                            action: DevOptions.enabled
                                ? ChampionshipIconButton(
                                    iconType: ClubIconType.school,
                                    tooltip: 'Dev Testing Console',
                                    size: 40,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (ctx) => DevThemeTesterSheet(
                                          onChanged: () {
                                            if (mounted) setState(_loadState);
                                          },
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        ),

                        // Scrollable Themes
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Current Active Theme Card
                                _animatedItem(
                                  index: 1,
                                  child: _buildCurrentThemeCard(currentItem),
                                ),
                                const SizedBox(height: 20),

                                // 2. STARTER THEMES (FREE) Section
                                _animatedItem(
                                  index: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'STARTER THEMES (FREE)',
                                          style: ChampionshipTypography.overline(
                                            color: ChampionshipColors.goldLabel,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'Always Unlocked',
                                          style: ChampionshipTypography.subtitle(
                                            fontSize: 11.5,
                                            color: ChampionshipColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _animatedItem(
                                  index: 3,
                                  child: _buildThemeGrid(freeItems),
                                ),
                                const SizedBox(height: 20),

                                // 3. CHAMPIONSHIP THEMES (PREMIUM) Section
                                _animatedItem(
                                  index: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'CHAMPIONSHIP THEMES (PREMIUM)',
                                          style: ChampionshipTypography.overline(
                                            color: ChampionshipColors.goldLabel,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'Exclusive Table Finishes',
                                          style: ChampionshipTypography.subtitle(
                                            fontSize: 11.5,
                                            color: ChampionshipColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _animatedItem(
                                  index: 5,
                                  child: _buildThemeGrid(premiumItems),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Bottom Navigation Dock (Themes tab active)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: ChampionshipBottomNav(
                          activeTab: ChampionshipTab.themes,
                          onOpenRules: _openTutorial,
                          onOpenThemes: () {
                            // Already on Themes screen
                          },
                          onOpenSettings: _openSettings,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentThemeCard(ThemeCatalogItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChampionshipColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ChampionshipColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: ChampionshipColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChampionshipColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ThemeBoardPreview(
              theme: item.theme,
              size: 64,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'CURRENTLY EQUIPPED',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChampionshipTypography.overline(
                          color: ChampionshipColors.goldLabel,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5EE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF9FD4B3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 10, color: Color(0xFF1B6A45)),
                          SizedBox(width: 3),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B6A45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChampionshipTypography.cardTitle(
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChampionshipTypography.subtitle(
                    fontSize: 12,
                    color: ChampionshipColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(List<ThemeCatalogItem> items) {
    // 2-column grid pairs for deterministic, responsive scroll performance
    final List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = (i + 1 < items.length) ? items[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ChampionshipThemeGridCard(
                  item: left,
                  onTap: () => _selectTheme(left),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? ChampionshipThemeGridCard(
                        item: right,
                        onTap: () => _selectTheme(right),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
