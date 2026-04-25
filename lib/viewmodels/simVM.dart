import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/simEngine.dart';

class PromoBooking {
  final Wrestler wrestler;
  const PromoBooking({required this.wrestler});
}

class MatchBooking {
  final Wrestler w1;
  final Wrestler w2;
  final Wrestler? w3;
  final Wrestler? w4;
  final String matchType;
  final Wrestler predictedWinner;

  const MatchBooking({
    required this.w1,
    required this.w2,
    this.w3,
    this.w4,
    required this.matchType,
    required this.predictedWinner,
  });

  bool get isTagTeam => matchType == 'Tag Team' && w3 != null && w4 != null;
  String get teamALabel => isTagTeam ? '${w1.name} & ${w2.name}' : w1.name;
  String get teamBLabel => isTagTeam ? '${w3!.name} & ${w4!.name}' : w2.name;
}

class MatchResult {
  final String position;
  final String matchType;
  final Wrestler w1;
  final Wrestler w2;
  final Wrestler? w3;
  final Wrestler? w4;
  final Wrestler winner;
  final double starRating;
  final int points;
  final bool correctPrediction;
  final bool wasUpset;

  const MatchResult({
    required this.position,
    required this.matchType,
    required this.w1,
    required this.w2,
    this.w3,
    this.w4,
    required this.winner,
    required this.starRating,
    required this.points,
    required this.correctPrediction,
    required this.wasUpset,
  });

  bool get isTagTeam => matchType == 'Tag Team' && w3 != null && w4 != null;
  String get sideALabel => isTagTeam ? '${w1.name} & ${w2.name}' : w1.name;
  String get sideBLabel => isTagTeam ? '${w3!.name} & ${w4!.name}' : w2.name;
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
  List<PromoBooking?> promos = [null, null];
  List<MatchResult> weekResults = [];
  List<MatchResult> aiWeekResults = [];

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
    promos = [null, null];
    weekResults = [];
    aiWeekResults = [];
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
        if (m.w3 != null) names.add(m.w3!.name);
        if (m.w4 != null) names.add(m.w4!.name);
      }
    }
    for (final p in promos) {
      if (p != null) names.add(p.wrestler.name);
    }
    return names;
  }

  List<Wrestler> get availableWrestlers =>
      playerRoster.where((w) => w.canBeBooked && !_bookedNames.contains(w.name)).toList();

  void setSlot(
    int index,
    Wrestler w1,
    Wrestler w2,
    String matchType,
    Wrestler predictedWinner, {
    Wrestler? w3,
    Wrestler? w4,
  }) {
    card[index] = MatchBooking(
      w1: w1,
      w2: w2,
      w3: w3,
      w4: w4,
      matchType: matchType,
      predictedWinner: predictedWinner,
    );
    notifyListeners();
  }

  void clearSlot(int index) {
    card[index] = null;
    notifyListeners();
  }

  void setPromoSlot(int index, Wrestler wrestler) {
    promos[index] = PromoBooking(wrestler: wrestler);
    notifyListeners();
  }

  void clearPromoSlot(int index) {
    promos[index] = null;
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

      late final double rating;
      late final Wrestler winner;
      late final Wrestler loser;

      if (match.isTagTeam) {
        final teamAProxy = _buildTagProxy(match.w1, match.w2, 'A');
        final teamBProxy = _buildTagProxy(match.w3!, match.w4!, 'B');
        rating = _engine.simulateRating(
          w1: teamAProxy,
          w2: teamBProxy,
          matchType: match.matchType,
        );
        final proxyWinner = _engine.determineWinner(teamAProxy, teamBProxy);
        final teamAWon = proxyWinner.name == teamAProxy.name;
        winner = teamAWon ? match.w1 : match.w3!;
        loser = teamAWon ? match.w3! : match.w1;

        _recordTagFeud(match);
        _applyMatchOutcome(match.w1, pos, match.matchType, won: teamAWon);
        _applyMatchOutcome(match.w2, pos, match.matchType, won: teamAWon);
        _applyMatchOutcome(match.w3!, pos, match.matchType, won: !teamAWon);
        _applyMatchOutcome(match.w4!, pos, match.matchType, won: !teamAWon);

        _engine.updateAfterMatch(
          wrestler: match.w1,
          won: teamAWon,
          starRating: rating,
          wasMainEvent: i == 3,
        );
        _engine.updateAfterMatch(
          wrestler: match.w2,
          won: teamAWon,
          starRating: rating,
          wasMainEvent: i == 3,
        );
        _engine.updateAfterMatch(
          wrestler: match.w3!,
          won: !teamAWon,
          starRating: rating,
          wasMainEvent: i == 3,
        );
        _engine.updateAfterMatch(
          wrestler: match.w4!,
          won: !teamAWon,
          starRating: rating,
          wasMainEvent: i == 3,
        );
      } else {
        rating = _engine.simulateRating(w1: match.w1, w2: match.w2, matchType: match.matchType);
        winner = _engine.determineWinner(match.w1, match.w2);
        final won1 = winner.name == match.w1.name;
        loser = won1 ? match.w2 : match.w1;

        match.w1.addFeudalEncounter(match.w2.name);
        match.w2.addFeudalEncounter(match.w1.name);

        _applyMatchOutcome(match.w1, pos, match.matchType, won: won1);
        _applyMatchOutcome(match.w2, pos, match.matchType, won: !won1);

        _engine.updateAfterMatch(wrestler: winner, won: true, starRating: rating, wasMainEvent: i == 3);
        _engine.updateAfterMatch(wrestler: loser, won: false, starRating: rating, wasMainEvent: i == 3);
      }

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
        matchType: match.matchType,
        w1: match.w1,
        w2: match.w2,
        w3: match.w3,
        w4: match.w4,
        winner: winner,
        starRating: rating,
        points: pts,
        correctPrediction: correctPred,
        wasUpset: wasUpset,
      ));
    }

    final avgRating = totalRating / 4;
    playerPts += 10; // full card booked bonus
    if (avgRating >= 4.5) {
      playerPts += 25;
    } else if (avgRating >= 3.75) {
      playerPts += 15;
    }

    // Process promo segments
    for (final promo in promos) {
      if (promo != null) {
        final w = promo.wrestler;
        w.currentStamina = min(w.stamina, w.currentStamina + w.promoSkill * 4);
        w.popularity = (w.popularity + w.promoSkill).clamp(1, 100);
      }
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
    aiWeekResults = [];
    final available = aiRoster.where((w) => w.canBeBooked).toList()
      ..sort((a, b) => (b.popularity + b.inRing).compareTo(a.popularity + a.inRing));

    if (available.length < 8) return available.length * 15;

    int aiPts = 0;
    double totalRating = 0;

    for (int i = 0; i < 4; i++) {
      final idx = (3 - i) * 2;
      final w1 = available[idx];
      final w2 = available[idx + 1];
      final type = i == 3 ? 'Championship' : 'Singles';
      final pos = positions[i];

      final rating = _engine.simulateRating(w1: w1, w2: w2, matchType: type);
      final winner = _engine.determineWinner(w1, w2);
      final won1 = winner.name == w1.name;
      final loser = won1 ? w2 : w1;

      w1.addFeudalEncounter(w2.name);
      w2.addFeudalEncounter(w1.name);
      w1.currentStamina = (w1.currentStamina - _engine.staminaDrain(pos, type, won1)).clamp(0, w1.stamina);
      w2.currentStamina = (w2.currentStamina - _engine.staminaDrain(pos, type, !won1)).clamp(0, w2.stamina);

      int pts = _basePoints(rating);
      if (pos == 'Main Event') pts += 10;
      if (pos == 'Opener' && rating >= 3.5) pts += 5;

      totalRating += rating;
      aiPts += pts;

      aiWeekResults.add(MatchResult(
        position: pos,
        matchType: type,
        w1: w1,
        w2: w2,
        winner: winner,
        starRating: rating,
        points: pts,
        correctPrediction: false,
        wasUpset: winner.popularity < loser.popularity,
      ));

      _engine.updateAfterMatch(wrestler: winner, won: true, starRating: rating, wasMainEvent: i == 3);
      _engine.updateAfterMatch(wrestler: loser, won: false, starRating: rating, wasMainEvent: i == 3);
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
    final matchBookedNames = weekResults.fold(<String>{}, (set, r) {
      set.add(r.w1.name);
      set.add(r.w2.name);
      return set;
    });

    // Promo wrestlers already got recovery in simulateWeek — don't double-recover
    final promoNames = promos
        .where((p) => p != null)
        .map((p) => p!.wrestler.name)
        .toSet();

    for (final w in playerRoster) {
      if (!matchBookedNames.contains(w.name) && !promoNames.contains(w.name)) {
        _engine.recoverStamina(w, benchedThisWeek: true);
      }
      w.matchesThisWeek = 0;
    }

    for (final w in aiRoster) {
      w.currentStamina = min(w.stamina, w.currentStamina + 5);
      w.matchesThisWeek = 0;
    }

    currentWeek++;
    card = [null, null, null, null];
    promos = [null, null];
    weekResults = [];
    aiWeekResults = [];
    weekSimulated = false;
    if (currentWeek > totalWeeks) seasonOver = true;

    notifyListeners();
  }

  Wrestler _buildTagProxy(Wrestler a, Wrestler b, String key) {
    final aLead = a.inRing + a.popularity >= b.inRing + b.popularity ? a : b;
    return Wrestler(
      name: 'Team$key:${a.name}&${b.name}',
      promotion: aLead.promotion,
      role: a.role == b.role ? a.role : aLead.role,
      wrestlerClass: aLead.wrestlerClass,
      inRing: ((a.effectiveInRing + b.effectiveInRing) / 2).round(),
      charisma: ((a.charisma + b.charisma) / 2).round(),
      promoSkill: ((a.promoSkill + b.promoSkill) / 2).round(),
      popularity: ((a.popularity + b.popularity) / 2).round(),
      morale: ((a.morale + b.morale) / 2).round(),
      stamina: max(a.stamina, b.stamina),
      currentStamina: ((a.currentStamina + b.currentStamina) / 2).round(),
      salary: a.salary + b.salary,
      contractWeeks: min(a.contractWeeks, b.contractWeeks),
      momentum: ((a.momentum + b.momentum) / 2).round(),
    );
  }

  void _recordTagFeud(MatchBooking match) {
    final teamA = [match.w1, match.w2];
    final teamB = [match.w3!, match.w4!];
    for (final a in teamA) {
      for (final b in teamB) {
        a.addFeudalEncounter(b.name);
        b.addFeudalEncounter(a.name);
      }
    }
  }

  void _applyMatchOutcome(Wrestler wrestler, String position, String matchType, {required bool won}) {
    wrestler.currentStamina =
        (wrestler.currentStamina - _engine.staminaDrain(position, matchType, won))
            .clamp(0, wrestler.stamina);
    wrestler.matchesThisWeek++;
  }
}
