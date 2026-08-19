import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/logic/culte_lock.dart';
import 'package:kased_app/core/constants.dart';

void main() {
  group('CulteLock', () {
    group('isLocked', () {
      test('returns false for today\'s culte', () {
        final now = DateTime.now();
        expect(CulteLock.isLocked(now), isFalse);
      });

      test('returns false for culte 29 days ago', () {
        final date = DateTime.now().subtract(const Duration(days: 29));
        expect(CulteLock.isLocked(date), isFalse);
      });

      test('returns false for culte exactly 30 days ago', () {
        final date = DateTime.now().subtract(const Duration(days: 30));
        expect(CulteLock.isLocked(date), isFalse);
      });

      test('returns true for culte 31 days ago', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        expect(CulteLock.isLocked(date), isTrue);
      });

      test('returns true for culte 100 days ago', () {
        final date = DateTime.now().subtract(const Duration(days: 100));
        expect(CulteLock.isLocked(date), isTrue);
      });

      test('returns false for future culte', () {
        final date = DateTime.now().add(const Duration(days: 7));
        expect(CulteLock.isLocked(date), isFalse);
      });

      test('ignores time of day', () {
        final now = DateTime.now();
        final morning = DateTime(now.year, now.month, now.day, 8, 0);
        final evening = DateTime(now.year, now.month, now.day, 20, 0);
        // Both should return the same result
        expect(CulteLock.isLocked(morning), equals(CulteLock.isLocked(evening)));
      });
    });

    group('isPaymentLocked', () {
      test('returns false when culte is not locked', () {
        final now = DateTime.now();
        expect(
          CulteLock.isPaymentLocked(dateCulte: now, cotisationEstPaye: true),
          isFalse,
        );
      });

      test('returns false when culte is locked but payment not made', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        expect(
          CulteLock.isPaymentLocked(dateCulte: date, cotisationEstPaye: false),
          isFalse,
        );
      });

      test('returns true when culte is locked and payment is made', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        expect(
          CulteLock.isPaymentLocked(dateCulte: date, cotisationEstPaye: true),
          isTrue,
        );
      });

      test('returns false for exact 30 days boundary', () {
        final date = DateTime.now().subtract(const Duration(days: 30));
        expect(
          CulteLock.isPaymentLocked(dateCulte: date, cotisationEstPaye: true),
          isFalse,
        );
      });
    });

    group('lockMessage', () {
      test('returns null when culte is not locked', () {
        final now = DateTime.now();
        expect(CulteLock.lockMessage(now), isNull);
      });

      test('returns message when culte is locked', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        final message = CulteLock.lockMessage(date);
        expect(message, isNotNull);
        expect(message, contains('${KasedConstants.joursVerrouillageCulte}'));
      });

      test('returns specific message for locked payment', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        final message = CulteLock.lockMessage(date, cotisationEstPaye: true);
        expect(message, contains('Paiement verrouillé'));
      });

      test('returns general message when not payment lock', () {
        final date = DateTime.now().subtract(const Duration(days: 31));
        final message = CulteLock.lockMessage(date, cotisationEstPaye: false);
        expect(message, contains('Culte verrouillé'));
        expect(message, isNot(contains('Paiement')));
      });
    });

    group('constant leverage', () {
      test('uses KasedConstants.joursVerrouillageCulte', () {
        // If the constant changes, the boundary should change too
        // This test validates that the logic references the constant
        final boundaryDate = DateTime.now().subtract(
          Duration(days: KasedConstants.joursVerrouillageCulte),
        );
        expect(CulteLock.isLocked(boundaryDate), isFalse);

        final lockedDate = DateTime.now().subtract(
          Duration(days: KasedConstants.joursVerrouillageCulte + 1),
        );
        expect(CulteLock.isLocked(lockedDate), isTrue);
      });
    });
  });
}
