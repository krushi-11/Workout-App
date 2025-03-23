import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/models/fake_data.dart';
import 'package:project_1/models/models.dart';
import 'package:project_1/providers/workout_provider.dart';
import 'package:project_1/screens/workout_recording_page.dart';
import 'package:provider/provider.dart';

import '../custom_mock_box.dart';

///test file for workout recording widget
void main() {
  group('WorkoutRecordingPage Tests', () {
    //shared provider instance across the file
    late WorkoutProvider workoutProvider;

    //sets up a fresh workoutprovider before each test
    setUp(() {
      final mockBox = CustomMockBox<Workout>();
      workoutProvider = WorkoutProvider(mockBox);
    });

    //helper function to wrap the widget with provider
    Widget createTestableWidget(Widget child) {
      return ChangeNotifierProvider<WorkoutProvider>.value(
        value: workoutProvider,
        child: MaterialApp(home: child),
      );
    }

    ///test that checks each exercise in workout plan has input
    testWidgets('WorkoutRecordingPage shows a separate input for each exercise in the workout plan', (WidgetTester tester) async {
      //renders the widget in test environment
      await tester.pumpWidget(
        ChangeNotifierProvider<WorkoutProvider>.value(
          value: workoutProvider,
          child: MaterialApp(
            home: WorkoutRecordingPage(workoutPlan: exampleWorkoutPlan),
          ),
        ),
      );
      //verifies each exercise has corresponding input widget
      for (var exercise in exampleWorkoutPlan.exercises) {
        expect(find.byKey(Key('${exercise.name}')), findsOneWidget);
      }
    });

    ///test case that checks the complete workflow of recording a workout
    testWidgets('WorkoutRecordingPage adds a Workout to the shared state when the user fills out and ends a workout', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<WorkoutProvider>.value(
          value: workoutProvider,
          child: MaterialApp(
            home: WorkoutRecordingPage(workoutPlan: exampleWorkoutPlan),
          ),
        ),
      );
      // checking the entered valid exercise values
      for (var exercise in exampleWorkoutPlan.exercises) {
        if (exercise.unit == MeasurementUnit.repetitions) {
          await tester.tap(find.byKey(Key('add_${exercise.name}')));
        } else if (exercise.unit == MeasurementUnit.seconds) {
          await tester.tap(find.byKey(Key('${exercise.name}')));
          await tester.pump(const Duration(seconds: 1)); // Simulate stopwatch running
          await tester.tap(find.byKey(Key('${exercise.name}')));
        } else if (exercise.unit == MeasurementUnit.meters) {
          await tester.drag(find.byKey(Key('${exercise.name}')), const Offset(50.0, 0.0));
        }
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // Submit workout
      await tester.tap(find.byKey(Key('submit_workout_button')));

      await tester.pumpAndSettle();


      // Verify workout is added to provider
      expect(workoutProvider.workouts.length, 1);
    });
  });
}