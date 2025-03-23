import 'package:cloud_firestore/cloud_firestore.dart';

enum MeasurementUnit {
  seconds,
  repetitions,
  meters,
}

// Extension for unit display names
extension MeasurementUnitExtension on MeasurementUnit {
  String get displayName {
    switch (this) {
      case MeasurementUnit.seconds:
        return 'seconds';
      case MeasurementUnit.repetitions:
        return 'repetitions';
      case MeasurementUnit.meters:
        return 'meters';
    }
  }

  static MeasurementUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'seconds':
        return MeasurementUnit.seconds;
      case 'meters':
        return MeasurementUnit.meters;
      default:
        return MeasurementUnit.repetitions;
    }
  }
}

// Exercise Model
class Exercise {
  final String name;
  final int targetoutput;
  final MeasurementUnit unit;

  Exercise({required this.name, required this.targetoutput, required this.unit});

  // Convert Exercise to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetoutput': targetoutput,
      'unit': unit.displayName,
    };
  }

  // Convert Firestore document to Exercise
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'],
      targetoutput: map['targetoutput'],
      unit: MeasurementUnitExtension.fromString(map['unit']),
    );
  }
}

// Exercise Result Model
class ExerciseResult {
  final Exercise exercise;
  final int actualoutput;

  ExerciseResult({required this.exercise, required this.actualoutput});

  bool get isSuccessful => actualoutput >= exercise.targetoutput;

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'actualoutput': actualoutput,
    };
  }

  factory ExerciseResult.fromMap(Map<String, dynamic> map) {
    return ExerciseResult(
      exercise: Exercise.fromMap(map['exercise']),
      actualoutput: map['actualoutput'],
    );
  }
}

// Workout Model
class Workout {
  final String id;
  final DateTime date;
  final List<ExerciseResult> results;

  Workout({required this.id, required this.date, required this.results});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'results': results.map((e) => e.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      date: (map['date'] as Timestamp).toDate(),
      results: (map['results'] as List).map((e) => ExerciseResult.fromMap(e)).toList(),
    );
  }
}

// WorkoutPlan Model
class WorkoutPlan {
  final String id;
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({required this.id, required this.name, required this.exercises});

  // Convert Firestore Document to WorkoutPlan Object
  factory WorkoutPlan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return WorkoutPlan(
      id: doc.id,
      name: data['name'],
      exercises: (data['exercises'] as List).map((exercise) {
        return Exercise(
          name: exercise['name'],
          targetoutput: exercise['targetOutput'],
          unit: exercise['unit'] is int
              ? MeasurementUnit.values[exercise['unit']] // Convert int to Enum
              : MeasurementUnitExtension.fromString(exercise['unit']), // If string
        );
      }).toList(),
    );
  }

  // Convert WorkoutPlan Object to Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'exercises': exercises.map((exercise) => {
        'name': exercise.name,
        'targetOutput': exercise.targetoutput,
        'unit': exercise.unit.index, // Convert Enum to int
      }).toList(),
    };
  }
}