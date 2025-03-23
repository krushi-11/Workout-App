import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/recent_performance_widget.dart';

//widget to show details of solo workouts
class SoloWorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  const SoloWorkoutDetailsPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Solo Workout Details'),
      ),
      body: Column(
        children: [
          const RecentPerformanceWidget(),
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
                          "Achieved: ${result.actualoutput} ${exercise.unit.displayName}",
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