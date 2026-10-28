import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('PoshanSaathi app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PoshanSaathiApp());

    // Verify that the initial welcome screen renders
    expect(find.text('PoshanSaathi'), findsWidgets);
  });
}
