import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/services/notify_port.dart';

void main() {
  group('NotificationEvent', () {
    test('creates event with all fields', () {
      final event = NotificationEvent(
        type: 'membre_ajoute',
        label: 'Jean Dupont',
        membreId: 'm1',
        extra: 'extra',
      );

      expect(event.type, 'membre_ajoute');
      expect(event.label, 'Jean Dupont');
      expect(event.membreId, 'm1');
      expect(event.extra, 'extra');
    });

    test('creates event without optional fields', () {
      final event = NotificationEvent(
        type: 'culte_cree',
        label: 'Culte du 17/08/2026',
      );

      expect(event.type, 'culte_cree');
      expect(event.label, 'Culte du 17/08/2026');
      expect(event.membreId, isNull);
      expect(event.extra, isNull);
    });

    test('equality works correctly', () {
      final e1 = NotificationEvent(type: 'test', label: 'label');
      final e2 = NotificationEvent(type: 'test', label: 'label');
      final e3 = NotificationEvent(type: 'other', label: 'label');

      expect(e1, equals(e2));
      expect(e1, isNot(e3));
    });
  });

  group('FakeNotifyAdapter', () {
    late FakeNotifyAdapter adapter;

    setUp(() {
      adapter = FakeNotifyAdapter();
    });

    test('records events', () {
      adapter.send(NotificationEvent(type: 'test', label: 'label'));
      expect(adapter.events.length, 1);
      expect(adapter.events.first.type, 'test');
    });

    test('hasEventType returns true for existing type', () {
      adapter.send(NotificationEvent(type: 'membre_ajoute', label: 'Jean'));
      expect(adapter.hasEventType('membre_ajoute'), isTrue);
      expect(adapter.hasEventType('membre_supprime'), isFalse);
    });

    test('lastEvent returns null when empty', () {
      expect(adapter.lastEvent, isNull);
    });

    test('lastEvent returns last sent event', () {
      adapter.send(NotificationEvent(type: 'first', label: '1'));
      adapter.send(NotificationEvent(type: 'second', label: '2'));
      expect(adapter.lastEvent?.type, 'second');
    });

    test('eventsOfType filters correctly', () {
      adapter.send(NotificationEvent(type: 'a', label: '1'));
      adapter.send(NotificationEvent(type: 'b', label: '2'));
      adapter.send(NotificationEvent(type: 'a', label: '3'));

      expect(adapter.eventsOfType('a').length, 2);
      expect(adapter.eventsOfType('b').length, 1);
    });

    test('events is unmodifiable', () {
      adapter.send(NotificationEvent(type: 'test', label: 'label'));
      expect(() => adapter.events.add(NotificationEvent(type: 'x', label: 'y')), throwsUnsupportedError);
    });
  });

  group('RealNotifyAdapter', () {
    late RealNotifyAdapter adapter;

    setUp(() {
      adapter = RealNotifyAdapter();
    });

    test('records events', () {
      adapter.send(NotificationEvent(type: 'test', label: 'label'));
      expect(adapter.events.length, 1);
    });
  });

  group('NoOpNotifyAdapter', () {
    late NoOpNotifyAdapter adapter;

    setUp(() {
      adapter = NoOpNotifyAdapter();
    });

    test('does not record events', () {
      adapter.send(NotificationEvent(type: 'test', label: 'label'));
      expect(adapter.events, isEmpty);
    });
  });
}
