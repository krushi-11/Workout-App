import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;
  final bool isSoloWorkout;

  const WorkoutDetailsPage({super.key, required this.workout, this.isSoloWorkout = true});

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

  Future<List<Map<String, dynamic>>> _fetchRankings(String workoutId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('groupWorkouts')
          .doc(workoutId)
          .get();

      if (!snapshot.exists) return [];

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> results = data['results'] ?? {};

      List<Map<String, dynamic>> rankings = [];

      results.forEach((userId, userResults) {
        if (userResults is List) {
          int totalScore = userResults.fold<int>(
            0,
                (sum, entry) => sum + ((entry['actualoutput'] ?? 0) as num).toInt(),
          );
          rankings.add({
            'userId': userId,
            'total': totalScore,
            'results': userResults,
          });
        }
      });

      rankings.sort((a, b) => (b['total'] ?? 0).compareTo(a['total'] ?? 0));

      return rankings;
    } catch (e) {
      print("Error fetching rankings: $e");
      return [];
    }
  }

  Future<String?> _fetchWorkoutType(String workoutId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('groupWorkouts')
          .doc(workoutId)
          .get();

      if (snapshot.exists) {
        return snapshot['type'];
      }
      return null;
    } catch (e) {
      print("Error fetching workout type: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Workout Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isSoloWorkout) const RecentPerformanceWidget(),

            if (!isSoloWorkout)
              FutureBuilder<String?>(
                future: _fetchWorkoutType(workout.id),
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
                      child: Text("Could not load workout type"),
                    );
                  }

                  bool isCompetitiveWorkout = snapshot.data == 'competitive';

                  return Column(
                    children: [
                      if (!isCompetitiveWorkout)
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),

                      if (isCompetitiveWorkout)
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchRankings(workout.id),
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
                                child: Text("Could not load rankings"),
                              );
                            }

                            List<Map<String, dynamic>> rankings = snapshot.data!;
                            rankings.sort((a, b) => (b['total'] ?? 0).compareTo(a['total'] ?? 0));

                            // Move the current user's results to the top
                            Map<String, dynamic>? currentUserResults = rankings.firstWhere(
                                  (r) => r['userId'] == currentUserId,
                              orElse: () => {},
                            );

                            if (currentUserResults.isNotEmpty) {
                              rankings.removeWhere((r) => r['userId'] == currentUserId);
                              rankings.insert(0, currentUserResults);
                            }

                            return Column(
                              children: rankings.map((participant) {
                                String participantId = participant['userId'];
                                bool isCurrentUser = participantId == currentUserId;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        isCurrentUser
                                            ? "🏆 Your Results"
                                            : "👥 Participant: $participantId",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentUser ? Colors.blue : Colors.black,
                                        ),
                                      ),
                                    ),
                                    ...participant['results'].map<Widget>((result) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        decoration: BoxDecoration(
                                          color: isCurrentUser
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16.0),
                                          leading: Icon(
                                            (result['actualoutput'] ?? 0) >=
                                                (result['exercise']['targetoutput'] ?? 0)
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: (result['actualoutput'] ?? 0) >=
                                                (result['exercise']['targetoutput'] ?? 0)
                                                ? Colors.green
                                                : Colors.red,
                                            size: 40.0,
                                          ),
                                          title: Text(
                                            result['exercise']['name'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16.0),
                                          ),
                                          subtitle: Text(
                                            "Achieved: ${result['actualoutput']} ${result['exercise']['unit']}",
                                            style: const TextStyle(fontSize: 14.0),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),

            // Display **only** the selected workout's results
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workout.results.length,
              itemBuilder: (context, index) {
                final result = workout.results[index];
                final exercise = result.exercise;
                final isSuccessful = result.isSuccessful;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: ${exercise.targetoutput} ${exercise.unit.displayName}',
                          style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                        ),
                        Text(
                          'Achieved: ${result.actualoutput} ${exercise.unit.displayName}',
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
          ],
        ),
      ),
    );
  }
}