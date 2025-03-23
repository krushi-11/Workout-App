import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

//widget to show details of collaborative workout
class CollaborativeWorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  const CollaborativeWorkoutDetailsPage({super.key, required this.workout});

  Future<int?> _fetchParticipantsCount(String workoutId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('groupWorkouts')
          .doc(workoutId)
          .get();

      if (snapshot.exists) {
        List<dynamic> participants = snapshot['participants'] ?? [];
        return participants.length;
      }
      return null;
    } catch (e) {
      print("Error fetching participants: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Collaborative Workout Details'),
      ),
      body: Column(
        children: [
          FutureBuilder<int?>(
            future: _fetchParticipantsCount(workout.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Could not load participant data"),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Participants: ${snapshot.data}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workout.results.length,
              itemBuilder: (context, index) {
                final result = workout.results[index];
                final exercise = result.exercise;
                final isSuccessful = result.isSuccessful;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Icon(
                      isSuccessful ? Icons.check_circle : Icons.cancel,
                      color: isSuccessful ? Colors.green : Colors.red,
                      size: 40.0,
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Target: ${exercise.targetoutput} ${exercise.unit.displayName}",
                          style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                        ),
                        Text(
                          "Total Achieved: ${result.actualoutput} ${exercise.unit.displayName}",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isSuccessful ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}