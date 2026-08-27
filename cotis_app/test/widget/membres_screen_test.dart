import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/screens/membres/membres_screen.dart';
import 'package:kased_app/providers/kased_app_provider.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/core/services/stats_service.dart';

// Fake KasedApp that returns controlled state for testing
class FakeKasedApp extends KasedApp {
  final AppState _state;

  FakeKasedApp(this._state);

  @override
  Future<AppState> build() async {
    return _state;
  }

  @override
  DashboardStats getDashboardStats() => DashboardStats(
        totalMembres: _state.membres.length,
        totalCultes: _state.cultes.length,
        totalCollecte: 0,
        membresEnRetard: 0,
        totalDu: 0,
      );

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> syncData() async {}

  @override
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async => [];

  @override
  List<Map<String, dynamic>> getRetardsMembresLocally() => [];
}

void main() {
  Widget createMembresScreen(AppState state) {
    return ProviderScope(
      overrides: [
        kasedAppProvider.overrideWith(() => FakeKasedApp(state)),
      ],
      child: const MaterialApp(
        home: MembresScreen(),
      ),
    );
  }

  testWidgets('Renders list of members', (WidgetTester tester) async {
    final membres = [
      Membre()
        ..id = '1'
        ..nom = 'Doe'
        ..prenom = 'John'
        ..telephone = '123'
        ..dateAdhesion = DateTime(2023),
    ];
    final state = AppState(membres: membres, cultes: [], cotisations: []);

    await tester.pumpWidget(createMembresScreen(state));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Membres'), findsOneWidget);
  });

  testWidgets('Shows empty state when no members', (WidgetTester tester) async {
    final state = AppState(membres: [], cultes: [], cotisations: []);

    await tester.pumpWidget(createMembresScreen(state));
    await tester.pumpAndSettle();

    expect(find.text('Aucun membre enregistré'), findsOneWidget);
  });
}
