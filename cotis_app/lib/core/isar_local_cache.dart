import 'package:isar/isar.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/core/local_cache.dart';

/// Isar-backed implementation of [LocalCache].
/// All generated extension methods (.filter(), .where(), etc.) live here.
class IsarLocalCache implements LocalCache {
  final Isar _isar;
  IsarLocalCache(this._isar);

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<Membre>> getAllMembres() =>
      _isar.membres.where().findAll();

  @override
  Future<List<Culte>> getAllCultes() =>
      _isar.cultes.where().sortByDateCulteDesc().findAll();

  @override
  Future<List<Cotisation>> getAllCotisations() =>
      _isar.cotisations.where().findAll();

  @override
  Future<List<SyncOperation>> getPendingSyncOps() =>
      _isar.syncOperations.where().sortByCreatedAt().findAll();

  // ── Individual writes ──────────────────────────────────────────────────────

  @override
  Future<void> saveMembre(Membre m) =>
      _isar.writeTxn(() => _isar.membres.put(m));

  @override
  Future<void> saveAllMembres(List<Membre> list) =>
      _isar.writeTxn(() => _isar.membres.putAll(list));

  @override
  Future<void> clearMembres() =>
      _isar.writeTxn(() => _isar.membres.clear());

  @override
  Future<void> deleteMembreById(String id) =>
      _isar.writeTxn(() => _isar.membres.filter().idEqualTo(id).deleteAll());

  @override
  Future<void> saveCulte(Culte c) =>
      _isar.writeTxn(() => _isar.cultes.put(c));

  @override
  Future<void> saveAllCultes(List<Culte> list) =>
      _isar.writeTxn(() => _isar.cultes.putAll(list));

  @override
  Future<void> clearCultes() =>
      _isar.writeTxn(() => _isar.cultes.clear());

  @override
  Future<void> deleteCulteById(String id) =>
      _isar.writeTxn(() => _isar.cultes.filter().idEqualTo(id).deleteAll());

  @override
  Future<void> saveCotisation(Cotisation c) =>
      _isar.writeTxn(() => _isar.cotisations.put(c));

  @override
  Future<void> saveAllCotisations(List<Cotisation> list) =>
      _isar.writeTxn(() => _isar.cotisations.putAll(list));

  @override
  Future<void> clearCotisations() =>
      _isar.writeTxn(() => _isar.cotisations.clear());

  @override
  Future<void> deleteCotisationsByCulteId(String culteId) =>
      _isar.writeTxn(
        () => _isar.cotisations.filter().culteIdEqualTo(culteId).deleteAll(),
      );

  @override
  Future<void> saveSyncOp(SyncOperation op) =>
      _isar.writeTxn(() => _isar.syncOperations.put(op));

  @override
  Future<void> deleteSyncOp(int isarId) =>
      _isar.writeTxn(() => _isar.syncOperations.delete(isarId));

  @override
  Future<CorbeilleItem?> getCorbeilleItem(int isarId) =>
      _isar.corbeilleItems.get(isarId);

  @override
  Future<void> saveCorbeilleItem(CorbeilleItem item) =>
      _isar.writeTxn(() => _isar.corbeilleItems.put(item));

  @override
  Future<void> purgeOldCorbeilleItems(DateTime before) =>
      _isar.writeTxn(
        () => _isar.corbeilleItems.filter().deletedAtLessThan(before).deleteAll(),
      );

  // ── Compound / transactional writes ───────────────────────────────────────

  @override
  Future<void> restoreMembreAndDeleteCorbeilleItem(
    Membre membre,
    int corbeilleIsarId,
  ) =>
      _isar.writeTxn(() async {
        await _isar.membres.put(membre);
        await _isar.corbeilleItems.delete(corbeilleIsarId);
      });

  @override
  Future<void> restoreCulteAndDeleteCorbeilleItem(
    Culte culte,
    int corbeilleIsarId,
  ) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        await _isar.corbeilleItems.delete(corbeilleIsarId);
      });

  @override
  Future<void> deleteMembreAndSaveCorbeilleItem(
    String id,
    CorbeilleItem item,
  ) =>
      _isar.writeTxn(() async {
        await _isar.membres.filter().idEqualTo(id).deleteAll();
        await _isar.corbeilleItems.put(item);
      });

  @override
  Future<void> deleteCulteAndCotisationsAndSaveCorbeilleItem(
    String culteId,
    CorbeilleItem item,
  ) =>
      _isar.writeTxn(() async {
        await _isar.cultes.filter().idEqualTo(culteId).deleteAll();
        await _isar.cotisations.filter().culteIdEqualTo(culteId).deleteAll();
        await _isar.corbeilleItems.put(item);
      });

  @override
  Future<void> saveCulteWithCotisations(
    Culte culte,
    List<Cotisation> cotisations,
  ) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        await _isar.cotisations.putAll(cotisations);
      });

  @override
  Future<void> updateCulteAndCotisations(
    Culte culte,
    List<Cotisation>? cotisationsToUpdate,
  ) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        if (cotisationsToUpdate != null && cotisationsToUpdate.isNotEmpty) {
          await _isar.cotisations.putAll(cotisationsToUpdate);
        }
      });

  @override
  Future<void> replaceAll({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
  }) =>
      _isar.writeTxn(() async {
        await _isar.membres.clear();
        await _isar.cultes.clear();
        await _isar.cotisations.clear();
        await _isar.membres.putAll(membres);
        await _isar.cultes.putAll(cultes);
        await _isar.cotisations.putAll(cotisations);
      });
}
