import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kased_app/main.dart';
import 'package:kased_app/providers/auth_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders the dashboard shell', (WidgetTester tester) async {
    // Initialiser avec un état authentifié pour éviter d'être bloqué sur loading ou redirigé vers onboarding
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(() => FakeAuthNotifier(
          const AuthState(
            isAuthenticated: true, 
            isLoading: false,
            userEmail: 'test@example.com',
          )
        )),
        // Mock AppData pour éviter les appels Isar et Réseau
        appDataProvider.overrideWith(() => FakeAppDataNotifier()),
        // Mock InsForgeService pour éviter LateInitializationError
        insForgeServiceProvider.overrideWithValue(FakeInsForgeService()),
      ],
      child: const KasedApp(),
    ));
    await tester.pumpAndSettle();
    
    // Vérifier qu'on voit au moins un texte "Accueil" (AppBar ou NavigationBar)
    expect(find.text('Accueil'), findsAtLeastNWidgets(1));
  });
}

class FakeAuthNotifier extends Auth {
  final AuthState fixedState;
  FakeAuthNotifier(this.fixedState);

  @override
  AuthState build() => fixedState;
}

class FakeAppDataNotifier extends AppData {
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

class FakeInsForgeService extends Fake implements InsForgeService {}
