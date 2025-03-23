import 'package:flutter/material.dart';
import '../models/models.dart';

// this is reusable widget for inputting exercise data
class ExerciseInputWidget extends StatelessWidget {
  //exercise get recorded
  final Exercise exercise;
  //callback function to handle input changes
  final Function(String) onValueChanged;

  const ExerciseInputWidget({Key? key, required this.exercise, required this.onValueChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exercise.name),
      //shows the target and unit of exercise
      subtitle: Text('Target: ${exercise.targetoutput} ${exercise.unit.displayName}'),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: onValueChanged,
        ),
      ),
    );
  }
}