import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/realtime/realtime_patch_engine.dart';
import 'package:kased_app/core/realtime/realtime_models.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';

/// Stub LocalCache for unit tests.
class StubLocalCache implements LocalCache {
  final List<Membre> _membres = [];
  final List<Culte> _cultes = [];
  final List<Cotisation> _cotisations = [];

  @override
  Future<List<Membre>> getAllMembres() async => _membres;

  @override
  Future<List<Culte>> getAllCultes() async => _cultes;

  @override
  Future<List<Cotisation>> getAllCotisations() async => _cotisations;

  @override
  Future<void> saveMembre(Membre m) async {
    final idx = _membres.indexWhere((e) => e.id == m.id);
    if (idx >= 0) {
      _membres[idx] = m;
    } else {
      _membres.add(m);
    }
  }

  @override
  Future<void> deleteMembreById(String id) async {
    _membres.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> saveCulte(Culte c) async {
    final idx = _cultes.indexWhere((e) => e.id == c.id);
    if (idx >= 0) {
      _cultes[idx] = c;
    } else {
      _cultes.add(c);
    }
  }

  @override
  Future<void> deleteCulteById(String id) async {
    _cultes.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> saveCotisation(Cotisation c) async {
    final idx = _cotisations.indexWhere((e) => e.id == c.id);
    if (idx >= 0) {
      _cotisations[idx] = c;
    } else {
      _cotisations.add(c);
    }
  }

  @override
  Future<void> saveAllCotisations(List<Cotisation> list) async {
    _cotisations.clear();
    _cotisations.addAll(list);
  }

  @override
  Future<void> deleteCotisationsByCulteId(String culteId) async {}

  @override
  Future<List<SyncOperation>> getPendingSyncOps() async => [];

  @override
  Future<void> saveSyncOp(SyncOperation op) async {}

  @override
  Future<void> deleteSyncOp(int isarId) async {}

  @override
  Future<CorbeilleItem?> getCorbeilleItem(int isarId) async => null;

  @override
  Future<void> saveCorbeilleItem(CorbeilleItem item) async {}

  @override
  Future<void> purgeOldCorbeilleItems(DateTime before) async {}

  @override
  Future<void> deleteCorbeilleItem(int isarId) async {}

  @override
  Future<void> deleteAllCorbeilleItems() async {}

  @override
  Future<void> restoreMembreAndDeleteCorbeilleItem(
      Membre membre, int corbeilleIsarId) async {}

  @override
  Future<void> restoreCulteAndDeleteCorbeilleItem(
      Culte culte, int corbeilleIsarId) async {}

  @override
  Future<void> deleteMembreAndSaveCorbeilleItem(
      String id, CorbeilleItem item) async {}

  @override
  Future<void> deleteCulteAndCotisationsAndSaveCorbeilleItem(
      String culteId, CorbeilleItem item) async {}

  @override
  Future<void> saveCulteWithCotisations(
      Culte culte, List<Cotisation> cotisations) async {}

  @override
  Future<void> updateCulteAndCotisations(
      Culte culte, List<Cotisation>? cotisationsToUpdate) async {}

  @override
  Future<void> replaceAll({
    required List<Membre> membres,
    required List<Culte> cultes,
    required List<Cotisation> cotisations,
  }) async {
    _membres.clear();
    _membres.addAll(membres);
    _cultes.clear();
    _cultes.addAll(cultes);
    _cotisations.clear();
    _cotisations.addAll(cotisations);
  }

  @override
  Future<void> mergeFromCloud({
    required List<Membre> cloudMembres,
    required List<Culte> cloudCultes,
    required List<Cotisation> cloudCotisations,
    required Set<String> pendingMembreIds,
    required Set<String> pendingCulteIds,
    required Set<String> pendingCotisationIds,
  }) async {
    await replaceAll(
      membres: cloudMembres,
      cultes: cloudCultes,
      cotisations: cloudCotisations,
    );
  }

  @override
  Future<void> saveMembreWithSyncOp(Membre membre, SyncOperation op) async {
    await saveMembre(membre);
  }

  @override
  Future<void> saveCulteWithSyncOp(Culte culte, SyncOperation op) async {
    await saveCulte(culte);
  }

  @override
  Future<void> saveCotisationWithSyncOp(Cotisation cotisation, SyncOperation op) async {
    await saveCotisation(cotisation);
  }

  @override
  Future<void> softDeleteMembreWithSyncOp(Membre membre, SyncOperation op) async {
    membre.isDeleted = true;
    await saveMembre(membre);
  }

  @override
  Future<void> softDeleteCulteWithSyncOp(
      Culte culte, List<Cotisation> cotisations, SyncOperation op) async {
    culte.isDeleted = true;
    await saveCulte(culte);
  }

  @override
  Future<void> restoreMembreWithSyncOp(Membre membre, SyncOperation op) async {
    membre.isDeleted = false;
    await saveMembre(membre);
  }

  @override
  Future<void> restoreCulteWithSyncOp(Culte culte, SyncOperation op) async {
    culte.isDeleted = false;
    await saveCulte(culte);
  }
}

void main() {
  group('RealtimePatchEngine', () {
    test('apply create membre adds to cache', () async {
      final cache = StubLocalCache();
      bool applied = false;
      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () => applied = true,
      );

      final event = RealtimeEvent(
        action: 'create',
        table: 'membres',
        id: 'test-001',
        data: {
          'id': 'test-001',
          'nom': 'Dupont',
          'prenom': 'Jean',
          'dateAdhesion': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );

      await engine.apply(event);

      expect(applied, true);
      final membres = await cache.getAllMembres();
      expect(membres.length, 1);
      expect(membres.first.nom, 'Dupont');
      expect(membres.first.prenom, 'Jean');
    });

    test('apply update membre modifies existing', () async {
      final cache = StubLocalCache();
      await cache.saveMembre(
        Membre()
          ..id = 'test-001'
          ..nom = 'Dupont'
          ..prenom = 'Jean',
      );

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'update',
        table: 'membres',
        id: 'test-001',
        data: {
          'id': 'test-001',
          'nom': 'Dupont',
          'prenom': 'Jacques',
          'dateAdhesion': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );

      await engine.apply(event);

      final membres = await cache.getAllMembres();
      expect(membres.length, 1);
      expect(membres.first.prenom, 'Jacques');
    });

    test('apply delete membre removes from cache', () async {
      final cache = StubLocalCache();
      await cache.saveMembre(
        Membre()..id = 'test-001'..nom = 'Dupont'..prenom = 'Jean',
      );

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'delete',
        table: 'membres',
        id: 'test-001',
      );

      await engine.apply(event);

      final membres = await cache.getAllMembres();
      expect(membres.isEmpty, true);
    });

    test('apply create culte adds to cache', () async {
      final cache = StubLocalCache();
      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'create',
        table: 'cultes',
        id: 'culte-001',
        data: {
          'id': 'culte-001',
          'dateCulte': DateTime.now().toIso8601String(),
          'titre': 'Culte du dimanche',
          'montantCotisation': 50.0,
        },
      );

      await engine.apply(event);

      final cultes = await cache.getAllCultes();
      expect(cultes.length, 1);
      expect(cultes.first.titre, 'Culte du dimanche');
    });

    test('apply update culte modifies existing', () async {
      final cache = StubLocalCache();
      await cache.saveCulte(
        Culte()..id = 'culte-001'..titre = 'Ancien titre',
      );

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'update',
        table: 'cultes',
        id: 'culte-001',
        data: {
          'id': 'culte-001',
          'dateCulte': DateTime.now().toIso8601String(),
          'titre': 'Nouveau titre',
          'montantCotisation': 100.0,
        },
      );

      await engine.apply(event);

      final cultes = await cache.getAllCultes();
      expect(cultes.first.titre, 'Nouveau titre');
      expect(cultes.first.montantCotisation, 100.0);
    });

    test('apply delete culte removes from cache', () async {
      final cache = StubLocalCache();
      await cache.saveCulte(Culte()..id = 'culte-001');

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'delete',
        table: 'cultes',
        id: 'culte-001',
      );

      await engine.apply(event);

      final cultes = await cache.getAllCultes();
      expect(cultes.isEmpty, true);
    });

    test('apply create cotisation adds to cache', () async {
      final cache = StubLocalCache();
      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'create',
        table: 'cotisations',
        id: 'cot-001',
        data: {
          'id': 'cot-001',
          'membreId': 'membre-001',
          'culteId': 'culte-001',
          'montantObligatoire': 50.0,
          'montantPaye': 50.0,
          'statut': 'paye',
        },
      );

      await engine.apply(event);

      final cotisations = await cache.getAllCotisations();
      expect(cotisations.length, 1);
      expect(cotisations.first.membreId, 'membre-001');
    });

    test('apply update cotisation modifies existing', () async {
      final cache = StubLocalCache();
      await cache.saveCotisation(
        Cotisation()..id = 'cot-001'..statut = StatutCotisation.nonPaye,
      );

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'update',
        table: 'cotisations',
        id: 'cot-001',
        data: {
          'id': 'cot-001',
          'membreId': 'membre-001',
          'culteId': 'culte-001',
          'montantObligatoire': 50.0,
          'montantPaye': 50.0,
          'statut': 'paye',
        },
      );

      await engine.apply(event);

      final cotisations = await cache.getAllCotisations();
      expect(cotisations.first.statut, StatutCotisation.paye);
    });

    test('apply delete cotisation is ignored (no delete)', () async {
      final cache = StubLocalCache();
      await cache.saveCotisation(
        Cotisation()..id = 'cot-001',
      );

      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'delete',
        table: 'cotisations',
        id: 'cot-001',
      );

      await engine.apply(event);

      final cotisations = await cache.getAllCotisations();
      expect(cotisations.length, 1); // Should remain
    });

    test('apply unknown table does not crash', () async {
      final cache = StubLocalCache();
      final engine = RealtimePatchEngine(
        cache: cache,
        onPatchApplied: () {},
      );

      final event = RealtimeEvent(
        action: 'create',
        table: 'unknown',
        id: 'test-001',
      );

      // Should not throw
      await engine.apply(event);
    });
  });
}
