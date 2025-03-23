import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

//widget to get details for competitive workout
class CompetitiveWorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  const CompetitiveWorkoutDetailsPage({super.key, required this.workout});

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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Competitive Workout Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRankings(workout.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No workout results found."));
          }

          List<Map<String, dynamic>> rankings = snapshot.data!;
          rankings.sort((a, b) => (b['total'] ?? 0).compareTo(a['total'] ?? 0));

          int userRank = rankings.indexWhere((r) => r['userId'] == currentUserId) + 1;

          return Column(
            children: [
              // Show user's rank
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Your Rank: $userRank/${rankings.length}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),

              // Show rankings and results
              Expanded(
                child: ListView.builder(
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final participant = rankings[index];
                    final String participantId = participant['userId'];
                    final bool isCurrentUser = participantId == currentUserId;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Participant Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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

                        // Show each exercise result in a card format
                        ...participant['results'].map<Widget>((result) {
                          final int actualOutput = result['actualoutput'] ?? 0;
                          final int targetOutput = result['exercise']['targetoutput'] ?? 0;
                          final bool isSuccessful = actualOutput >= targetOutput;
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
                                result['exercise']['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Target: ${result['exercise']['targetoutput']} ${result['exercise']['unit']}",
                                    style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                                  ),
                                  Text(
                                    "Achieved: ${result['actualoutput']} ${result['exercise']['unit']}",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: isSuccessful ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
