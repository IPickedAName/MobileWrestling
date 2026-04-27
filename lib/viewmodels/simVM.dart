import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/simEngine.dart';

class PromoBooking {
  final Wrestler wrestler;
  const PromoBooking({required this.wrestler});
}

class RestBooking {
  final Wrestler wrestler;
  final int recoveryAmount;

  const RestBooking({required this.wrestler, this.recoveryAmount = 20});
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
  final int matchRevenue;
  final int cardCost;

  const WeekSummary({
    required this.week,
    required this.playerPoints,
    required this.aiPoints,
    required this.avgRating,
    this.matchRevenue = 0,
    this.cardCost = 0,
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
  List<RestBooking?> rests = [null, null];
  List<MatchResult> weekResults = [];
  List<MatchResult> aiWeekResults = [];

  bool weekSimulated = false;
  bool seasonOver = false;
  bool seasonStarted = false;
  bool arcadeMode = false;
  int Function(String matchType) _matchCostResolver = (_) => 0;
void resetSeasonState() {
  playerRoster = [];
  aiRoster = [];

  currentWeek = 1;
  playerTotalPoints = 0;
  aiTotalPoints = 0;

  history = [];
  card = [null, null, null, null];
  promos = [null, null];
  rests = [null, null];

  weekResults = [];
  aiWeekResults = [];

  weekSimulated = false;
  seasonOver = false;
  seasonStarted = false;

  notifyListeners();
}
  void initSeason(
    List<Wrestler> pRoster,
    List<Wrestler> aRoster, {
    int weeks = 12,
    bool arcadeMode = false,
    int Function(String matchType)? matchCostResolver,
  }) {
    playerRoster = List.from(pRoster);
    aiRoster = List.from(aRoster);
    this.arcadeMode = arcadeMode;
    _matchCostResolver = matchCostResolver ?? (_) => 0;
    totalWeeks = weeks;
    currentWeek = 1;
    playerTotalPoints = 0;
    aiTotalPoints = 0;
    history = [];
    card = [null, null, null, null];
    promos = [null, null];
    rests = [null, null];
    weekResults = [];
    aiWeekResults = [];
    weekSimulated = false;
    seasonOver = false;
    seasonStarted = true;
    notifyListeners();
  }

  bool get cardFull => card.every((m) => m != null);
  int get slotsBooked => card.where((m) => m != null).length;

  

  void syncPlayerRoster(List<Wrestler> roster) {
    playerRoster = List.from(roster);
    card = [null, null, null, null];
    promos = [null, null];
    rests = [null, null];
    notifyListeners();
  }

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
    for (final r in rests) {
      if (r != null) names.add(r.wrestler.name);
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

  void setRestSlot(int index, Wrestler wrestler, {int? recoveryAmount}) {
    rests[index] = RestBooking(
      wrestler: wrestler,
      recoveryAmount: recoveryAmount ?? (arcadeMode ? 30 : 20),
    );
    notifyListeners();
  }

  void clearRestSlot(int index) {
    rests[index] = null;
    notifyListeners();
  }

  void autoBookCard() {
    if (!seasonStarted || weekSimulated) return;

    card = [null, null, null, null];
    promos = [null, null];
    rests = [null, null];

    _ensureAutoBookAvailability();

    final bookable = List<Wrestler>.from(playerRoster.where((w) => w.canBeBooked));
    final available = arcadeMode && bookable.length < 8
      ? List<Wrestler>.from(playerRoster)
      : bookable;
    if (available.length < 8) {
      notifyListeners();
      return;
    }

    available.sort((a, b) => _autoBookScore(b).compareTo(_autoBookScore(a)));

    final champions = available.where((w) => w.isChampion).toList()
      ..sort((a, b) => _autoBookScore(b).compareTo(_autoBookScore(a)));

    final usedNames = <String>{};

    MatchBooking buildSingles(List<Wrestler> picks, String matchType) {
      final w1 = picks[0];
      final w2 = picks[1];
      usedNames.add(w1.name);
      usedNames.add(w2.name);
      return MatchBooking(
        w1: w1,
        w2: w2,
        matchType: matchType,
        predictedWinner: w1.popularity >= w2.popularity ? w1 : w2,
      );
    }

    if (champions.length >= 2) {
      final mainEventPool = [champions[0], champions[1]];
      card[3] = buildSingles(mainEventPool, 'Championship');
    } else {
      final mainEventPool = available.where((w) => !usedNames.contains(w.name)).take(2).toList();
      if (mainEventPool.length == 2) {
        card[3] = buildSingles(mainEventPool, 'Singles');
      }
    }

    final remaining = available.where((w) => !usedNames.contains(w.name)).toList();
    for (int slot = 0; slot < 3; slot++) {
      final start = slot * 2;
      if (remaining.length >= start + 2) {
        card[slot] = buildSingles(
          [remaining[start], remaining[start + 1]],
          'Singles',
        );
      }
    }

    final restCandidates = playerRoster
        .where((w) => !usedNames.contains(w.name))
        .toList()
      ..sort((a, b) => a.currentStamina.compareTo(b.currentStamina));

    for (int i = 0; i < rests.length && i < restCandidates.length; i++) {
      rests[i] = RestBooking(
        wrestler: restCandidates[i],
        recoveryAmount: arcadeMode ? 30 : 20,
      );
    }

    notifyListeners();
  }

  void autoFinishWeek() {
    if (!seasonStarted || weekSimulated) return;
    autoBookCard();
    if (cardFull) {
      simulateWeek();
    }
  }

  void autoPlayToSeasonEnd() {
    if (!seasonStarted) return;

    int safety = totalWeeks * 3;

    while (!seasonOver && safety > 0) {
      safety--;
      if (!weekSimulated) {
        autoBookCard();
        if (!cardFull) {
          _recoverRosterForAutoPlay();
          continue;
        }
        simulateWeek();
      }
      advanceWeek();
    }

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

    // Ticket revenue per match based on position and star rating
    int matchRevenue = 0;
    int cardCost = 0;
    for (int i = 0; i < weekResults.length; i++) {
      final r = weekResults[i];
      final base = i == 3 ? 120 : (i == 0 ? 40 : 70); // Main Event / Opener / Midcard
      final ratingBonus = ((r.starRating - 3.0).clamp(0.0, 2.0) * 20).round();
      final champBonus = r.matchType == 'Championship' ? 30 : 0;
      final tagBonus = r.isTagTeam ? 15 : 0;
      matchRevenue += base + ratingBonus + champBonus + tagBonus;
      cardCost += _matchCostResolver(r.matchType);
    }

    // Process promo segments
    for (final promo in promos) {
      if (promo != null) {
        final w = promo.wrestler;
        final recovery = (w.promoSkill * (arcadeMode ? 5 : 4)).round();
        w.currentStamina = min(w.stamina, w.currentStamina + recovery);
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
      matchRevenue: matchRevenue,
      cardCost: cardCost,
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
    final available = _buildAIBookableRoster();
    if (available.length < 2) return 0;

    final matchesToBook = min(4, available.length ~/ 2);

    int aiPts = 0;
    double totalRating = 0;

    for (int i = 0; i < matchesToBook; i++) {
      final idx = i * 2;
      final w1 = available[idx];
      final w2 = available[idx + 1];
      final type = i == matchesToBook - 1 ? 'Championship' : 'Singles';
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

    if (matchesToBook == 4) {
      aiPts += 10;
      final avg = totalRating / 4;
      if (avg >= 4.5) {
        aiPts += 25;
      } else if (avg >= 3.75) {
        aiPts += 15;
      }
    }

    return aiPts;
  }

  List<Wrestler> _buildAIBookableRoster() {
    int safety = 0;
    while (aiRoster.where((w) => w.canBeBooked).length < 8 && safety < 3) {
      for (final wrestler in aiRoster.where((w) => !w.canBeBooked)) {
        _engine.recoverStamina(wrestler, benchedThisWeek: true);
      }
      safety++;
    }

    if (arcadeMode && aiRoster.where((w) => w.canBeBooked).length < 8) {
      for (final wrestler in aiRoster.where((w) => !w.canBeBooked)) {
        wrestler.currentStamina = max(wrestler.currentStamina, 40);
      }
    }

    return aiRoster.where((w) => w.canBeBooked).toList()
      ..sort((a, b) => (b.popularity + b.inRing).compareTo(a.popularity + a.inRing));
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
    final restBookings = rests.where((r) => r != null).map((r) => r!).toList();
    final restNames = restBookings.map((r) => r.wrestler.name).toSet();

    for (final rest in restBookings) {
      rest.wrestler.currentStamina = min(
        rest.wrestler.stamina,
        rest.wrestler.currentStamina + rest.recoveryAmount,
      );
      rest.wrestler.matchesThisWeek = 0;
    }

    for (final w in playerRoster) {
      if (restNames.contains(w.name)) {
        continue;
      }
      if (!matchBookedNames.contains(w.name) && !promoNames.contains(w.name)) {
        _engine.recoverStamina(w, benchedThisWeek: true);
      }
      w.matchesThisWeek = 0;
    }

    for (final w in aiRoster) {
      w.currentStamina = min(w.stamina, w.currentStamina + (arcadeMode ? 10 : 5));
      w.matchesThisWeek = 0;
    }

    currentWeek++;
    card = [null, null, null, null];
    promos = [null, null];
    rests = [null, null];
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
    final rawDrain = _engine.staminaDrain(position, matchType, won);
    final adjustedDrain = arcadeMode ? (rawDrain * 0.75).round() : rawDrain;
    wrestler.currentStamina =
        (wrestler.currentStamina - adjustedDrain).clamp(0, wrestler.stamina);
    wrestler.matchesThisWeek++;
  }

  int _bookingScore(Wrestler wrestler) {
    return (wrestler.popularity * 2) + wrestler.inRing + wrestler.charisma + wrestler.momentum;
  }

  int _autoBookScore(Wrestler wrestler) {
    return _bookingScore(wrestler) + (wrestler.currentStamina * 3);
  }

  void _ensureAutoBookAvailability() {
    int safety = 0;
    final maxLoops = arcadeMode ? 5 : 3;
    while (playerRoster.where((w) => w.canBeBooked).length < 8 && safety < maxLoops) {
      for (final wrestler in playerRoster.where((w) => !w.canBeBooked)) {
        _engine.recoverStamina(wrestler, benchedThisWeek: true);
      }
      safety++;
    }

    if (arcadeMode && playerRoster.where((w) => w.canBeBooked).length < 8) {
      for (final wrestler in playerRoster.where((w) => !w.canBeBooked)) {
        wrestler.currentStamina = max(wrestler.currentStamina, 40);
      }
    }
  }

  void _recoverRosterForAutoPlay() {
    for (final wrestler in playerRoster) {
      _engine.recoverStamina(wrestler, benchedThisWeek: true);
      wrestler.matchesThisWeek = 0;
    }
    for (final wrestler in aiRoster) {
      _engine.recoverStamina(wrestler, benchedThisWeek: true);
      wrestler.matchesThisWeek = 0;
    }
    card = [null, null, null, null];
    promos = [null, null];
    rests = [null, null];
    weekResults = [];
    aiWeekResults = [];
    weekSimulated = false;
  }
}
