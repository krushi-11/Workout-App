import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/widgets/recent_performance_widget.dart';
import 'package:project_1/models/models.dart';
import 'package:project_1/providers/workout_provider.dart';
import '../custom_mock_box.dart';

void main() {
  late CustomMockBox<Workout> mockWorkoutBox; //temporary box for testing

  setUp(() {
    mockWorkoutBox = CustomMockBox<Workout>();

    // Mock the values with sample workouts
    mockWorkoutBox.add(Workout(
      date: DateTime.now(),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Push Ups', targetoutput: 10, unit: MeasurementUnit.repetitions),
          actualoutput: 12,
        ),
        ExerciseResult(
          exercise: Exercise(name: 'Running', targetoutput: 1000, unit: MeasurementUnit.meters),
          actualoutput: 900,
        ),
      ],
    ));
  });

  ///test case to verify the widget displays correct metrics when workout exists
  testWidgets('RecentPerformanceWidget displays a metric based on workouts', (WidgetTester tester) async {
    //initialize workout provider with mock box
    final workoutProvider = WorkoutProvider(mockWorkoutBox);

    //this will pump the widget into test
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: workoutProvider,
        child: const MaterialApp(
          home: Scaffold(body: RecentPerformanceWidget()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    //expectations from the test case
    expect(find.textContaining('Recent Performance'), findsOneWidget);
    expect(find.textContaining('Total exercises completed: 2'), findsOneWidget);
    expect(find.textContaining('Successful exercises: 1'), findsOneWidget);
  });

  ///test case to check the widget displays empty state message when no workout are there
  testWidgets('RecentPerformanceWidget displays default message when no workouts exist', (WidgetTester tester) async {
    final emptyBox = CustomMockBox<Workout>(); // Creates an empty box
    //initialize the provider with empty box
    final workoutProvider = WorkoutProvider(emptyBox);

    //pump the widget in the test case
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: workoutProvider,
        child: const MaterialApp(
          home: Scaffold(body: RecentPerformanceWidget()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    //expectation from the test
    expect(find.textContaining('No workouts recorded in the past 7 days.'), findsOneWidget);
  });
}