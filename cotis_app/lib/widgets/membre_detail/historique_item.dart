import 'package:kased_app/models/cotisation.dart';

/// Modèle de données pour un élément de l'historique de paiement.
///
/// Stocke les informations d'une cotisation avec son culte associé.
class HistoriqueItem {
  final DateTime? date;
  final String titre;
  final StatutCotisation statut;
  final double montant;
  final DateTime? datePaiement;

  const HistoriqueItem({
    this.date,
    required this.titre,
    required this.statut,
    required this.montant,
    this.datePaiement,
  });
}
