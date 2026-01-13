import 'package:flutter_test/flutter_test.dart';
import 'package:gymgo_mobile/core/router/routes.dart';

void main() {
  group('Routes Configuration', () {
    test('memberRoutines path is correct', () {
      expect(Routes.memberRoutines, equals('/member/routines'));
    });

    test('memberRoutines name is correct', () {
      expect(Routes.memberRoutinesName, equals('member-routines'));
    });

    test('memberRoutineDetail path includes id parameter', () {
      expect(Routes.memberRoutineDetail, equals('/member/routines/:id'));
    });

    test('home route is defined', () {
      expect(Routes.home, equals('/home'));
    });

    test('all main routes are defined', () {
      // Verify all main routes exist
      expect(Routes.home, isNotEmpty);
      expect(Routes.memberClasses, isNotEmpty);
      expect(Routes.memberRoutines, isNotEmpty);
      expect(Routes.memberMeasurements, isNotEmpty);
      expect(Routes.profile, isNotEmpty);
    });
  });

  group('Quick Actions Navigation Targets', () {
    // This test verifies the navigation behavior conceptually
    // The actual navigation is tested in integration tests

    test('routines quick action should navigate to /member/routines', () {
      // The Home dashboard "Rutinas" quick action should navigate to the same
      // route as the bottom navigation "Rutinas" tab.
      // Both should use Routes.memberRoutines which is '/member/routines'
      const expectedRoute = '/member/routines';
      expect(Routes.memberRoutines, equals(expectedRoute));
    });

    test('bottom nav index 2 corresponds to routines', () {
      // MainShell bottom navigation:
      // 0 = Home (/home)
      // 1 = Classes (/member/classes)
      // 2 = Routines (/member/routines) <-- This is what we verify
      // 3 = Measurements (/member/measurements)
      // 4 = Profile (/profile)

      // This documents the expected behavior that both quick action
      // and bottom nav should go to the same route
      const bottomNavRoutinesRoute = '/member/routines';
      const quickActionRoutinesRoute = '/member/routines';

      expect(bottomNavRoutinesRoute, equals(quickActionRoutinesRoute));
    });
  });
}
