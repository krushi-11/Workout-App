import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

//widget for recording the workouts using selected plan
class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final String? inviteCode;

  const WorkoutRecordingPage({Key? key, required this.workoutPlan, this.inviteCode}) : super(key: key);

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<Exercise, int> _exerciseResults = {};
  final Map<Exercise, Stopwatch> _stopwatches = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (var exercise in widget.workoutPlan.exercises) {
      _exerciseResults[exercise] = 0;
      if (exercise.unit == MeasurementUnit.seconds) {
        _stopwatches[exercise] = Stopwatch();
      }
    }
  }

  // function to submit workout
  void _submitWorkout() async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    final results = _exerciseResults.entries.map((entry) {
      print("Submitting result: ${entry.key.name} - ${entry.value}");
      return ExerciseResult(exercise: entry.key, actualoutput: entry.value);
    }).toList();

    if (widget.inviteCode != null) {
      print("Submitting workout results for invite code: ${widget.inviteCode}");
      await workoutProvider.submitGroupWorkoutResults(widget.inviteCode!, results);
    } else {
      final workout = Workout(
        id: '',
        date: DateTime.now(),
        results: results,
      );

      workoutProvider.addWorkout(workout);
    }

    print("Workout submission complete!");
    context.go('/');
  }

  // Stopwatches for Time-Based Exercises
  Widget _buildStopwatchInput(Exercise exercise) {
    return ListTile(
      title: Text('${exercise.name} (Target: ${exercise.targetoutput} sec)'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_stopwatches[exercise]!.isRunning) {
                  _stopwatches[exercise]!.stop();
                  _timer?.cancel();
                  _exerciseResults[exercise] = _stopwatches[exercise]!.elapsed.inSeconds;
                } else {
                  _stopwatches[exercise]!.reset();
                  _stopwatches[exercise]!.start();
                  _startTimer(exercise);
                }
              });
            },
            child: Text(_stopwatches[exercise]!.isRunning ? 'Stop' : 'Start'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${_exerciseResults[exercise]} sec'),
          ),
        ],
      ),
    );
  }

  void _startTimer(Exercise exercise) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatches[exercise]!.isRunning) {
        setState(() {
          _exerciseResults[exercise] = _stopwatches[exercise]!.elapsed.inSeconds;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // Stepper Input for Repetitions-Based Exercises
  Widget _buildStepperInput(Exercise exercise) {
    return ListTile(
      title: Text('${exercise.name} (Target: ${exercise.targetoutput} reps)'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _exerciseResults[exercise] = (_exerciseResults[exercise]! - 1).clamp(0, 999);
              });
            },
          ),
          Text('${_exerciseResults[exercise]}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _exerciseResults[exercise] = (_exerciseResults[exercise]! + 1).clamp(0, 999);
              });
            },
          ),
        ],
      ),
    );
  }

  // Slider Input for Distance-Based Exercises
  Widget _buildSliderInput(Exercise exercise) {
    return Column(
      children: [
        Text('${exercise.name} (Target: ${exercise.targetoutput} meters)'),
        Slider(
          value: _exerciseResults[exercise]!.toDouble(),
          min: 0,
          max: exercise.targetoutput.toDouble() * 1.5,
          divisions: 50,
          label: '${_exerciseResults[exercise]} meters',
          onChanged: (value) {
            setState(() {
              _exerciseResults[exercise] = value.toInt();
            });
          },
        ),
      ],
    );
  }

  // Builds Input Fields Based on Measurement Unit
  Widget _buildExerciseInput(Exercise exercise) {
    switch (exercise.unit) {
      case MeasurementUnit.repetitions:
        return _buildStepperInput(exercise);
      case MeasurementUnit.seconds:
        return _buildStopwatchInput(exercise);
      case MeasurementUnit.meters:
        return _buildSliderInput(exercise);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workoutPlan.name)),
      body: Column(
        children: [
          if (widget.inviteCode != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  const Text(
                    "Invite Code:",
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SelectableText(
                    widget.inviteCode!,
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 16.0),
                  QrImageView(
                    data: widget.inviteCode!, // The invite code that you generated
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                  const Text(
                    "Share this code with others to join the workout!",
                    style: TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: widget.workoutPlan.exercises.map(_buildExerciseInput).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _submitWorkout,
              child: const Text('Finish Workout'),
            ),
          ),
        ],
      ),
    );
  }
}