import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgo_mobile/core/theme/gymgo_theme.dart';
import 'package:gymgo_mobile/features/routines/domain/routine.dart';
import 'package:gymgo_mobile/features/routines/presentation/widgets/exercise_row.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  group('ExerciseRow Widget', () {
    Widget buildTestWidget(ExerciseItem exercise, {VoidCallback? onTap}) {
      return MaterialApp(
        theme: GymGoTheme.darkTheme,
        home: Scaffold(
          body: ExerciseRow(
            exercise: exercise,
            index: 1,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('displays exercise name', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      expect(find.text('Push Up'), findsOneWidget);
    });

    testWidgets('displays index number', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays sets and reps when available', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Squat',
        order: 1,
        sets: 3,
        reps: '10-12',
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      expect(find.text('3 x 10-12'), findsOneWidget);
    });

    testWidgets('shows placeholder when no media available', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      // Should show dumbbell icon as placeholder
      expect(find.byIcon(LucideIcons.dumbbell), findsOneWidget);
    });

    testWidgets('attempts to load GIF when gifUrl is provided', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
        gifUrl: 'https://example.com/pushup.gif',
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      // Should have CachedNetworkImage widget
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('shows play icon overlay when video is available', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
        gifUrl: 'https://example.com/pushup.gif',
        videoUrl: 'https://example.com/pushup.mp4',
      );

      await tester.pumpWidget(buildTestWidget(exercise));
      await tester.pump();

      // Should show play icon
      expect(find.byIcon(LucideIcons.play), findsOneWidget);
    });

    testWidgets('shows YouTube icon for YouTube videos', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
        videoUrl: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
      );

      await tester.pumpWidget(buildTestWidget(exercise));
      await tester.pump();

      // Should show YouTube icon
      expect(find.byIcon(LucideIcons.youtube), findsOneWidget);
    });

    testWidgets('shows chevron when onTap is provided', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(exercise, onTap: () {}));

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('does not show chevron when onTap is null', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(exercise, onTap: null));

      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Push Up',
        order: 1,
      );

      await tester.pumpWidget(buildTestWidget(
        exercise,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(ExerciseRow));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays weight when available', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Deadlift',
        order: 1,
        sets: 5,
        reps: '5',
        weight: '100kg',
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      expect(find.text('100kg'), findsOneWidget);
    });

    testWidgets('displays category badge when available', (WidgetTester tester) async {
      const exercise = ExerciseItem(
        exerciseId: '1',
        exerciseName: 'Bench Press',
        order: 1,
        category: 'Pecho',
      );

      await tester.pumpWidget(buildTestWidget(exercise));

      expect(find.text('Pecho'), findsOneWidget);
    });
  });
}
