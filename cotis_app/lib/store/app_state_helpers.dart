import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/store/app_state.dart';

/// Fonctions pures pour les transformations d'AppState.
/// Chaque fonction prend un AppState et retourne un nouvel AppState modifié.
/// Ces fonctions sont testables isolément, sans Flutter ni Isar.

// ── Membres ──────────────────────────────────────────────────────────────────

/// Trie les membres par nom puis prénom, en éliminant les doublons par id.
List<Membre> sortMembres(List<Membre> membres) {
  // Deduplicate by id (keep first occurrence)
  final seenIds = <String>{};
  final deduped = <Membre>[];
  for (final m in membres) {
    if (seenIds.add(m.id)) {
      deduped.add(m);
    }
  }
  deduped.sort((a, b) => a.nom.compareTo(b.nom) != 0
      ? a.nom.compareTo(b.nom)
      : a.prenom.compareTo(b.prenom));
  return deduped;
}

/// Supprime un membre de la liste.
List<Membre> removeMembre(List<Membre> membres, String membreId) {
  return membres.where((m) => m.id != membreId).toList();
}

/// Ajoute un membre et trie. Le membre est remplacé s'il existe déjà (par id).
List<Membre> addMembreSorted(List<Membre> membres, Membre membre) {
  return updateMembreInList(membres, membre.id, membre);
}

/// Met à jour un membre existant.
List<Membre> updateMembreInList(
  List<Membre> membres,
  String id,
  Membre updated,
) {
  return sortMembres([
    ...membres.where((m) => m.id != id),
    updated,
  ]);
}

// ── Cultes ───────────────────────────────────────────────────────────────────

/// Trie les cultes par date décroissante.
List<Culte> sortCultesDesc(List<Culte> cultes) {
  final sorted = List<Culte>.from(cultes);
  sorted.sort((a, b) => b.dateCulte.compareTo(a.dateCulte));
  return sorted;
}

/// Ajoute un culte et trie.
List<Culte> addCulteSorted(List<Culte> cultes, Culte culte) {
  return sortCultesDesc([culte, ...cultes]);
}

/// Met à jour un culte existant.
List<Culte> updateCulteInList(
  List<Culte> cultes,
  String id,
  Culte updated,
) {
  return sortCultesDesc([
    ...cultes.where((c) => c.id != id),
    updated,
  ]);
}

/// Supprime un culte de la liste.
List<Culte> removeCulte(List<Culte> cultes, String culteId) {
  return cultes.where((c) => c.id != culteId).toList();
}

// ── Cotisations ──────────────────────────────────────────────────────────────

/// Remplace une cotisation existante ou l'ajoute.
List<Cotisation> upsertCotisation(
  List<Cotisation> cotisations,
  Cotisation cotisation,
) {
  final index =
      cotisations.indexWhere((c) => c.id == cotisation.id);
  if (index != -1) {
    final updated = List<Cotisation>.from(cotisations);
    updated[index] = cotisation;
    return updated;
  }
  return [...cotisations, cotisation];
}

/// Met à jour toutes les cotisations d'un culte donné.
List<Cotisation> updateCotisationsByCulte(
  List<Cotisation> cotisations,
  String culteId,
  Cotisation Function(Cotisation) transform,
) {
  return cotisations
      .map((c) => c.culteId == culteId ? transform(c) : c)
      .toList();
}

// ── AppState transformations ─────────────────────────────────────────────────

/// Helper : créer un nouvel AppState avec membres triés.
AppState withSortedMembres(AppState state, List<Membre> membres) {
  return state.copyWith(membres: sortMembres(membres));
}

/// Helper : créer un nouvel AppState avec cultes triés desc.
AppState withSortedCultesDesc(AppState state, List<Culte> cultes) {
  return state.copyWith(cultes: sortCultesDesc(cultes));
}

/// Helper : mettre à jour les cotisations.
AppState withCotisations(AppState state, List<Cotisation> cotisations) {
  return state.copyWith(cotisations: cotisations);
}

/// Helper : mise à jour complète (membres, cultes, cotisations).
AppState withFullData(
  AppState state, {
  required List<Membre> membres,
  required List<Culte> cultes,
  required List<Cotisation> cotisations,
}) {
  return state.copyWith(
    membres: sortMembres(membres),
    cultes: sortCultesDesc(cultes),
    cotisations: cotisations,
  );
}

/// Helper : mise à jour partielle avec tri.
AppState withPartialUpdate(
  AppState state, {
  List<Membre>? membres,
  List<Culte>? cultes,
  List<Cotisation>? cotisations,
}) {
  return state.copyWith(
    membres: membres != null ? sortMembres(membres) : null,
    cultes: cultes != null ? sortCultesDesc(cultes) : null,
    cotisations: cotisations,
  );
}

// ── Filters ──────────────────────────────────────────────────────────────────

/// Filtre les membres actifs (non supprimés).
List<Membre> filterActiveMembres(List<Membre> membres) {
  return membres
      .where((m) => m.isActive && !m.isDeleted)
      .toList();
}

/// Filtre les cultes actifs (non supprimés).
List<Culte> filterActiveCultes(List<Culte> cultes) {
  return cultes.where((c) => !c.isDeleted).toList();
}

/// Filtre les cultes futurs.
List<Culte> filterFutureCultes(List<Culte> cultes) {
  final now = DateTime.now();
  return cultes
      .where((c) => !c.isDeleted && c.dateCulte.isAfter(now))
      .toList();
}

/// Filtre les cultes passés.
List<Culte> filterPastCultes(List<Culte> cultes) {
  final now = DateTime.now();
  return cultes
      .where((c) => !c.isDeleted && c.dateCulte.isBefore(now))
      .toList();
}

/// Filtre les cotisations d'un membre.
List<Cotisation> filterCotisationsByMembre(
  List<Cotisation> cotisations,
  String membreId,
) {
  return cotisations.where((c) => c.membreId == membreId).toList();
}

/// Filtre les cotisations d'un culte.
List<Cotisation> filterCotisationsByCulte(
  List<Cotisation> cotisations,
  String culteId,
) {
  return cotisations.where((c) => c.culteId == culteId).toList();
}
