import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/simEngine.dart';

class MatchBooking {
  final Wrestler w1;
  final Wrestler w2;
  final String matchType;
  final Wrestler predictedWinner;

  const MatchBooking({
    required this.w1,
    required this.w2,
    required this.matchType,
    required this.predictedWinner,
  });
}

class MatchResult {
  final String position;
  final Wrestler w1;
  final Wrestler w2;
  final Wrestler winner;
  final double starRating;
  final int points;
  final bool correctPrediction;
  final bool wasUpset;

  const MatchResult({
    required this.position,
    required this.w1,
    required this.w2,
    required this.winner,
    required this.starRating,
    required this.points,
    required this.correctPrediction,
    required this.wasUpset,
  });
}

class WeekSummary {
  final int week;
  final int playerPoints;
  final int aiPoints;
  final double avgRating;

  const WeekSummary({
    required this.week,
    required this.playerPoints,
    required this.aiPoints,
    required this.avgRating,
  });
}

class SimViewModel extends ChangeNotifier {
  final SimulationEngine _engine = SimulationEngine();

  static const List<String> positions = ['Opener', 'Midcard', 'Midcard', 'Main Event'];

  List<Wrestler> playerRoster = [];
  List<Wrestler> aiRoster = [];

  int totalWeeks = 12;
  int currentWeek = 1;
  int playerTotalPoints = 0;
  int aiTotalPoints = 0;

  List<WeekSummary> history = [];
  List<MatchBooking?> card = [null, null, null, null];
  List<MatchResult> weekResults = [];

  bool weekSimulated = false;
  bool seasonOver = false;
  bool seasonStarted = false;

  void initSeason(List<Wrestler> pRoster, List<Wrestler> aRoster, {int weeks = 12}) {
    playerRoster = List.from(pRoster);
    aiRoster = List.from(aRoster);
    totalWeeks = weeks;
    currentWeek = 1;
    playerTotalPoints = 0;
    aiTotalPoints = 0;
    history = [];
    card = [null, null, null, null];
    weekResults = [];
    weekSimulated = false;
    seasonOver = false;
    seasonStarted = true;
    notifyListeners();
  }

  bool get cardFull => card.every((m) => m != null);
  int get slotsBooked => card.where((m) => m != null).length;

  Set<String> get _bookedNames {
    final names = <String>{};
    for (final m in card) {
      if (m != null) {
        names.add(m.w1.name);
        names.add(m.w2.name);
      }
    }
    return names;
  }

  List<Wrestler> get availableWrestlers =>
      playerRoster.where((w) => w.canBeBooked && !_bookedNames.contains(w.name)).toList();

  void setSlot(int index, Wrestler w1, Wrestler w2, String matchType, Wrestler predictedWinner) {
    card[index] = MatchBooking(w1: w1, w2: w2, matchType: matchType, predictedWinner: predictedWinner);
    notifyListeners();
  }

  void clearSlot(int index) {
    card[index] = null;
    notifyListeners();
  }

  void simulateWeek() {
    if (!cardFull) return;

    weekResults = [];
    double totalRating = 0;
    int playerPts = 0;

    for (int i = 0; i < 4; i++) {
      final match = card[i]!;
      final pos = positions[i];

      final rating = _engine.simulateRating(w1: match.w1, w2: match.w2, matchType: match.matchType);
      final winner = _engine.determineWinner(match.w1, match.w2);
      final won1 = winner.name == match.w1.name;
      final loser = won1 ? match.w2 : match.w1;

      match.w1.addFeudalEncounter(match.w2.name);
      match.w2.addFeudalEncounter(match.w1.name);

      match.w1.currentStamina =
          (match.w1.currentStamina - _engine.staminaDrain(pos, match.matchType, won1))
              .clamp(0, match.w1.stamina);
      match.w2.currentStamina =
          (match.w2.currentStamina - _engine.staminaDrain(pos, match.matchType, !won1))
              .clamp(0, match.w2.stamina);
      match.w1.matchesThisWeek++;
      match.w2.matchesThisWeek++;

      final correctPred = match.predictedWinner.name == winner.name;
      final wasUpset = winner.popularity < loser.popularity;

      int pts = _basePoints(rating);
      if (correctPred) pts += wasUpset ? 35 : 15;
      if (pos == 'Main Event') pts += 10;
      if (pos == 'Opener' && rating >= 3.5) pts += 5;

      totalRating += rating;
      playerPts += pts;

      weekResults.add(MatchResult(
        position: pos,
        w1: match.w1,
        w2: match.w2,
        winner: winner,
        starRating: rating,
        points: pts,
        correctPrediction: correctPred,
        wasUpset: wasUpset,
      ));

      _engine.updateAfterMatch(wrestler: winner, won: true, starRating: rating, wasMainEvent: i == 3);
      _engine.updateAfterMatch(wrestler: loser, won: false, starRating: rating, wasMainEvent: i == 3);
    }

    final avgRating = totalRating / 4;
    playerPts += 10; // full card booked bonus
    if (avgRating >= 4.5) {
      playerPts += 25;
    } else if (avgRating >= 3.75) {
      playerPts += 15;
    }

    final aiPts = _simulateAI();
    playerTotalPoints += playerPts;
    aiTotalPoints += aiPts;

    history.add(WeekSummary(
      week: currentWeek,
      playerPoints: playerPts,
      aiPoints: aiPts,
      avgRating: avgRating,
    ));

    weekSimulated = true;
    notifyListeners();
  }

  int _basePoints(double rating) {
    if (rating >= 5.0) return 60;
    if (rating >= 4.5) return 50;
    if (rating >= 4.0) return 40;
    if (rating >= 3.5) return 30;
    if (rating >= 3.0) return 20;
    if (rating >= 2.5) return 10;
    return 0;
  }

  int _simulateAI() {
    final available = aiRoster.where((w) => w.canBeBooked).toList()
      ..sort((a, b) => (b.popularity + b.inRing).compareTo(a.popularity + a.inRing));

    if (available.length < 8) return available.length * 15;

    int aiPts = 0;
    double totalRating = 0;

    for (int i = 0; i < 4; i++) {
      final idx = (3 - i) * 2; // best wrestlers go to main event
      final w1 = available[idx];
      final w2 = available[idx + 1];
      final type = i == 3 ? 'Championship' : 'Singles';
      final pos = positions[i];

      final rating = _engine.simulateRating(w1: w1, w2: w2, matchType: type);
      final winner = _engine.determineWinner(w1, w2);
      final won1 = winner.name == w1.name;

      w1.addFeudalEncounter(w2.name);
      w2.addFeudalEncounter(w1.name);
      w1.currentStamina = (w1.currentStamina - _engine.staminaDrain(pos, type, won1)).clamp(0, w1.stamina);
      w2.currentStamina = (w2.currentStamina - _engine.staminaDrain(pos, type, !won1)).clamp(0, w2.stamina);

      int pts = _basePoints(rating);
      if (pos == 'Main Event') pts += 10;
      if (pos == 'Opener' && rating >= 3.5) pts += 5;

      totalRating += rating;
      aiPts += pts;

      _engine.updateAfterMatch(wrestler: winner, won: true, starRating: rating, wasMainEvent: i == 3);
      _engine.updateAfterMatch(wrestler: won1 ? w2 : w1, won: false, starRating: rating, wasMainEvent: i == 3);
    }

    aiPts += 10;
    final avg = totalRating / 4;
    if (avg >= 4.5) {
      aiPts += 25;
    } else if (avg >= 3.75) {
      aiPts += 15;
    }

    return aiPts;
  }

  void advanceWeek() {
    final bookedNames = weekResults.fold(<String>{}, (set, r) {
      set.add(r.w1.name);
      set.add(r.w2.name);
      return set;
    });

    for (final w in playerRoster) {
      if (!bookedNames.contains(w.name)) _engine.recoverStamina(w, benchedThisWeek: true);
      w.matchesThisWeek = 0;
    }

    for (final w in aiRoster) {
      w.currentStamina = min(w.stamina, w.currentStamina + 5);
      w.matchesThisWeek = 0;
    }

    currentWeek++;
    card = [null, null, null, null];
    weekResults = [];
    weekSimulated = false;
    if (currentWeek > totalWeeks) seasonOver = true;

    notifyListeners();
  }
}
