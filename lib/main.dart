import 'package:flutter/material.dart';
import 'services/wrestlerService.dart';
import 'services/simEngine.dart';
import 'models/wrestler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final wrestlers = await WrestlerService.loadWrestlers();
  for (var w in wrestlers) {
    print('${w.name} | ${w.wrestlerClass} | inRing: ${w.inRing} | salary: \$${w.salary}k | canBook: ${w.canBeBooked}');
  }

  final engine = SimulationEngine();

  final cody = wrestlers.firstWhere((w) => w.name == 'Cody Rhodes');
  final gunther = wrestlers.firstWhere((w) => w.name == 'Gunther');

  double rating = engine.simulateRating(
    w1: cody, w2: gunther, matchType: 'Championship'
  );
  Wrestler winner = engine.determineWinner(cody, gunther);
  int points = engine.calculatePoints(
    starRating: rating,
    correctPrediction: true,
    wasUpset: false,
    cardPosition: 'Main Event',
    allMatchesBooked: true,
    showAvgRating: rating,
  );

  print('--- MATCH SIMULATION ---');
  print('${cody.name} vs ${gunther.name}');
  print('Rating: $rating stars');
  print('Winner: ${winner.name}');
  print('Points earned: $points');

  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('Sim test — check terminal')))
  ));
}