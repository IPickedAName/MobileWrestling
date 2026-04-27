import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/wrestlerService.dart';
import 'viewmodels/draft_VM.dart';
import 'viewmodels/simVM.dart';
import 'views/welcomeScreen.dart';
import 'views/loginScreen.dart';
import 'views/homeScreen.dart';
import 'views/draftScreen.dart';
import 'views/bookingScreen.dart';
import 'views/resultsScreen.dart';
import 'views/statsScreen.dart';
import 'views/profileScreen.dart';
import 'views/leaderboardScreen.dart';
import 'theme/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase unsupported on this platform (web, Windows) — local logic still works
  }

  final wrestlers = await WrestlerService.loadWrestlers();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DraftViewModel(pool: wrestlers, startingBudget: 15000),
        ),
        ChangeNotifierProvider(
          create: (_) => SimViewModel(),
        ),
      ],
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
      theme: GameTheme.buildTheme(),

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
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
