# ADR-0002 : Actions domain-driven

**Statut :** Proposed
**Date :** 2026-08-25
**Concernés :** KasedStore, handlers

## Contexte

Les 12 méthodes publiques du provider sont hétérogènes : certaines gèrent un seul membre, d'autres un culte entier, d'autres le sync global. Sans organisation, le dispatch serait un switch gigantesque.

## Décision

Organiser les actions en 5 hiérarchies sealed par domain :

```dart
// Members
sealed class MemberAction {}
final class CreateMember implements MemberAction {
  final String nom, prenom;
  final DateTime dateAdhesion;
  final DateTime? dateNaissance;
  final String? telephone, notes;
}
final class UpdateMember implements MemberAction {
  final String id;
  final String? nom, prenom, telephone, notes;
  final DateTime? dateAdhesion, dateNaissance;
  final bool? isActive;
}
final class AddPaymentAdvance implements MemberAction {
  final String membreId;
  final double montant;
  final String? notes;
}
final class DeleteMember implements MemberAction {
  final String id;
}
final class RestoreMember implements MemberAction {
  final String id;
}

// Cultes
sealed class CulteAction {}
final class CreateCulte implements CulteAction {
  final DateTime date;
  final String? titre;
  final double montant;
}
final class UpdateCulte implements CulteAction {
  final String id;
  final DateTime? dateCulte;
  final String? titre;
  final double? montantCotisation;
  final String? notes;
}
final class DeleteCulte implements CulteAction {
  final String id;
}
final class RestoreCulte implements CulteAction {
  final String id;
}

// Cotisations
sealed class CotisationAction {}
final class RegisterPayment implements CotisationAction {
  final String membreId, culteId;
  final double montant;
}
final class MarkAbsent implements CotisationAction {
  final String membreId, culteId;
}
final class BulkSetPaiements implements CotisationAction {
  final String culteId;
  final StatutCotisation newStatut;
  final List<String> membreIds;
}
final class TogglePaiement implements CotisationAction {
  final String membreId, culteId;
}
final class PaySeveralCultesInAdvance implements CotisationAction {
  final String membreId;
  final List<String> culteIds;
  final double montantTotal;
}

// Sync
sealed class SyncAction {}
final class SyncData implements SyncAction {}
final class LoadDashboard implements SyncAction {}

// Corbeille
sealed class CorbeilleAction {}
final class PermanentlyDelete implements CorbeilleAction {
  final int isarId;
}
final class EmptyTrash implements CorbeilleAction {}
```

## Conséquences

- Chaque handler gère son domain (locabilité)
- Testing par domain : tests unitaires indépendants
- Interface小而明确 pour chaque seam
- Facile d'ajouter un nouveau domain sans toucher aux autres
