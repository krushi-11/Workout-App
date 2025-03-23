import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/workout_provider.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Authenticate user anonymously
  await _signInAnonymously();

  runApp(const MyApp());
}

// Function to sign in anonymously
Future<void> _signInAnonymously() async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("User signed in anonymously: ${userCredential.user?.uid}");
  } catch (e) {
    print("Anonymous sign-in failed: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkoutProvider(),
      child: MaterialApp.router(
        routerConfig: router, // Use GoRouter configuration here
        title: 'Workout Tracker',
        theme: ThemeData(primarySwatch: Colors.blue),
      ),
    );
  }
}