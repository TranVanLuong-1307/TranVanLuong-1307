import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/app.dart';

void main() {
  testWidgets('NotificationInsightApp smoke test', (WidgetTester tester) async {
    // Build app widget
    await tester.pumpWidget(const NotificationInsightApp());

    // Verify main screen scaffold builds
    expect(find.byType(NotificationInsightApp), findsOneWidget);
  });
}
