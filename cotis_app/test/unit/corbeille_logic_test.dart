import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/screens/corbeille/corbeille_screen.dart';

void main() {
  group('Corbeille Logic - Purge à 30 jours', () {
    test('Identifie correctement les éléments de plus de 30 jours à purger', () {
      final now = DateTime(2023, 6, 15); // Date de test fixe

      final itemRecent = CorbeilleItem()
        ..entityId = '1'
        ..deletedAt = DateTime(2023, 6, 1); // 14 jours

      final itemLimite = CorbeilleItem()
        ..entityId = '2'
        ..deletedAt = DateTime(2023, 5, 16); // 30 jours

      final itemVieux = CorbeilleItem()
        ..entityId = '3'
        ..deletedAt = DateTime(2023, 5, 1); // 45 jours

      final items = [itemRecent, itemLimite, itemVieux];

      final toPurge = getItemsToPurge(items, now);
      final keep = filterRecent(items, now);

      expect(toPurge.length, 1);
      expect(toPurge.first.entityId, '3'); // Seul le vieux doit être purgé

      expect(keep.length, 2);
      expect(keep.any((i) => i.entityId == '1'), isTrue);
      expect(keep.any((i) => i.entityId == '2'), isTrue);
    });

    test('Ne purge rien si la corbeille ne contient que des éléments récents', () {
      final now = DateTime(2023, 6, 15);
      final itemRecent1 = CorbeilleItem()..deletedAt = DateTime(2023, 6, 10);
      final itemRecent2 = CorbeilleItem()..deletedAt = DateTime(2023, 6, 14);

      final items = [itemRecent1, itemRecent2];

      expect(getItemsToPurge(items, now).isEmpty, isTrue);
      expect(filterRecent(items, now).length, 2);
    });
  });
}
