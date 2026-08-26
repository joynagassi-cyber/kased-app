class _HistoriqueItem {
  final DateTime? date;
  final String titre;
  final StatutCotisation statut;
  final double montant;
  final DateTime? datePaiement;

  const _HistoriqueItem({
    this.date,
    required this.titre,
    required this.statut,
    required this.montant,
    this.datePaiement,
  });
}

// ── Stat Card (theme-aware, uses ColorScheme) ────────────────────────────────

