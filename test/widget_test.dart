import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/main.dart';

void main() {
  testWidgets('LifeLink App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify LifeLink brand is present
    expect(find.text('LifeLink'), findsOneWidget);
    expect(find.text('Connecting Donors, Saving Lives'), findsOneWidget);
  });
}
