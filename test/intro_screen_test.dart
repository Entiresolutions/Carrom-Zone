import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/screens/intro_screen.dart';
import 'package:carrom_master/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IntroScreen renders with pure white background and handles tap skip',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(450, 900));

    await tester.pumpWidget(
      const MaterialApp(
        home: IntroScreen(autoNavigate: false),
      ),
    );

    // Verify IntroScreen is mounted
    expect(find.byType(IntroScreen), findsOneWidget);

    // Verify root container has white background
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);

    // Verify GestureDetector exists for tap-to-skip
    expect(find.byType(GestureDetector), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('IntroScreen transitions to SplashScreen on skip tap when autoNavigate is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntroScreen(autoNavigate: true),
      ),
    );

    await tester.pump();

    // Tap to skip
    await tester.tap(find.byKey(const ValueKey('intro_gesture_detector')), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should navigate to SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
