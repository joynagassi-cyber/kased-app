import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/screens/membres/membres_screen.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/models/membre.dart';
import 'package:mocktail/mocktail.dart';

// Use AutoDisposeAsyncNotifier as base to avoid _setElement errors
class MockAppDataNotifier extends AutoDisposeAsyncNotifier<AppState> with Mock implements AppData {}

void main() {
  late MockAppDataNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockAppDataNotifier();
  });

  Widget createMembresScreen() {
    return ProviderScope(
      overrides: [
        appDataProvider.overrideWith(() => mockNotifier),
      ],
      child: const MaterialApp(
        home: MembresScreen(),
      ),
    );
  }

  testWidgets('Renders list of members', (WidgetTester tester) async {
    final membres = [
      Membre()..id = '1'..nom = 'Doe'..prenom = 'John'..telephone = '123'..dateAdhesion = DateTime(2023),
    ];
    final state = AppState(membres: membres, cultes: [], cotisations: []);
    
    when(() => mockNotifier.build()).thenAnswer((_) async => state);
    when(() => mockNotifier.loadRetardsMembres()).thenAnswer((_) async => []);

    await tester.pumpWidget(createMembresScreen());
    await tester.pump(); 
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Membres'), findsOneWidget);
  });

  testWidgets('Shows empty state when no members', (WidgetTester tester) async {
    final state = AppState(membres: [], cultes: [], cotisations: []);
    
    when(() => mockNotifier.build()).thenAnswer((_) async => state);
    when(() => mockNotifier.loadRetardsMembres()).thenAnswer((_) async => []);

    await tester.pumpWidget(createMembresScreen());
    await tester.pumpAndSettle();

    expect(find.text('Aucun membre enregistré'), findsOneWidget);
  });
}
