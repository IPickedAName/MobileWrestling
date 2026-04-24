import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/wrestlerService.dart';
import 'viewmodels/draft_VM.dart';
import 'views/welcomeScreen.dart';
import 'views/loginScreen.dart';
import 'views/homeScreen.dart';
import 'views/draftScreen.dart';
import 'views/bookingScreen.dart';
import 'views/resultsScreen.dart';
import 'views/statsScreen.dart';
import 'views/profileScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  final wrestlers = await WrestlerService.loadWrestlers();

  runApp(
    ChangeNotifierProvider(
      create: (_) => DraftViewModel(
        pool: wrestlers,
        startingBudget: 15000,
      ),
      child: const WrestlerApp(),
    ),
  );
}

class WrestlerApp extends StatelessWidget {
  const WrestlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'wRESTler Fantasy Booker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCC0000),
          secondary: Color(0xFFCC0000),
        ),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFCC0000),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      initialRoute: '/welcome',

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login':   (context) => const LoginScreen(),
        '/home':    (context) => const HomeScreen(),
        '/draft':   (context) => const DraftScreen(),
        '/booking': (context) => const BookingScreen(),
        '/results': (context) => const ResultsScreen(),
        '/stats':   (context) => const StatsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
