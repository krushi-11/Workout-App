import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/models/models.dart';
import 'package:project_1/screens/workout_history_page.dart';
import 'package:project_1/providers/workout_provider.dart';

import '../custom_mock_box.dart';

void main() {
  testWidgets('WorkoutHistoryPage shows multiple workout entries', (WidgetTester tester) async {
    final mockBox = CustomMockBox<Workout>();

    // Add sample data to mock box
    mockBox.add(Workout(
      date: DateTime.now(),
      results: [ExerciseResult(exercise: Exercise(name: 'Push Ups', targetoutput: 10, unit: MeasurementUnit.repetitions), actualoutput: 12)],
    ));
    mockBox.add(Workout(
      date: DateTime.now().subtract(const Duration(days: 1)),
      results: [ExerciseResult(exercise: Exercise(name: 'Running', targetoutput: 1000, unit: MeasurementUnit.meters), actualoutput: 1200)],
    ));

    // Create WorkoutProvider with CustomMockBox
    final workoutProvider = WorkoutProvider(mockBox);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: workoutProvider,
        child: const MaterialApp(home: WorkoutHistoryPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify workout entries are displayed
    expect(find.textContaining('Workout on'), findsNWidgets(2));
    expect(find.textContaining('1/1 exercises successful'), findsNWidgets(2));
  });
}
