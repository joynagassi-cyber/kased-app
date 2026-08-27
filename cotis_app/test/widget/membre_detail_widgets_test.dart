import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/widgets/membre_detail/stat_card.dart';
import 'package:kased_app/widgets/membre_detail/cadence_card.dart';

void main() {
  group('StatCard Widget', () {
    testWidgets('Displays label, value and sub correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'MEMBRES',
              value: '42',
              sub: '+3 ce mois',
              icon: Icons.people,
              iconColor: Colors.blue,
              cardColor: Colors.grey[100]!,
              textColor: Colors.black,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('MEMBRES'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+3 ce mois'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('Renders in dark mode correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatCard(
              label: 'CULTES',
              value: '12',
              sub: 'Actifs',
              icon: Icons.church,
              iconColor: Colors.purple,
              cardColor: Colors.grey[800]!,
              textColor: Colors.white,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('CULTES'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });
  });

  group('CadenceCard Widget', () {
    testWidgets('Displays percentage and count correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CadenceCard(
              percentage: 75.0,
              paid: 9,
              total: 12,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('9 / 12 cultes'), findsOneWidget);
      expect(find.byType(CadenceCard), findsOneWidget);
    });

    testWidgets('Shows 0% when no cultes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CadenceCard(
              percentage: 0.0,
              paid: 0,
              total: 0,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 / 0 cultes'), findsOneWidget);
    });

    testWidgets('Shows 100% when all paid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CadenceCard(
              percentage: 100.0,
              paid: 12,
              total: 12,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('12 / 12 cultes'), findsOneWidget);
    });
  });
}
