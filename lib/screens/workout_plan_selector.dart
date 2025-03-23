import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/fake_data.dart';

class WorkoutPlanSelector {
  static Future<WorkoutPlan?> show(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('workoutPlans').get();

    // Convert Firestore Data to WorkoutPlan Objects
    final firebasePlans = querySnapshot.docs.map((doc) => WorkoutPlan.fromFirestore(doc)).toList();

    // Ensure hardcoded plan isn't duplicated
    bool isExamplePlanInFirestore = firebasePlans.any((plan) => plan.name == exampleWorkoutPlan.name);

    // If not already in Firestore, add the hardcoded exampleWorkoutPlan
    final allPlans = isExamplePlanInFirestore ? firebasePlans : [exampleWorkoutPlan, ...firebasePlans];

    return showDialog<WorkoutPlan>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Workout Plan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allPlans.length,
              itemBuilder: (context, index) {
                final plan = allPlans[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: plan.exercises.map((exercise) {
                        return Text(
                          '- ${exercise.name} (Target: ${exercise.targetoutput} ${exercise.unit.displayName})',
                        );
                      }).toList(),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(plan);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}