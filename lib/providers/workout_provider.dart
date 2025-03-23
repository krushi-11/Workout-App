import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class WorkoutProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Fetch Workouts from Firestore
  Stream<List<Workout>> getWorkouts() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Workout(
          id: doc.id,
          date: (doc['date'] as Timestamp).toDate(),
          results: (doc['results'] as List).map((exercise) {
            return ExerciseResult(
              exercise: Exercise(
                name: exercise['name'],
                targetoutput: exercise['targetoutput'],
                unit: _parseMeasurementUnit(exercise['unit']),
              ),
              actualoutput: exercise['actualoutput'],
            );
          }).toList(),
        );
      }).toList();
    });
  }

  Stream<List<Workout>> getGroupWorkouts() {
    return _firestore
        .collection('groupWorkouts')
        .where('participants', arrayContains: _userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();

        if (!data.containsKey('type') || !data.containsKey('results') || !data.containsKey('createdAt')) {
          print("Firestore document missing required fields: $data");
          return null;
        }

        String workoutType = data['type'];
        dynamic rawResults = data['results'];
        List<Exercise> workoutExercises = (data['exercises'] as List).map((exercise) {
          return Exercise(
            name: exercise['name'],
            targetoutput: exercise['targetOutput'], // Fetch correct targetoutput
            unit: _parseMeasurementUnit(exercise['unit']),
          );
        }).toList();

        List<ExerciseResult> finalResults = [];

        if (workoutType == 'collaborative') {
          // Ensure results are treated as a **Map**, not a List
          if (rawResults is Map<String, dynamic>) {
            rawResults.forEach((exerciseName, exerciseData) {
              Exercise? matchedExercise = workoutExercises.firstWhere(
                    (ex) => ex.name == exerciseName,
                orElse: () => Exercise(name: exerciseName, targetoutput: 0, unit: MeasurementUnit.repetitions),
              );

              finalResults.add(
                ExerciseResult(
                  exercise: matchedExercise, // Ensures correct targetoutput is assigned
                  actualoutput: exerciseData['totalOutput'] ?? 0,
                ),
              );
            });
          }
        } else if (workoutType == 'competitive') {
          // Ensure results are treated as a **Map**, not a List
          if (rawResults is Map<String, dynamic>) {
            rawResults.forEach((userId, userResults) {
              if (userResults is List) {
                for (var entry in userResults) {
                  Exercise originalExercise = Exercise.fromMap(entry['exercise']);
                  Exercise updatedExercise = workoutExercises.firstWhere(
                        (ex) => ex.name == originalExercise.name,
                    orElse: () => Exercise(name: originalExercise.name, targetoutput: 0, unit: originalExercise.unit),
                  );
                  finalResults.add(
                    ExerciseResult(
                      exercise: updatedExercise,
                      actualoutput: entry['actualoutput'],
                    ),
                  );
                }
              }
            });
          }
        }

        return Workout(
          id: doc.id,
          date: (data['createdAt'] as Timestamp).toDate(),
          results: finalResults,
        );
      }).whereType<Workout>().toList();
    });
  }

  // Save Workout to Firestore
  Future<void> addWorkout(Workout workout) async {
    try {
      print("addWorkout() CALLED with ID: ${workout.id}");

      CollectionReference workoutsRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts');

      // Ensure we store a unique ID for each workout
      String workoutId = "${workout.date.millisecondsSinceEpoch}_${workout.results.map((e) => e.exercise.name).join(",")}";

      QuerySnapshot existingWorkouts = await workoutsRef
          .where('id', isEqualTo: workoutId)
          .get();

      if (existingWorkouts.docs.isEmpty) {
        await workoutsRef.add({
          'id': workoutId,
          'date': Timestamp.fromDate(workout.date),
          'results': workout.results.map((result) {
            return {
              'name': result.exercise.name,
              'targetoutput': result.exercise.targetoutput,
              'unit': result.exercise.unit.displayName,
              'actualoutput': result.actualoutput,
            };
          }).toList(),
        });

        print("Workout added successfully!");
        notifyListeners();
      } else {
        print("Workout already exists! Skipping duplicate entry.");
      }
    } catch (e) {
      print("Error saving workout: $e");
    }
  }

  // Fetch workouts from the last 7 days
  Stream<List<Workout>> getRecentWorkouts() {
    DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('date', isGreaterThan: sevenDaysAgo)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Workout(
          id: doc.id,
          date: (doc['date'] as Timestamp).toDate(),
          results: (doc['results'] as List).map((exercise) {
            return ExerciseResult(
              exercise: Exercise(
                name: exercise['name'],
                targetoutput: exercise['targetoutput'],
                unit: _parseMeasurementUnit(exercise['unit']),
              ),
              actualoutput: exercise['actualoutput'],
            );
          }).toList(),
        );
      }).toList();
    });
  }

  // Create a new group workout and return the invite code
  Future<String?> createGroupWorkout(WorkoutPlan workoutPlan, String type) async {
    try {
      String inviteCode = _generateInviteCode(); // Generate a unique code

      DocumentReference docRef = await _firestore.collection('groupWorkouts').add({
        'inviteCode': inviteCode, // Store the invite code
        'name': workoutPlan.name,
        'exercises': workoutPlan.exercises.map((exercise) => {
          'name': exercise.name,
          'targetOutput': exercise.targetoutput,
          'unit': exercise.unit.displayName,
        }).toList(),
        'type': type,
        'participants': [_userId], // Add creator to participants
        'results': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Group workout created with invite code: $inviteCode");
      return inviteCode;
    } catch (e) {
      print("Error creating group workout: $e");
      return null;
    }
  }

  // ✅ Join a group workout
  Future<bool> joinGroupWorkout(String inviteCode) async {
    try {
      print("Trying to join workout with code: $inviteCode");

      QuerySnapshot querySnapshot = await _firestore
          .collection('groupWorkouts')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Invalid invite code: Workout does not exist.");
        return false; // No workout found with this invite code
      }

      DocumentSnapshot workoutDoc = querySnapshot.docs.first;
      String workoutId = workoutDoc.id;
      Map<String, dynamic> workoutData = workoutDoc.data() as Map<String, dynamic>;

      List<dynamic> participants = workoutData['participants'] ?? [];

      if (!participants.contains(_userId)) {
        await _firestore.collection('groupWorkouts').doc(workoutId).update({
          'participants': FieldValue.arrayUnion([_userId]),
        });

        print("Successfully joined the workout. Added participant: $_userId");
      } else {
        print("User already in workout.");
      }

      return true;
    } catch (e) {
      print("Error joining workout: $e");
      return false;
    }
  }

  // Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Helper method to convert unit strings
  MeasurementUnit _parseMeasurementUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'seconds':
        return MeasurementUnit.seconds;
      case 'meters':
        return MeasurementUnit.meters;
      case 'repetitions':
      default:
        return MeasurementUnit.repetitions;
    }
  }

  Future<WorkoutPlan?> getGroupWorkoutPlan(String inviteCode) async {
    DocumentSnapshot snapshot = await _firestore.collection('groupWorkouts').doc(inviteCode).get();

    if (!snapshot.exists) return null;

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return WorkoutPlan(
      id: inviteCode,
      name: data['name'],
      exercises: (data['exercises'] as List).map((exercise) => Exercise.fromMap(exercise)).toList(),
    );
  }

  Future<void> submitGroupWorkoutResults(String inviteCode, List<ExerciseResult> results) async {
    try {
      print("Submitting workout results for invite code: $inviteCode");

      QuerySnapshot querySnapshot = await _firestore
          .collection('groupWorkouts')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Workout not found in Firestore! Invite Code: $inviteCode");
        return;
      }

      DocumentSnapshot workoutDoc = querySnapshot.docs.first;
      DocumentReference workoutRef = _firestore.collection('groupWorkouts').doc(workoutDoc.id);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(workoutRef);
        if (!snapshot.exists) {
          print("Workout not found in Firestore during transaction!");
          return;
        }

        Map<String, dynamic> workoutData = snapshot.data() as Map<String, dynamic>;

        // Ensure 'results' exists and is a Map
        Map<String, dynamic> existingResults = {};
        if (workoutData.containsKey('results') && workoutData['results'] is Map<String, dynamic>) {
          existingResults = Map<String, dynamic>.from(workoutData['results']);
        }

        if (workoutData['type'] == 'collaborative') {
          // Sum up results for collaborative workouts
          for (var result in results) {
            String exerciseName = result.exercise.name;

            if (!existingResults.containsKey(exerciseName)) {
              existingResults[exerciseName] = {'totalOutput': 0};
            }

            // Add the user's output to the existing total output
            existingResults[exerciseName]['totalOutput'] += result.actualoutput;
          }
        } else {
          // Store competitive results separately per user
          existingResults[_userId] = results.map((r) => r.toMap()).toList();
        }

        transaction.update(workoutRef, {'results': existingResults});
      });

      print("Workout results saved!");
    } catch (e) {
      print("Error saving group workout results: $e");
    }
  }

  Future<void> _addCollaborativeResults(DocumentReference workoutRef, List<ExerciseResult> results) async {
    DocumentSnapshot snapshot = await workoutRef.get();
    Map<String, dynamic> workoutData = snapshot.data() as Map<String, dynamic>;

    // Ensure 'results' exists and is a Map, not a List
    Map<String, dynamic> existingResults = {};
    if (workoutData.containsKey('results') && workoutData['results'] is Map<String, dynamic>) {
      existingResults = workoutData['results'];
    }

    for (var result in results) {
      String exerciseName = result.exercise.name;

      if (!existingResults.containsKey(exerciseName)) {
        existingResults[exerciseName] = {'totalOutput': 0};
      }

      // Add the user's output to the existing total output
      existingResults[exerciseName]['totalOutput'] += result.actualoutput;
    }

    await workoutRef.update({'results': existingResults});
  }

  Future<void> _addCompetitiveResults(DocumentReference workoutRef, List<ExerciseResult> results) async {
    DocumentSnapshot snapshot = await workoutRef.get();
    Map<String, dynamic> workoutData = snapshot.data() as Map<String, dynamic>;

    // Ensure 'results' exists and is a Map, not a List
    Map<String, dynamic> existingResults = {};
    if (workoutData.containsKey('results') && workoutData['results'] is Map<String, dynamic>) {
      existingResults = workoutData['results'];
    }

    // Store individual user's results separately
    existingResults[_userId] = results.map((r) => r.toMap()).toList();

    await workoutRef.update({'results': existingResults});
  }

  Future<List<dynamic>> getGroupWorkoutResults(String inviteCode) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('groupWorkouts').doc(inviteCode).get();
      if (!snapshot.exists) return [];

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      return data['results'] ?? [];
    } catch (e) {
      print("Error fetching group workout results: $e");
      return [];
    }
  }


  Future<WorkoutPlan?> getWorkoutByInviteCode(String inviteCode) async {
    try {
      print("Searching for workout with invite code: $inviteCode");

      QuerySnapshot querySnapshot = await _firestore
          .collection('groupWorkouts') // Ensure collection name matches Firestore
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        print("Workout found in Firestore!");

        return WorkoutPlan.fromFirestore(doc);
      } else {
        print("No workout found for invite code: $inviteCode");
        return null;
      }
    } catch (e) {
      print("Error fetching workout by invite code: $e");
      return null;
    }
  }

  List<ExerciseResult> _sumCollaborativeResults(List<dynamic> resultsData) {
    Map<String, int> totalOutputs = {}; // Stores combined outputs per exercise
    Map<String, Exercise> exerciseDetails = {}; // Stores exercise details

    for (var userResults in resultsData) {
      if (userResults is Map<String, dynamic>) {
        for (var entry in userResults['exercises']) {
          String exerciseName = entry['exercise']['name'];
          int actualOutput = entry['actualoutput'];

          if (!exerciseDetails.containsKey(exerciseName)) {
            exerciseDetails[exerciseName] = Exercise.fromMap(entry['exercise']);
          }

          // Sum total outputs for collaborative workouts
          totalOutputs[exerciseName] = (totalOutputs[exerciseName] ?? 0) + actualOutput;
        }
      }
    }

    // Convert summed results into `ExerciseResult` objects
    return totalOutputs.entries.map((entry) {
      return ExerciseResult(
        exercise: exerciseDetails[entry.key]!,
        actualoutput: entry.value,
      );
    }).toList();
  }

  List<ExerciseResult> _getCompetitiveResults(Map<String, dynamic> rawResults) {
    List<ExerciseResult> allResults = [];

    rawResults.forEach((userId, userResults) {
      for (var entry in userResults) {
        allResults.add(
          ExerciseResult(
            exercise: Exercise.fromMap(entry['exercise']),
            actualoutput: entry['actualoutput'],
          ),
        );
      }
    });

    return allResults;
  }
}