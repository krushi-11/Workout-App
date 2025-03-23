import 'package:flutter/material.dart';
import '../models/models.dart';

//a card widget that displays a summary of completed workout and also shows the date and successful number of exercises
class WorkoutCard extends StatelessWidget {
  final Workout workout;
  //callback function for when the card is tapped
  final VoidCallback onTap;

  const WorkoutCard({Key? key, required this.workout, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //this calculates the number of exercises that were successfully completed
    final successfulResults = workout.results.where((r) => r.isSuccessful).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          'Workout on ${workout.date.toLocal().toString().split(' ')[0]}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        //shows exercise result with color
        subtitle: Text(
          '$successfulResults/${workout.results.length} exercises successful',
          style: TextStyle(
            fontSize: 14.0,
            //green if all exercises are successfully completed
            color: successfulResults == workout.results.length ? Colors.green : Colors.red,
          ),
        ),
        //handle tap events using the provided callback
        onTap: onTap,
      ),
    );
  }
}