import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

// Hardcoded workout plan
final exampleWorkoutPlan = WorkoutPlan(
  id: 'default_plan',  // Assign a fixed ID for easy retrieval
  name: "Full Body Workout",
  exercises: [
    Exercise(name: 'Push Ups', targetoutput: 20, unit: MeasurementUnit.repetitions),
    Exercise(name: 'Plank', targetoutput: 60, unit: MeasurementUnit.seconds),
    Exercise(name: 'Running', targetoutput: 1000, unit: MeasurementUnit.meters),
    Exercise(name: 'Jumping Jacks', targetoutput: 30, unit: MeasurementUnit.repetitions),
    Exercise(name: 'Squats', targetoutput: 15, unit: MeasurementUnit.repetitions),
    Exercise(name: 'Cycling', targetoutput: 5000, unit: MeasurementUnit.meters),
    Exercise(name: 'Burpees', targetoutput: 10, unit: MeasurementUnit.repetitions),
  ],
);

// Function to upload the hardcoded workout plan to Firestore if it's missing
Future<void> uploadDefaultWorkoutPlan() async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection('workoutPlans').doc(exampleWorkoutPlan.id);

  final docSnapshot = await docRef.get();
  if (!docSnapshot.exists) {
    await docRef.set({
      'name': exampleWorkoutPlan.name,
      'exercises': exampleWorkoutPlan.exercises.map((exercise) => {
        'name': exercise.name,
        'targetOutput': exercise.targetoutput,
        'unit': exercise.unit.index,
      }).toList(),
    });
  }
}