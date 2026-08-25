import 'package:kased_app/models/cotisation.dart';

/// Hiérarchie d'actions domain-driven pour le KasedStore.
/// Chaque action est immutable et contient toutes les données nécessaires.
/// Les handlers du store reçoivent une action et produisent un nouvel AppState.

// ── Members ──────────────────────────────────────────────────────────────────

sealed class MemberAction extends KasedAction {}

class CreateMember extends MemberAction {
  final String nom, prenom;
  final DateTime dateAdhesion;
  final DateTime? dateNaissance;
  final String? telephone, notes;

  CreateMember({
    required this.nom,
    required this.prenom,
    required this.dateAdhesion,
    this.dateNaissance,
    this.telephone,
    this.notes,
  });
}

class UpdateMember extends MemberAction {
  final String id;
  final String? nom, prenom, telephone, notes;
  final DateTime? dateAdhesion, dateNaissance;
  final bool? isActive;

  UpdateMember({
    required this.id,
    this.nom,
    this.prenom,
    this.telephone,
    this.notes,
    this.dateAdhesion,
    this.dateNaissance,
    this.isActive,
  });
}

class AddPaymentAdvance extends MemberAction {
  final String membreId;
  final double montant;
  final String? notes;

  AddPaymentAdvance({
    required this.membreId,
    required this.montant,
    this.notes,
  });
}

class DeleteMember extends MemberAction {
  final String id;

  DeleteMember(this.id);
}

class RestoreMember extends MemberAction {
  final String id;

  RestoreMember(this.id);
}

// ── Cultes ───────────────────────────────────────────────────────────────────

sealed class CulteAction extends KasedAction {}

class CreateCulte extends CulteAction {
  final DateTime date;
  final String? titre;
  final double montant;

  CreateCulte({
    required this.date,
    this.titre,
    required this.montant,
  });
}

class UpdateCulte extends CulteAction {
  final String id;
  final DateTime? dateCulte;
  final String? titre;
  final double? montantCotisation;
  final String? notes;

  UpdateCulte({
    required this.id,
    this.dateCulte,
    this.titre,
    this.montantCotisation,
    this.notes,
  });
}

class DeleteCulte extends CulteAction {
  final String id;

  DeleteCulte(this.id);
}

class RestoreCulte extends CulteAction {
  final String id;

  RestoreCulte(this.id);
}

// ── Cotisations ──────────────────────────────────────────────────────────────

sealed class CotisationAction extends KasedAction {}

class RegisterPayment extends CotisationAction {
  final String membreId, culteId;
  final double montant;

  RegisterPayment({
    required this.membreId,
    required this.culteId,
    required this.montant,
  });
}

class MarkAbsent extends CotisationAction {
  final String membreId, culteId;

  MarkAbsent({
    required this.membreId,
    required this.culteId,
  });
}

class BulkSetPaiements extends CotisationAction {
  final String culteId;
  final StatutCotisation newStatut;
  final List<String> membreIds;

  BulkSetPaiements({
    required this.culteId,
    required this.newStatut,
    required this.membreIds,
  });
}

class TogglePaiement extends CotisationAction {
  final String membreId, culteId;

  TogglePaiement({
    required this.membreId,
    required this.culteId,
  });
}

class PaySeveralCultesInAdvance extends CotisationAction {
  final String membreId;
  final List<String> culteIds;
  final double montantTotal;

  PaySeveralCultesInAdvance({
    required this.membreId,
    required this.culteIds,
    required this.montantTotal,
  });
}

// ── Sync ─────────────────────────────────────────────────────────────────────

sealed class SyncAction extends KasedAction {}

class SyncData extends SyncAction {}

class LoadDashboard extends SyncAction {}

// ── Corbeille ────────────────────────────────────────────────────────────────

sealed class CorbeilleAction extends KasedAction {}

class PermanentlyDelete extends CorbeilleAction {
  final int isarId;

  PermanentlyDelete(this.isarId);
}

class EmptyTrash extends CorbeilleAction {}

// ── Queries (read-only, no state mutation) ───────────────────────────────────

sealed class QueryAction extends KasedAction {}

class GetHistoriqueMembre extends QueryAction {
  final String membreId;

  GetHistoriqueMembre(this.membreId);
}

class GetCotisationsDuCulte extends QueryAction {
  final String culteId;

  GetCotisationsDuCulte(this.culteId);
}

/// Racine de la hiérarchie d'actions.
/// Toutes les actions doivent hériter de cette classe scellée.
sealed class KasedAction {}
