import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';

/// Abstraction over the local Isar database.
/// All Isar-specific code lives in [IsarLocalCache].
/// Tests use [FakeLocalCache] (or any other implementation).
abstract class LocalCache {
  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<List<Membre>> getAllMembres();
  Future<List<Culte>> getAllCultes(); // sorted by dateCulte desc
  Future<List<Cotisation>> getAllCotisations();
  Future<List<SyncOperation>> getPendingSyncOps(); // sorted by createdAt asc

  // ── Individual writes ──────────────────────────────────────────────────────

  Future<void> saveMembre(Membre m);
  Future<void> saveAllMembres(List<Membre> list);
  Future<void> clearMembres();
  Future<void> deleteMembreById(String id);

  Future<void> saveCulte(Culte c);
  Future<void> saveAllCultes(List<Culte> list);
  Future<void> clearCultes();
  Future<void> deleteCulteById(String id);

  Future<void> saveCotisation(Cotisation c);
  Future<void> saveAllCotisations(List<Cotisation> list);
  Future<void> clearCotisations();
  Future<void> deleteCotisationsByCulteId(String culteId);

  Future<void> saveSyncOp(SyncOperation op);
  Future<void> deleteSyncOp(int isarId);

  Future<CorbeilleItem?> getCorbeilleItem(int isarId);
  Future<void> saveCorbeilleItem(CorbeilleItem item);
  Future<void> purgeOldCorbeilleItems(DateTime before);

  // ── Compound / transactional writes ───────────────────────────────────────

  /// Restore a membre from the trash bin in one transaction.
  Future<void> restoreMembreAndDeleteCorbeilleItem(Membre membre, int corbeilleIsarId);

  /// Restore a culte from the trash bin in one transaction.
  Future<void> restoreCulteAndDeleteCorbeilleItem(Culte culte, int corbeilleIsarId);

  /// Delete a membre + put its CorbeilleItem in a single transaction.
  Future<void> deleteMembreAndSaveCorbeilleItem(String id, CorbeilleItem item);

  /// Delete a culte + all its cotisations + put its CorbeilleItem.
  Future<void> deleteCulteAndCotisationsAndSaveCorbeilleItem(
    String culteId,
    CorbeilleItem item,
  );

  /// Put a new culte + all generated cotisations atomically.
  Future<void> saveCulteWithCotisations(
    Culte culte,
    List<Cotisation> cotisations,
  );

  /// Update culte + optionally update cotisations in one transaction.
  Future<void> updateCulteAndCotisations(
    Culte culte,
    List<Cotisation>? cotisationsToUpdate,
  );

  /// Replace entire local cache (used after a full cloud sync).
  Future<void> replaceAll({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
  });
}
