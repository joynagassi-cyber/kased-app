import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';

void main() {
  testWidgets('basic app loads without error', (WidgetTester tester) async {
    // Simple test that app can be pumped without crashing
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) {
          // Simple auth state that's already loaded
          return AppData.authenticated('test@example.com');
        }),
      ],
      child: const KasedApp(),
    ));

    // Just check that the app renders without throwing
    expect(find.byType(KasedApp), findsOneWidget);
  });
}
