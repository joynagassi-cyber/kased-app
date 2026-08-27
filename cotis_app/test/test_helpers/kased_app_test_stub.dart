import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/kased_app_provider.dart';

/// Stub de test pour [KasedApp] utilisé dans les tests E2E et widget.
///
/// Fournit un AppState pré-construit sans initialisation complexe
/// (Isar, InsForge, sync, etc.). Toutes les méthodes déléguées au store
/// sont remplacées par des implémentations muettes ou retournant des valeurs
/// par défaut.
///
/// Exemple d'utilisation :
/// ```dart
/// ProviderScope(
///   overrides: [
///     kasedAppProvider.overrideWith((ref) => TestKasedApp(mockState)),
///   ],
///   child: const MyApp(),
/// )
/// ```
class TestKasedApp extends KasedApp {
  final AppState appState;
  final DashboardStats dashboardStats;

  TestKasedApp(
    this.appState, {
    DashboardStats? stats,
  }) : dashboardStats = stats ?? DashboardStats(
          totalMembres: appState.membres.length,
          totalCultes: appState.cultes.length,
          totalCollecte: 0.0,
          membresEnRetard: 0,
          totalDu: 0.0,
        );

  @override
  Future<AppState> build() async {
    return appState;
  }

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> syncData() async {}

  @override
  DashboardStats getDashboardStats() => dashboardStats;

  @override
  Future<List<Map<String, dynamic>>> loadRetardsMembres() async {
    return appState.retardsMembres;
  }

  @override
  Future<List<Map<String, dynamic>>> loadMembresAJour() async {
    return appState.membresAJour;
  }

  @override
  List<Map<String, dynamic>> getRetardsMembresLocally() {
    return appState.retardsMembres;
  }

  @override
  Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId) async {
    if (appState.historiqueMembreId == membreId) {
      return appState.historiqueMembre;
    }
    return [];
  }

  @override
  Future<List<Cotisation>> getCotisationsDuCulte(String culteId) async {
    return appState.cotisations
        .where((c) => c.culteId == culteId)
        .toList();
  }

  @override
  Future<void> restaurerElement(int isarId) async {}

  @override
  Future<void> supprimerDefinitivement(int isarId) async {}

  @override
  Future<void> viderCorbeille() async {}

  @override
  Future<Membre> addMembre({
    required String nom,
    required String prenom,
    required DateTime dateAdhesion,
    DateTime? dateNaissance,
    String? telephone,
    String? notes,
  }) async {
    return Membre()
      ..id = 'test-id'
      ..nom = nom
      ..prenom = prenom
      ..dateAdhesion = dateAdhesion;
  }

  @override
  Future<void> updateMembre({
    required String id,
    String? nom,
    String? prenom,
    DateTime? dateAdhesion,
    DateTime? dateNaissance,
    String? telephone,
    String? notes,
    bool? isActive,
  }) async {}

  @override
  Future<void> ajouterPaiementAvance({
    required String membreId,
    required double montant,
    String? notes,
  }) async {}

  @override
  Future<void> deleteMembre(String id) async {}

  @override
  Future<void> addCulte({
    required DateTime date,
    String? titre,
    required double montant,
  }) async {}

  @override
  Future<void> updateCulte({
    required String id,
    DateTime? dateCulte,
    String? titre,
    double? montantCotisation,
    String? notes,
  }) async {}

  @override
  Future<void> deleteCulte(String id) async {}

  @override
  Future<void> enregistrerPaiementPersonnel({
    required String membreId,
    required String culteId,
    required double montant,
  }) async {}

  @override
  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {}

  @override
  Future<({int success, int total})> bulkSetPaiements({
    required String culteId,
    required StatutCotisation newStatut,
    required List<String> membreIds,
  }) async {
    return (success: membreIds.length, total: membreIds.length);
  }

  @override
  Future<void> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {}

  @override
  Future<void> payerPlusieursCultesEnAvance({
    required String membreId,
    required List<String> culteIds,
    required double montantTotal,
  }) async {}

  @override
  Future<double> getObjectifMensuel() => StatsService.loadObjectifMensuel();

  @override
  Future<DashboardStats> updateObjectifMensuel(double montant) async {
    await StatsService.saveObjectifMensuel(montant);
    return dashboardStats;
  }
}
