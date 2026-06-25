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

  /// Choisit la version la plus récente entre locale et cloud
  Membre _pickMembre(Membre local, Membre cloud) {
    if (local.updatedAt == null && cloud.updatedAt == null) return cloud;
    if (local.updatedAt == null) return cloud;
    if (cloud.updatedAt == null) return local;
    return local.updatedAt!.isAfter(cloud.updatedAt!) ? local : cloud;
  }

  Culte _pickCulte(Culte local, Culte cloud) {
    if (local.updatedAt == null && cloud.updatedAt == null) return cloud;
    if (local.updatedAt == null) return cloud;
    if (cloud.updatedAt == null) return local;
    return local.updatedAt!.isAfter(cloud.updatedAt!) ? local : cloud;
  }

  Cotisation _pickCotisation(Cotisation local, Cotisation cloud) {
    if (local.updatedAt == null && cloud.updatedAt == null) return cloud;
    if (local.updatedAt == null) return cloud;
    if (cloud.updatedAt == null) return local;
    return local.updatedAt!.isAfter(cloud.updatedAt!) ? local : cloud;
  }

  @override
  Future<void> mergeFromCloud({
    required List<Membre> cloudMembres,
    required List<Culte> cloudCultes,
    required List<Cotisation> cloudCotisations,
    required Set<String> pendingMembreIds,
    required Set<String> pendingCulteIds,
    required Set<String> pendingCotisationIds,
  }) =>
      _isar.writeTxn(() async {
        // ── Membres ─────────────────────────────────────────
        final localMembres = await _isar.membres.where().findAll();
        final cloudMembresById = {for (final m in cloudMembres) m.id: m};
        final localMembresById = {for (final m in localMembres) m.id: m};
        final mergedMembres = <Membre>[];

        // Fusion : cloud + local, garder le plus récent
        final allMembreIds = {...cloudMembresById.keys, ...localMembresById.keys};
        for (final id in allMembreIds) {
          // Si l'entité a une opération en attente, garder la version locale
          if (pendingMembreIds.contains(id)) {
            if (localMembresById.containsKey(id)) {
              mergedMembres.add(localMembresById[id]!);
            }
            continue;
          }
          final cloud = cloudMembresById[id];
          final local = localMembresById[id];
          
          // Si local est supprimé et ne contient aucune opération, l'éliminer
          if (local != null && local.isDeleted) {
            continue;
          }
          
          if (cloud != null && local != null) {
            mergedMembres.add(_pickMembre(local, cloud));
          } else {
            if (cloud != null) mergedMembres.add(cloud);
            else if (local != null && !local.isDeleted) mergedMembres.add(local);
          }
        }

        await _isar.membres.clear();
        await _isar.membres.putAll(mergedMembres);

        // ── Cultes ──────────────────────────────────────────
        final localCultes = await _isar.cultes.where().findAll();
        final cloudCultesById = {for (final c in cloudCultes) c.id: c};
        final localCultesById = {for (final c in localCultes) c.id: c};
        final mergedCultes = <Culte>[];

        final allCulteIds = {...cloudCultesById.keys, ...localCultesById.keys};
        for (final id in allCulteIds) {
          if (pendingCulteIds.contains(id)) {
            if (localCultesById.containsKey(id)) {
              mergedCultes.add(localCultesById[id]!);
            }
            continue;
          }
          final cloud = cloudCultesById[id];
          final local = localCultesById[id];
          
          // Si local est supprimé et ne contient aucune opération, l'éliminer
          if (local != null && local.isDeleted) {
            continue;
          }
          
          if (cloud != null && local != null) {
            mergedCultes.add(_pickCulte(local, cloud));
          } else {
            if (cloud != null) mergedCultes.add(cloud);
            else if (local != null && !local.isDeleted) mergedCultes.add(local);
          }
        }

        await _isar.cultes.clear();
        await _isar.cultes.putAll(mergedCultes);

        // ── Cotisations ─────────────────────────────────────
        final localCotisations = await _isar.cotisations.where().findAll();
        final cloudCotisationsById = {for (final c in cloudCotisations) c.id: c};
        final localCotisationsById = {for (final c in localCotisations) c.id: c};
        final mergedCotisations = <Cotisation>[];

        final allCotisationIds = {...cloudCotisationsById.keys, ...localCotisationsById.keys};
        for (final id in allCotisationIds) {
          if (pendingCotisationIds.contains(id)) {
            if (localCotisationsById.containsKey(id)) {
              mergedCotisations.add(localCotisationsById[id]!);
            }
            continue;
          }
          final cloud = cloudCotisationsById[id];
          final local = localCotisationsById[id];
          if (cloud != null && local != null) {
            mergedCotisations.add(_pickCotisation(local, cloud));
          } else {
            mergedCotisations.add(cloud ?? local!);
          }
        }

        await _isar.cotisations.clear();
        await _isar.cotisations.putAll(mergedCotisations);
      });

  // ── Mutations atomiques avec SyncOperation ────────────────────────────────

  @override
  Future<void> saveMembreWithSyncOp(Membre membre, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.membres.put(membre);
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> saveCulteWithSyncOp(Culte culte, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> saveCotisationWithSyncOp(Cotisation cotisation, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.cotisations.put(cotisation);
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> softDeleteMembreWithSyncOp(Membre membre, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.membres.put(membre);
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> softDeleteCulteWithSyncOp(Culte culte, List<Cotisation> cotisations, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        for (final c in cotisations) {
          await _isar.cotisations.put(c);
        }
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> restoreMembreWithSyncOp(Membre membre, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.membres.put(membre);
        await _isar.syncOperations.put(op);
      });

  @override
  Future<void> restoreCulteWithSyncOp(Culte culte, SyncOperation op) =>
      _isar.writeTxn(() async {
        await _isar.cultes.put(culte);
        await _isar.syncOperations.put(op);
      });
}
