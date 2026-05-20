# 💻 EXEMPLES DE CODE - Migration Cotisations

## 1. Utilisation du service InsForge

### Créer un culte avec cotisations automatiques
```dart
// Avant
final culte = await insForgeService.createCulte({
  'date': DateTime.now().toIso8601String().substring(0, 10),
  'montant_cotisation': 50.0,
});

// Après
final culteId = await insForgeService.creerCulteAvecCotisations(
  dateCulte: DateTime.now(),
  titre: 'Culte du dimanche',
  montantCotisation: 50.0,
);
// Les cotisations sont créées automatiquement pour tous les membres actifs
```

### Toggle paiement (marquer/démarquer comme payé)
```dart
// Avant
final paiementExiste = await checkIfPaiementExists(membreId, culteId);
if (paiementExiste) {
  await insForgeService.deletePaiement(paiementId);
} else {
  await insForgeService.createPaiement({
    'membre_id': membreId,
    'culte_id': culteId,
    'date_paiement': DateTime.now().toIso8601String(),
    'montant': 50.0,
  });
}

// Après
final cotisation = await insForgeService.togglePaiement(
  membreId: membreId,
  culteId: culteId,
);
// Le statut change automatiquement : non_paye ↔ paye (ou en_avance si futur)
```

### Marquer un membre comme absent
```dart
final cotisation = await insForgeService.marquerAbsent(
  membreId: membreId,
  culteId: culteId,
);
// Le statut devient 'absent' et date_paiement = null
```

### Récupérer le dashboard
```dart
final dashboard = await insForgeService.getDashboard();
print('Membres actifs: ${dashboard['total_membres_actifs']}');
print('Total cultes: ${dashboard['total_cultes']}');
print('Membres en retard: ${dashboard['membres_en_retard']}');
print('Total dû: ${dashboard['total_du_fcfa']} FCFA');
```

### Récupérer les retards
```dart
final retards = await insForgeService.getRetardsMembres();
for (final retard in retards) {
  print('${retard['nom']} ${retard['prenom']}: ${retard['montant_du_fcfa']} FCFA');
  print('  Cultes en retard: ${retard['cultes_en_retard']}');
}
```

### Historique d'un membre
```dart
final historique = await insForgeService.getHistoriqueMembre(membreId);
for (final ligne in historique) {
  print('${ligne['culte_date']}: ${ligne['statut']} - ${ligne['montant']} FCFA');
}
```

---

## 2. Widget pour afficher une cotisation

```dart
class CotisationTile extends StatelessWidget {
  final Cotisation cotisation;
  final Membre membre;
  final VoidCallback onTap;
  final VoidCallback? onMarkAbsent;

  const CotisationTile({
    required this.cotisation,
    required this.membre,
    required this.onTap,
    this.onMarkAbsent,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatutColor(cotisation.statut),
        child: Icon(
          _getStatutIcon(cotisation.statut),
          color: Colors.white,
        ),
      ),
      title: Text(membre.nomComplet),
      subtitle: Text(_getStatutLabel(cotisation.statut)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${cotisation.montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getStatutColor(cotisation.statut),
            ),
          ),
          if (onMarkAbsent != null)
            IconButton(
              icon: Icon(Icons.person_off),
              onPressed: onMarkAbsent,
              tooltip: 'Marquer absent',
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Color _getStatutColor(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye:
        return Colors.green;
      case StatutCotisation.nonPaye:
        return Colors.orange;
      case StatutCotisation.absent:
        return Colors.grey;
      case StatutCotisation.enAvance:
        return Colors.blue;
    }
  }

  IconData _getStatutIcon(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye:
        return Icons.check_circle;
      case StatutCotisation.nonPaye:
        return Icons.pending;
      case StatutCotisation.absent:
        return Icons.cancel;
      case StatutCotisation.enAvance:
        return Icons.flash_on;
    }
  }

  String _getStatutLabel(StatutCotisation statut) {
    switch (statut) {
      case StatutCotisation.paye:
        return 'Payé';
      case StatutCotisation.nonPaye:
        return 'Non payé';
      case StatutCotisation.absent:
        return 'Absent';
      case StatutCotisation.enAvance:
        return 'En avance';
    }
  }
}
```

---

## 3. Provider - Exemple de mise à jour

```dart
class AppDataProvider extends ChangeNotifier {
  final InsForgeService _service = InsForgeService();
  
  List<Membre> _membres = [];
  List<Culte> _cultes = [];
  List<Cotisation> _cotisations = [];
  Map<String, dynamic>? _dashboard;
  
  // Getters
  List<Membre> get membres => _membres;
  List<Culte> get cultes => _cultes;
  List<Cotisation> get cotisations => _cotisations;
  Map<String, dynamic>? get dashboard => _dashboard;
  
  // Charger le dashboard
  Future<void> loadDashboard() async {
    try {
      _dashboard = await _service.getDashboard();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement dashboard: $e');
    }
  }
  
  // Créer un culte avec cotisations auto
  Future<void> createCulteAvecCotisations({
    required DateTime date,
    String? titre,
    double montant = 50.0,
  }) async {
    try {
      final culteId = await _service.creerCulteAvecCotisations(
        dateCulte: date,
        titre: titre,
        montantCotisation: montant,
      );
      
      // Recharger les données
      await loadCultes();
      await loadCotisations();
      await loadDashboard();
    } catch (e) {
      print('Erreur création culte: $e');
      rethrow;
    }
  }
  
  // Toggle paiement
  Future<void> togglePaiement(String membreId, String culteId) async {
    try {
      await _service.togglePaiement(
        membreId: membreId,
        culteId: culteId,
      );
      
      // Recharger les cotisations
      await loadCotisations();
      await loadDashboard();
    } catch (e) {
      print('Erreur toggle paiement: $e');
      rethrow;
    }
  }
  
  // Marquer absent
  Future<void> marquerAbsent(String membreId, String culteId) async {
    try {
      await _service.marquerAbsent(
        membreId: membreId,
        culteId: culteId,
      );
      
      // Recharger les cotisations
      await loadCotisations();
      await loadDashboard();
    } catch (e) {
      print('Erreur marquer absent: $e');
      rethrow;
    }
  }
  
  // Charger les cotisations d'un culte
  Future<List<Cotisation>> getCotisationsDuCulte(String culteId) async {
    try {
      final data = await _service.getCotisationsDuCulte(culteId);
      return data.map((json) => Cotisation.fromJson(json)).toList();
    } catch (e) {
      print('Erreur chargement cotisations: $e');
      return [];
    }
  }
  
  // Charger les retards
  Future<List<Map<String, dynamic>>> getRetards() async {
    try {
      return await _service.getRetardsMembres();
    } catch (e) {
      print('Erreur chargement retards: $e');
      return [];
    }
  }
  
  // Historique d'un membre
  Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId) async {
    try {
      return await _service.getHistoriqueMembre(membreId);
    } catch (e) {
      print('Erreur chargement historique: $e');
      return [];
    }
  }
  
  // Charger tous les membres
  Future<void> loadMembres() async {
    try {
      final data = await _service.getMembres();
      _membres = data.map((json) => Membre.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement membres: $e');
    }
  }
  
  // Charger tous les cultes
  Future<void> loadCultes() async {
    try {
      final data = await _service.getCultes();
      _cultes = data.map((json) => Culte.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement cultes: $e');
    }
  }
  
  // Charger toutes les cotisations
  Future<void> loadCotisations() async {
    try {
      final data = await _service.getCotisations();
      _cotisations = data.map((json) => Cotisation.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement cotisations: $e');
    }
  }
  
  // Créer un membre (les cotisations seront générées automatiquement)
  Future<void> createMembre(Membre membre) async {
    try {
      await _service.createMembre(membre.toJson());
      await loadMembres();
      await loadCotisations(); // Recharger car trigger a créé des cotisations
      await loadDashboard();
    } catch (e) {
      print('Erreur création membre: $e');
      rethrow;
    }
  }
}
```

---

## 4. Écran Dashboard - Exemple

```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final InsForgeService _service = InsForgeService();
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getDashboard();
      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_dashboard == null) {
      return Center(child: Text('Erreur de chargement'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          StatCard(
            title: 'Membres actifs',
            value: '${_dashboard!['total_membres_actifs'] ?? 0}',
            icon: Icons.people,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          StatCard(
            title: 'Total cultes',
            value: '${_dashboard!['total_cultes'] ?? 0}',
            icon: Icons.event,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          StatCard(
            title: 'Membres en retard',
            value: '${_dashboard!['membres_en_retard'] ?? 0}',
            icon: Icons.warning,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          StatCard(
            title: 'Total dû',
            value: '${_dashboard!['total_du_fcfa'] ?? 0} FCFA',
            icon: Icons.attach_money,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Écran Détail Culte - Exemple

```dart
class CulteDetailScreen extends StatefulWidget {
  final Culte culte;

  const CulteDetailScreen({required this.culte});

  @override
  _CulteDetailScreenState createState() => _CulteDetailScreenState();
}

class _CulteDetailScreenState extends State<CulteDetailScreen> {
  final InsForgeService _service = InsForgeService();
  List<Cotisation> _cotisations = [];
  Map<String, Membre> _membresMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Charger les cotisations du culte
      final cotisData = await _service.getCotisationsDuCulte(widget.culte.id);
      final cotisations = cotisData.map((json) => Cotisation.fromJson(json)).toList();
      
      // Charger les membres
      final membresData = await _service.getMembres();
      final membres = membresData.map((json) => Membre.fromJson(json)).toList();
      final membresMap = {for (var m in membres) m.id: m};
      
      setState(() {
        _cotisations = cotisations;
        _membresMap = membresMap;
        _loading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePaiement(Cotisation cotisation) async {
    try {
      await _service.togglePaiement(
        membreId: cotisation.membreId,
        culteId: cotisation.culteId,
      );
      await _loadData(); // Recharger
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _marquerAbsent(Cotisation cotisation) async {
    try {
      await _service.marquerAbsent(
        membreId: cotisation.membreId,
        culteId: cotisation.culteId,
      );
      await _loadData(); // Recharger
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.culte.dateFormatee)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalPaye = _cotisations.where((c) => c.estPaye).length;
    final totalNonPaye = _cotisations.where((c) => c.estEnRetard).length;
    final montantCollecte = _cotisations
        .where((c) => c.estPaye)
        .fold(0.0, (sum, c) => sum + c.montant);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.culte.dateFormatee),
      ),
      body: Column(
        children: [
          // Résumé
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Payés', '$totalPaye', Colors.green),
                _buildStat('Non payés', '$totalNonPaye', Colors.orange),
                _buildStat('Collecté', '${montantCollecte.toStringAsFixed(0)} F', Colors.blue),
              ],
            ),
          ),
          // Liste des cotisations
          Expanded(
            child: ListView.builder(
              itemCount: _cotisations.length,
              itemBuilder: (context, index) {
                final cotisation = _cotisations[index];
                final membre = _membresMap[cotisation.membreId];
                
                if (membre == null) return SizedBox.shrink();
                
                return CotisationTile(
                  cotisation: cotisation,
                  membre: membre,
                  onTap: () => _togglePaiement(cotisation),
                  onMarkAbsent: () => _marquerAbsent(cotisation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
```

---

*Exemples de code pour la migration kased-app*
*Stack : Flutter + InsForge (PostgreSQL)*
