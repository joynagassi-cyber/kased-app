import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/widgets/member_pay_tile.dart';

void main() {
  final testMembre = Membre()
    ..id = 'm1'
    ..nom = 'Doe'
    ..prenom = 'John'
    ..telephone = '000000000'
    ..dateAdhesion = DateTime(2023, 1, 1)
    ..dateNaissance = DateTime(1990, 1, 1)
    ..isActive = true;

  Widget createWidgetUnderTest({
    required StatutCotisation statut,
    required bool isLocked,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MemberPayTile(
          membre: testMembre,
          statut: statut,
          isLocked: isLocked,
          onToggle: () {},
          onMarkAbsent: () {},
        ),
      ),
    );
  }

  group('MemberPayTile Lock Feature', () {
    testWidgets('Affiche les boutons d\'action quand non verrouillé', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        statut: StatutCotisation.paye,
        isLocked: false,
      ));

      expect(find.byType(IconButton), findsWidgets); // On a 2 icon buttons: Toggle et Absent
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('Affiche le Cadenas quand verrouillé et déjà payé', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        statut: StatutCotisation.paye,
        isLocked: true,
      ));

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('Affiche les boutons (pas le cadenas) quand verrouillé mais NON PAYÉ (retardataire)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        statut: StatutCotisation.nonPaye,
        isLocked: true, // Le culte est verrouillé (> 30 jours)
      ));

      // Les retardataires peuvent toujours payer même après 30 jours
      expect(find.byType(IconButton), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });
  });
}
