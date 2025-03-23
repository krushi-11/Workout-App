import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DownloadWorkoutPage extends StatefulWidget {
  const DownloadWorkoutPage({Key? key}) : super(key: key);

  @override
  State<DownloadWorkoutPage> createState() => _DownloadWorkoutPageState();
}

class _DownloadWorkoutPageState extends State<DownloadWorkoutPage> {
  final _urlController = TextEditingController(); // Input field for URL
  WorkoutPlan? _downloadedWorkoutPlan;
  String? _errorMessage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch workout plan from JSON URL
  Future<void> _fetchWorkoutPlan() async {
    setState(() {
      _downloadedWorkoutPlan = null;
      _errorMessage = null;
    });

    final url = _urlController.text;

    try {
      final response = await http.get(Uri.parse(url)); // Fetch JSON file

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final workoutPlan = WorkoutPlan(
          id: '', // Firestore will generate an ID
          name: data['name'],
          exercises: (data['exercises'] as List).map((exercise) {
            final unitString = exercise['unit'] ?? 'repetitions';
            return Exercise(
              name: exercise['name'],
              targetoutput: int.tryParse(exercise['target'].toString()) ?? 0,
              unit: _parseMeasurementUnit(unitString),
            );
          }).toList(),
        );

        setState(() {
          _downloadedWorkoutPlan = workoutPlan;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch workout plan. Please check the URL.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  // Convert string unit to MeasurementUnit enum
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

  // Save workout plan to Firestore
  Future<void> _saveWorkoutPlan() async {
    if (_downloadedWorkoutPlan != null) {
      try {
        DocumentReference docRef =
        await _firestore.collection('workoutPlans').add(_downloadedWorkoutPlan!.toFirestore());

        // Update the workout plan with Firestore ID
        setState(() {
          _downloadedWorkoutPlan = WorkoutPlan(
            id: docRef.id,
            name: _downloadedWorkoutPlan!.name,
            exercises: _downloadedWorkoutPlan!.exercises,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout plan saved successfully!')),
        );
        _urlController.clear();
        setState(() {
          _downloadedWorkoutPlan = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Workout Plan URL',
                hintText: 'Enter the URL of the workout plan',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _fetchWorkoutPlan,
              child: const Text('Download Workout Plan'),
            ),
            const SizedBox(height: 16.0),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_downloadedWorkoutPlan != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Plan: ${_downloadedWorkoutPlan!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                    const SizedBox(height: 8.0),
                    const Text('Exercises:'),
                    ..._downloadedWorkoutPlan!.exercises.map((exercise) {
                      return Text(
                        '${exercise.name} - Target: ${exercise.targetoutput} ${exercise.unit.displayName}',
                      );
                    }).toList(),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _saveWorkoutPlan,
                      child: const Text('Save Workout Plan'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _downloadedWorkoutPlan = null;
                        });
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}