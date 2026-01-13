import 'package:flutter_test/flutter_test.dart';
import 'package:gymgo_mobile/features/notifications/domain/app_notification.dart';

void main() {
  group('AppNotification', () {
    group('fromJson', () {
      test('creates notification from valid JSON', () {
        final json = {
          'id': 'test-123',
          'type': 'class_created',
          'title': 'Nueva clase disponible',
          'body': 'Yoga a las 10:00',
          'createdAt': '2024-01-15T10:00:00.000Z',
          'isRead': false,
          'data': {'classId': 'class-456'},
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.id, equals('test-123'));
        expect(notification.type, equals('class_created'));
        expect(notification.title, equals('Nueva clase disponible'));
        expect(notification.body, equals('Yoga a las 10:00'));
        expect(notification.isRead, isFalse);
        expect(notification.data['classId'], equals('class-456'));
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'test-123',
          'title': 'Test notification',
          'body': 'Test body',
          'createdAt': '2024-01-15T10:00:00.000Z',
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.type, equals(NotificationType.general));
        expect(notification.isRead, isFalse);
        expect(notification.data, isEmpty);
      });

      test('handles data as JSON string', () {
        final json = {
          'id': 'test-123',
          'title': 'Test',
          'body': 'Body',
          'createdAt': '2024-01-15T10:00:00.000Z',
          'data': '{"classId": "class-789"}',
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.data['classId'], equals('class-789'));
      });
    });

    group('toJson', () {
      test('serializes notification correctly', () {
        final notification = AppNotification(
          id: 'test-123',
          type: NotificationType.classCreated,
          title: 'Nueva clase',
          body: 'Yoga a las 10:00',
          createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
          isRead: false,
          data: const {'classId': 'class-456'},
        );

        final json = notification.toJson();

        expect(json['id'], equals('test-123'));
        expect(json['type'], equals('class_created'));
        expect(json['title'], equals('Nueva clase'));
        expect(json['body'], equals('Yoga a las 10:00'));
        expect(json['isRead'], isFalse);
        expect(json['data']['classId'], equals('class-456'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated isRead', () {
        final notification = AppNotification(
          id: 'test-123',
          type: NotificationType.classCreated,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now(),
          isRead: false,
        );

        final updated = notification.copyWith(isRead: true);

        expect(updated.id, equals('test-123'));
        expect(updated.isRead, isTrue);
        expect(notification.isRead, isFalse); // Original unchanged
      });
    });

    group('helper methods', () {
      test('classId returns data value', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.classCreated,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now(),
          data: const {'classId': 'class-123'},
        );

        expect(notification.classId, equals('class-123'));
      });

      test('isClassRelated returns true for class types', () {
        final types = [
          NotificationType.classCreated,
          NotificationType.classUpdated,
          NotificationType.classCancelled,
          NotificationType.bookingConfirmed,
          NotificationType.bookingCancelled,
        ];

        for (final type in types) {
          final notification = AppNotification(
            id: 'test',
            type: type,
            title: 'Test',
            body: 'Body',
            createdAt: DateTime.now(),
          );
          expect(notification.isClassRelated, isTrue,
              reason: 'Type $type should be class related');
        }
      });

      test('isRoutineRelated returns true for routine types', () {
        final types = [
          NotificationType.routineUpdated,
          NotificationType.routineAssigned,
        ];

        for (final type in types) {
          final notification = AppNotification(
            id: 'test',
            type: type,
            title: 'Test',
            body: 'Body',
            createdAt: DateTime.now(),
          );
          expect(notification.isRoutineRelated, isTrue,
              reason: 'Type $type should be routine related');
        }
      });
    });

    group('timeAgo', () {
      test('returns "Ahora" for recent notifications', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.general,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now(),
        );

        expect(notification.timeAgo, equals('Ahora'));
      });

      test('returns minutes format for notifications under 1 hour', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.general,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        expect(notification.timeAgo, equals('Hace 30 min'));
      });

      test('returns hours format for notifications under 24 hours', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.general,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        );

        expect(notification.timeAgo, equals('Hace 5 h'));
      });

      test('returns "Ayer" for notifications from yesterday', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.general,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(notification.timeAgo, equals('Ayer'));
      });

      test('returns days format for notifications under 1 week', () {
        final notification = AppNotification(
          id: 'test',
          type: NotificationType.general,
          title: 'Test',
          body: 'Body',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(notification.timeAgo, equals('Hace 3 días'));
      });
    });
  });

  group('NotificationType', () {
    test('all types are defined', () {
      expect(NotificationType.all, isNotEmpty);
      expect(NotificationType.all, contains(NotificationType.classCreated));
      expect(NotificationType.all, contains(NotificationType.routineUpdated));
      expect(NotificationType.all, contains(NotificationType.general));
    });
  });
}
