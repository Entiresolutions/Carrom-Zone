import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/services/audio_service.dart';

Widget _buildTestApp({
  required Widget child,
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: Scaffold(
            body: Center(
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  setUp(() {
    AudioService().sfxEnabled = false;
    AudioService().hapticsEnabled = false;
  });

  group('Responsive Difficulty Dialog Tests', () {
    const List<Size> testScreenSizes = [
      Size(390, 844), // Standard modern phone (iPhone 14 / Pixel 7)
      Size(360, 640), // Common compact Android
      Size(375, 667), // iPhone SE 2nd / 3rd gen
      Size(320, 568), // Ultra compact phone (iPhone SE 1st gen)
      Size(320, 480), // Legacy / small display
      Size(800, 360), // Landscape mobile
      Size(412, 915), // Tall flagship Android
      Size(768, 1024), // Tablet
    ];

    for (final size in testScreenSizes) {
      testWidgets('Adapts properly on ${size.width.toInt()}x${size.height.toInt()} screen without overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        AiDifficulty? chosenDifficulty;

        await tester.pumpWidget(
          _buildTestApp(
            child: DifficultySelectionDialog(
              currentDifficulty: AiDifficulty.medium,
              ruleset: CarromRuleset.classic,
              onDifficultyChosen: (diff) {
                chosenDifficulty = diff;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify no RenderFlex overflow occurs
        expect(tester.takeException(), isNull,
            reason: 'Overflow occurred on screen size ${size.width}x${size.height}');

        // 2. Verify Title and Header are displayed
        expect(find.text('CHOOSE DIFFICULTY'), findsOneWidget);

        // 3. Verify Difficulty options (Easy, Medium, Hard) exist
        expect(find.text('EASY'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);
        expect(find.text('HARD'), findsOneWidget);

        // 4. Verify Start Match button is visible and on screen
        final startButtonFinder = find.textContaining('START MATCH');
        expect(startButtonFinder, findsOneWidget);

        // 5. Verify the button is accessible and on-screen
        final startButtonElement = tester.element(startButtonFinder);
        final renderBox = startButtonElement.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        expect(position.dy, greaterThanOrEqualTo(0.0),
            reason: 'Button is pushed off top of screen');
        expect(position.dy + renderBox.size.height, lessThanOrEqualTo(size.height),
            reason: 'Button is pushed off bottom of screen on size ${size.width}x${size.height}');

        // 6. Test interaction: scroll to HARD if needed, tap HARD option and START MATCH
        final hardFinder = find.text('HARD');
        await tester.scrollUntilVisible(hardFinder, 50.0, scrollable: find.byType(Scrollable));
        await tester.pumpAndSettle();

        await tester.tap(hardFinder);
        await tester.pumpAndSettle();

        expect(find.text('START MATCH (HARD)'), findsOneWidget);

        await tester.tap(find.text('START MATCH (HARD)'));
        await tester.pumpAndSettle();

        expect(chosenDifficulty, equals(AiDifficulty.hard));
      });
    }

    testWidgets('Handles large accessibility text scaling (1.5x) without overflow or clipping',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          textScaleFactor: 1.5,
          child: DifficultySelectionDialog(
            currentDifficulty: AiDifficulty.medium,
            ruleset: CarromRuleset.freestyle,
            onDifficultyChosen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no overflow despite large text scaling
      expect(tester.takeException(), isNull);
      expect(find.text('CHOOSE DIFFICULTY'), findsOneWidget);
      expect(find.textContaining('START MATCH'), findsOneWidget);
    });
  });
}
