import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import '../screens/workout_plan_selector.dart';
import '../widgets/recent_performance_widget.dart';
import '../widgets/workout_card.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Download Workout Plan',
            onPressed: () {
              context.push('/downloadWorkout');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Show RecentPerformanceWidget only for Solo Workouts
          const RecentPerformanceWidget(),

          const SizedBox(height: 10),

          // Section for Solo Workouts
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Solo Workouts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Workout>>(
              stream: workoutProvider.getWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading workouts.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No solo workouts recorded yet.'));
                }

                List<Workout> workouts = snapshot.data!;

                return ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return WorkoutCard(
                      workout: workout,
                      onTap: () {
                        context.push('/soloWorkoutDetails', extra: workout);
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Section for Group Workouts
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Group Workouts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Workout>>(
              stream: workoutProvider.getGroupWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading group workouts.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No group workouts recorded yet.'));
                }

                List<Workout> groupWorkouts = snapshot.data!;

                return ListView.builder(
                  itemCount: groupWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = groupWorkouts[index];

                    return WorkoutCard(
                      workout: workout,
                      onTap: () => _navigateToGroupWorkoutDetails(context, workout),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'btn1',
              backgroundColor: Colors.white70,
              onPressed: () => _selectWorkoutType(context, workoutProvider),
              tooltip: 'Start New Workout',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),  // Adds space between the buttons
            FloatingActionButton(
              heroTag: 'btn2',
              onPressed: () => context.push('/joinWorkout'),
              tooltip: 'Join Workout',
              child: const Text("Join"),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Function to select workout type
  void _selectWorkoutType(BuildContext context, WorkoutProvider workoutProvider) async {
    String? workoutType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Workout Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Solo Workout"),
                onTap: () => Navigator.of(context).pop("solo"),
              ),
              ListTile(
                title: const Text("Collaborative Workout"),
                onTap: () => Navigator.of(context).pop("collaborative"),
              ),
              ListTile(
                title: const Text("Competitive Workout"),
                onTap: () => Navigator.of(context).pop("competitive"),
              ),
            ],
          ),
        );
      },
    );

    if (workoutType == null) return;

    final selectedPlan = await WorkoutPlanSelector.show(context);
    if (selectedPlan == null) return;

    if (workoutType == "solo") {
      final newWorkout = await context.push<Workout>(
        '/workoutRecording',
        extra: {
          'workoutPlan': selectedPlan,
          'inviteCode': null, // If no inviteCode, set it to null
        },
      );

      if (newWorkout != null) {
        workoutProvider.addWorkout(newWorkout);
      }
    } else {
      final inviteCode = await workoutProvider.createGroupWorkout(selectedPlan, workoutType);
      if (inviteCode != null) {
        context.push('/workoutRecording', extra: {
          'workoutPlan': selectedPlan,
          'inviteCode': inviteCode ?? "",
        });
      }
    }
  }

  // Function to Navigate to Correct Group Workout Page
  void _navigateToGroupWorkoutDetails(BuildContext context, Workout workout) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('groupWorkouts')
          .doc(workout.id)
          .get();

      if (!snapshot.exists) {
        print("Workout document does not exist!");
        return;
      }

      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('type')) {
        print("Workout type not found!");
        return;
      }

      String workoutType = data['type'];

      if (workoutType == 'competitive') {
        context.push('/competitiveWorkoutDetails', extra: workout);
      } else {
        context.push('/collaborativeWorkoutDetails', extra: workout);
      }
    } catch (e) {
      print("Error fetching workout type: $e");
    }
  }
}