/// Port (interface) pour InsForgeService.
///
/// Sépare la logique métier de l'implémentation HTTP concrète,
/// permettant les tests unitaires sans réseau.
abstract class InsForgeServicePort {
  // ── Membres (CRUD) ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembres({int page = 1, int pageSize = 100});
  Future<List<Map<String, dynamic>>> getAllMembres();
  Future<Map<String, dynamic>> createMembre(Map<String, dynamic> data);
  Future<void> updateMembre(String id, Map<String, dynamic> data);
  Future<void> deleteMembre(String id);

  // ── Cultes (CRUD) ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCultes({int page = 1, int pageSize = 50});
  Future<Map<String, dynamic>> createCulte(Map<String, dynamic> data);
  Future<String> creerCulteAvecCotisations({
    required DateTime dateCulte,
    String? titre,
    double montantCotisation = 50.0,
  });
  Future<void> updateCulte(String id, Map<String, dynamic> data);
  Future<void> deleteCulte(String id);

  // ── Cotisations (CRUD + opérations) ─────────────────────────────────────────

  Future<void> createCotisations(List<Map<String, dynamic>> data);
  Future<void> updateCotisation(String id, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getCotisations();
  Future<List<Map<String, dynamic>>> getCotisationsDuCulte(String culteId);
  Future<List<Map<String, dynamic>>> getCotisationsDuMembre(String membreId);
  Future<Map<String, dynamic>> togglePaiement({
    required String membreId,
    required String culteId,
  });
  Future<void> consommerAvancePourCulte({
    required String membreId,
    required String culteId,
  });
  Future<void> consommerAvanceSimple({
    required String membreId,
    required double montant,
  });
  Future<void> consignerPaiementEnAvance({
    required String membreId,
    required List<String> culteIds,
    required double montantTotal,
  });
  Future<Map<String, dynamic>> marquerAbsent({
    required String membreId,
    required String culteId,
  });
  Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId);
  Future<void> deleteCotisation(String id);
  Future<void> setCotisationStatut({
    required String membreId,
    required String culteId,
    required String statut,
  });
  Future<void> deleteCotisationsDuCulte(String culteId);

  // ── Vues (calculées) ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard();
  Future<List<Map<String, dynamic>>> getResumeCultes();
  Future<List<Map<String, dynamic>>> getRetardsMembres();
  Future<List<Map<String, dynamic>>> getMembresAJour();
  Future<List<Map<String, dynamic>>> getMembresEnAvance();

  // ── Upload ──────────────────────────────────────────────────────────────────

  Future<String?> uploadMembrePhoto(String filePath, String fileName);
}
