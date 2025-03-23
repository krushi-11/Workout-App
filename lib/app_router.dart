import 'package:go_router/go_router.dart';
import 'package:project_1/screens/download_workout_plan_page.dart';
import 'package:project_1/screens/workout_history_page.dart';
import 'package:project_1/screens/solo_workout_details_page.dart';
import 'package:project_1/screens/collaborative_workout_details_page.dart';
import 'package:project_1/screens/competitive_workout_details_page.dart';
import 'package:project_1/screens/workout_recording_page.dart';
import 'package:project_1/screens/join_group_workout_page.dart';
import 'models/models.dart';

// routings for all the pages
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WorkoutHistoryPage(),
    ),
    GoRoute(
      path: '/downloadWorkout',
      builder: (context, state) => const DownloadWorkoutPage(),
    ),
    GoRoute(
      path: '/soloWorkoutDetails',
      builder: (context, state) {
        final workout = state.extra as Workout;
        return SoloWorkoutDetailsPage(workout: workout);
      },
    ),
    GoRoute(
      path: '/collaborativeWorkoutDetails',
      builder: (context, state) {
        final workout = state.extra as Workout;
        return CollaborativeWorkoutDetailsPage(workout: workout);
      },
    ),
    GoRoute(
      path: '/competitiveWorkoutDetails',
      builder: (context, state) {
        final workout = state.extra as Workout;
        return CompetitiveWorkoutDetailsPage(workout: workout);
      },
    ),
    GoRoute(
      path: '/workoutRecording',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return WorkoutRecordingPage(
          workoutPlan: args['workoutPlan'],
          inviteCode: args['inviteCode'],
        );
      },
    ),
    GoRoute(
      path: '/joinWorkout',
      builder: (context, state) => const JoinWorkoutPage(),
    ),
  ],
);