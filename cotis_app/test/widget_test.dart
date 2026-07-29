import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';

void main() {
  testWidgets('renders the dashboard shell', (WidgetTester tester) async {
    // Simple fake service that returns empty data
    class FakeInsForgeService implements InsForgeService {
      FakeInsForgeService();

      @override
      Future<Map<String, dynamic>> getDashboard() async => {};

      @override
      Future<List<Map<String, dynamic>>> getCultes({int page = 1, int pageSize = 50}) async => [];
      @override
      Future<List<Map<String, dynamic>>> getMembres({int page = 1, int pageSize = 100}) async => [];
      @override
      Future<List<Map<String, dynamic>>> getRetardsMembres() async => [];
      @override
      Future<List<Map<String, dynamic>>> getMembresAJour() async => [];
      @override
      Future<List<Map<String, dynamic>>> getMembresEnAvance() async => [];

      // Minimal empty implementations for all other methods...
      @override
      Future<void> updateMembre(String id, Map<String, dynamic> data) async {}
      @override
      Future<void> deleteMembre(String id) async {}
      @override
      Future<String> creerCulteAvecCotisations({required DateTime dateCulte, String? titre, double montantCotisation = 50.0}) async => 'test-uuid';
      @override
      Future<void> updateCulte(String id, Map<String, dynamic> data) async {}
      @override
      Future<void> deleteCulte(String id) async {}
      @override
      Future<void> createCotisations(List<Map<String, dynamic>> data) async {}
      @override
      Future<void> updateCotisation(String id, Map<String, dynamic> data) async {}
      @override
      Future<List<Map<String, dynamic>>> getCotisations() async => [];
      @override
      Future<List<Map<String, dynamic>>> getCotisationsDuCulte(String culteId) async => [];
      @override
      Future<List<Map<String, dynamic>>> getCotisationsDuMembre(String membreId) async => [];
      @override
      Future<Map<String, dynamic>> togglePaiement({required String membreId, required String culteId}) async => {};
      @override
      Future<Map<String, dynamic>> marquerAbsent({required String membreId, required String culteId}) async => {};
      @override
      Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId) async => [];
      @override
      Future<void> deleteCotisation(String id) async {}
      @override
      Future<void> setCotisationStatut({required String membreId, required String culteId, required String statut}) async {}
      @override
      Future<void> deleteCotisationsDuCulte(String culteId) async {}
      @override
      Future<List<Map<String, dynamic>>> getChangesSince(String? lastSyncAt) async => [];
      @override
      Future<String?> uploadMembrePhoto(String filePath, String fileName) async => null;
    }

    // Fake app data that returns immediately without async operations
    class FakeAppData extends AppData {
      @override
      FutureOr<AppState> build() async {
        return AppState(
          membres: [],
          cultes: [],
          cotisations: [],
          isLoading: false,
        );
      }

      @override
      Future<void> syncData() async {}

      @override
      Future<void> loadDashboard() async {}
    }

    // Fake auth state - already authenticated
    class FakeAuth extends Auth {
      final AuthState state;
      FakeAuth(this.state);

      @override
      AuthState build() => state;
    }

    final fakeApi = FakeInsForgeService();
    final fakeAppData = FakeAppData();

    // Build the app with overrides
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Override Auth provider to provide authenticated state immediately
        authProvider.overrideWith((ref) => FakeAuth(
          const AuthState(
            isAuthenticated: true,
            isLoading: false,
            userEmail: 'test@example.com',
          ),
        )),
        // Override AppData provider to use fake that returns immediately
        appDataProvider.overrideWith((ref) => fakeAppData),
      ],
      child: const KasedApp(),
    ));

    // Quick pump to let the app settle
    await tester.pump(const Duration(milliseconds: 300));

    // Verify we can find the "Accueil" text
    expect(find.text('Accueil'), findsAtLeastNWidgets(1));
  });
}
