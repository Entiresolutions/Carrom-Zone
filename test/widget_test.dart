import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/main.dart';

void main() {
  testWidgets('Carrom Master App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarromMasterApp());
    expect(find.byType(CarromMasterApp), findsOneWidget);
  });
}
