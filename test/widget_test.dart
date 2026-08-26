import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/main.dart';

void main() {
  testWidgets('MyApp renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
