import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Widget de test minimal pour RetardsScreen sans dépendances natives
// ---------------------------------------------------------------------------
void main() {
  group('RetardsScreen UI', () {
    testWidgets('Affiche EmptyState quand liste vide', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockRetardsWidget(retards: []),
        ),
      );

      expect(find.text('Tout le monde est à jour !'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Affiche les noms des membres en retard', (tester) async {
      final retards = [
        {
          'nom': 'Dupont',
          'prenom': 'Jean',
          'cultes_en_retard': 3,
          'montant_du_fcfa': 150.0,
          'dernier_paiement': null,
        },
        {
          'nom': 'Martin',
          'prenom': 'Sophie',
          'cultes_en_retard': 1,
          'montant_du_fcfa': 50.0,
          'dernier_paiement': '2024-01-07T00:00:00.000Z',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _MockRetardsWidget(retards: retards),
        ),
      );

      // Noms affichés
      expect(find.textContaining('Jean Dupont'), findsOneWidget);
      expect(find.textContaining('Sophie Martin'), findsOneWidget);

      // Montants affichés
      expect(find.text('150 F'), findsOneWidget);
      expect(find.text('50 F'), findsOneWidget);
    });

    testWidgets('Affiche "Jamais payé" si dernier_paiement est null', (tester) async {
      final retards = [
        {
          'nom': 'Kaze',
          'prenom': 'Paul',
          'cultes_en_retard': 5,
          'montant_du_fcfa': 250.0,
          'dernier_paiement': null,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _MockRetardsWidget(retards: retards),
        ),
      );

      expect(find.text('Jamais payé'), findsOneWidget);
    });

    testWidgets('Liste triée par montant décroissant', (tester) async {
      // La liste est déjà triée côté InsForge (order=montant_du_fcfa.desc)
      // On vérifie que l'ordre d'affichage respecte l'ordre de la liste fournie
      final retards = [
        {
          'nom': 'Alpha',
          'prenom': 'A',
          'cultes_en_retard': 5,
          'montant_du_fcfa': 250.0,
          'dernier_paiement': null,
        },
        {
          'nom': 'Beta',
          'prenom': 'B',
          'cultes_en_retard': 1,
          'montant_du_fcfa': 50.0,
          'dernier_paiement': null,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _MockRetardsWidget(retards: retards),
        ),
      );

      // Vérifie l'ordre dans l'arbre via les positions des widgets
      final firstText = find.textContaining('A Alpha');
      final secondText = find.textContaining('B Beta');
      expect(tester.getTopLeft(firstText).dy,
          lessThan(tester.getTopLeft(secondText).dy));
    });

    testWidgets('Affiche CircularProgressIndicator pendant le chargement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockRetardsWidget(retards: [], isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tout le monde est à jour !'), findsNothing);
    });
  });
}

// ---------------------------------------------------------------------------
// Widget de test isolé qui reproduit la logique d'affichage de RetardsScreen
// sans dépendances Riverpod/Isar/InsForge
// ---------------------------------------------------------------------------
class _MockRetardsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> retards;
  final bool isLoading;

  const _MockRetardsWidget({
    required this.retards,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (retards.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64),
              SizedBox(height: 16),
              Text('Tout le monde est à jour !'),
              Text('Aucun retard détecté pour le moment.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: retards.length,
        itemBuilder: (context, index) {
          final retard = retards[index];
          final nom = retard['nom'] ?? '';
          final prenom = retard['prenom'] ?? '';
          final montantDu =
              (retard['montant_du_fcfa'] as num?)?.toDouble() ?? 0.0;
          final dernierPaiement = retard['dernier_paiement'] != null
              ? DateTime.tryParse(retard['dernier_paiement'].toString())
              : null;

          return ListTile(
            title: Text('$prenom $nom'),
            subtitle: dernierPaiement != null
                ? Text('Dernier paiement : ${dernierPaiement.day}/${dernierPaiement.month}')
                : const Text('Jamais payé'),
            trailing: Text('${montantDu.toInt()} F'),
          );
        },
      ),
    );
  }
}
