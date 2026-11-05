import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/design_system.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  group('Bottom Navigation Icons Verification', () {
    testWidgets('1. ClubIcon builds rounded Material icons for rules, themes, settings', (tester) async {
      const List<(ClubIconType, IconData)> mappings = [
        (ClubIconType.rules, Icons.menu_book_rounded),
        (ClubIconType.themes, Icons.palette_rounded),
        (ClubIconType.settings, Icons.tune_rounded),
      ];

      for (final (iconType, expectedIcon) in mappings) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClubIcon(
                type: iconType,
                size: 24,
                color: const Color(0xFF14243B),
              ),
            ),
          ),
        );

        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('2. MenuScreen mounts redesigned bottom nav with RULES, THEMES, and SETTINGS', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: repaintKey,
            child: const MenuScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('RULES'), findsOneWidget);
      expect(find.text('THEMES'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);

      // Verify that ClubIcon is used with the new types
      expect(find.byWidgetPredicate((w) => w is ClubIcon && w.type == ClubIconType.rules), findsWidgets);
      expect(find.byWidgetPredicate((w) => w is ClubIcon && w.type == ClubIconType.themes), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is ClubIcon && w.type == ClubIconType.settings), findsWidgets);

      // Capture screenshot of the menu screen with the bottom navigation dock
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        await tester.runAsync(() async {
          final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final out = File('C:/Users/Entire/.gemini/antigravity/brain/38ed6c08-0265-4f66-897c-e5eb770a993b/menu_with_bottom_nav_preview.png');
            await out.writeAsBytes(byteData.buffer.asUint8List());
            // ignore: avoid_print
            print('Saved menu preview with bottom nav to ${out.path}');
          }
        });
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });
  });
}
