import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/models.dart';

//widget to show performance score for solo workouts only
class RecentPerformanceWidget extends StatelessWidget {
  const RecentPerformanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Workout>>(
      stream: Provider.of<WorkoutProvider>(context, listen: false).getRecentWorkouts(),
      builder: (context, snapshot) {
        List<Workout> recentWorkouts = snapshot.data ?? [];

        int totalExercises = 0;
        int successfulExercises = 0;
        int failedExercises = 0;
        int workoutCount = recentWorkouts.length;

        // Define penalty for each failed exercise
        const int penaltyPerFailure = 5;
        const int workoutBonus = 5;

        for (var workout in recentWorkouts) {
          totalExercises += workout.results.length;
          successfulExercises += workout.results.where((r) => r.isSuccessful).length;
          failedExercises += workout.results.where((r) => !r.isSuccessful).length;
        }

        int performanceScore = (totalExercises > 0)
            ? (((successfulExercises * 100) ~/ totalExercises) + (workoutCount * workoutBonus) - (failedExercises * penaltyPerFailure)).clamp(0, 100)
            : 0; // Default score when no workouts exist

        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          color: Colors.blueGrey[50],
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient styling
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Text(
                    "Recent Performance Score",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                ),
                const SizedBox(height: 8.0),

                // Performance Score Display (Even when there are no workouts)
                Text(
                  "$performanceScore",
                  style: const TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: Colors.teal),
                ),

                const SizedBox(height: 4.0),

                if (recentWorkouts.isEmpty) // Show only when no workouts exist
                  const Text(
                    "No recent workouts found.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14.0),
                  )
                else
                  const Text(
                    "Performance score based on last 7 days' workouts",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14.0),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}