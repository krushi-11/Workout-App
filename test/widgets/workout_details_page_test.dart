import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/models/models.dart';
import 'package:project_1/providers/workout_provider.dart';
import 'package:project_1/screens/workout_details_page.dart';
import 'package:provider/provider.dart';

import '../custom_mock_box.dart';

void main() {
  ///test case to check that workout details page shows exercise details
  testWidgets('WorkoutDetailsPage shows exercise details', (WidgetTester tester) async {
    final workout = Workout(
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
    );

    //renders the widget in test environment
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider(CustomMockBox<Workout>()), // Pass the mocked box here
        child: MaterialApp(
          home: WorkoutDetailsPage(workout: workout),
        ),
      ),
    );

    //wait till all animation gets rendered sometimes tests do not pass because of UI
    await tester.pumpAndSettle();

    //expectations from the test
    expect(find.text('Push Ups'), findsOneWidget);
    expect(find.textContaining('Target: 10 repetitions'), findsOneWidget);
    expect(find.textContaining('Achieved: 12 repetitions'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.textContaining('Target: 1000 meters'), findsOneWidget);
    expect(find.textContaining('Achieved: 900 meters'), findsOneWidget);
  });
}