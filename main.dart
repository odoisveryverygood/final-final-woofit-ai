import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Firebase
import 'firebase_options.dart';

// Theme
import 'theme.dart';

// Screens for AuthWrapper
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/dog_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/analyzer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WoofFitApp());
}

class WoofFitApp extends StatelessWidget {
  const WoofFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<DogProvider>(
          create: (_) => DogProvider(),
        ),
        ChangeNotifierProvider<PlanProvider>(
          create: (_) => PlanProvider(),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => ActivityProvider(),
        ),
        ChangeNotifierProvider<AnalyzerProvider>(
          create: (_) => AnalyzerProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'WoofFit',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthWrapper(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AUTH WRAPPER: Decides whether to show Onboarding/Login or Home based on auth
// ---------------------------------------------------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If user is not logged in → show onboarding/login
    if (authProvider.user == null) {
      return const OnboardingScreen();
    }

    // If user is logged in → go to home screen
    return const HomeScreen();
  }
}

