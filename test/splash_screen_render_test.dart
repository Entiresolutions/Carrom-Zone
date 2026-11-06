import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Render and verify Carrom Zone premium splash screen', (tester) async {
    // Standard high-end mobile portrait (1080x2160 aspect ratio: 450x900 logical)
    await tester.binding.setSurfaceSize(const Size(450, 900));

    final GlobalKey repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const SplashScreen(autoNavigate: false),
        ),
      ),
    );

    // Pump to mid-loading progress (around 65% progress)
    await tester.pump(const Duration(milliseconds: 750));

    // Verify critical elements are present
    expect(find.text('PLAY  •  COMPETE  •  MASTER'), findsOneWidget);
    expect(find.text('LOADING...'), findsOneWidget);

    // Capture rendered screenshot
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final out = File('build/test_previews/splash_rendered_preview.png');
          if (!out.parent.existsSync()) {
            out.parent.createSync(recursive: true);
          }
          await out.writeAsBytes(byteData.buffer.asUint8List());
          // ignore: avoid_print
          print('Captured splash screen preview at ${out.path}');
        }
      });
    }

    // Clean up
    await tester.binding.setSurfaceSize(null);
  });
}
