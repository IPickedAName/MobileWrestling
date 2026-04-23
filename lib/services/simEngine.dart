import 'dart:math';
import '../models/wrestler.dart';

class SimulationEngine {
  final Random _rng = Random();

  // CLASS MATCHUP BONUS
  double _classBonus(String w1Class, String w2Class) {
    const counters = {
      'Giant': 'Cruiser',
      'Cruiser': 'Bruiser',
      'Bruiser': 'Fighter',
      'Fighter': 'Giant',
    };
    if (counters[w1Class] == w2Class) return 0.30;
    if (counters[w2Class] == w1Class) return 0.30;
    if (w1Class == 'Technician' || w2Class == 'Technician') return 0.20;
    if (w1Class == w2Class) return 0.10;
    return 0.0;
  }

  // MATCH TYPE BONUS + FLOOR
  double _typeBonus(String matchType) {
    switch (matchType) {
      case 'Championship': return 0.35;
      case 'Tag Team':     return -0.25;
      default:             return 0.0;
    }
  }

  double _typeFloor(String matchType) {
    switch (matchType) {
      case 'Championship': return 2.5;
      default:             return 1.5;
    }
  }

  // FEUD BONUS
  double _feudBonus(int encounters) {
    if (encounters == 0) return 0.0;
    if (encounters == 1) return 0.15;
    if (encounters == 2) return 0.30;
    if (encounters == 3) return 0.40;
    return max(-0.25, 0.40 - ((encounters - 3) * 0.15));
  }

  // STAMINA DRAIN
  int staminaDrain(String cardPosition, String matchType, bool won) {
    int base = 0;
    switch (cardPosition) {
      case 'Opener':     base = 8;  break;
      case 'Midcard':    base = 10; break;
      case 'Main Event': base = 14; break;
    }
    int typeExtra = matchType == 'Championship' ? 5 : matchType == 'Tag Team' ? -3 : 0;
    int lossExtra = won ? 0 : 2;
    return base + typeExtra + lossExtra;
  }

  // CORE RATING SIMULATION
  double simulateRating({
    required Wrestler w1,
    required Wrestler w2,
    required String matchType,
  }) {
    int encounters = w1.feudEncountersWith(w2.name);

    double w1Score = (w1.effectiveInRing * 0.5 + w1.charisma * 0.3 + w1.popularity * 0.2);
    double w2Score = (w2.effectiveInRing * 0.5 + w2.charisma * 0.3 + w2.popularity * 0.2);
    double workerScore = ((w1Score + w2Score) / 2) / 20;

    double synergy  = _classBonus(w1.wrestlerClass, w2.wrestlerClass);
    double typeBonus = _typeBonus(matchType);
    double feud     = _feudBonus(encounters);
    double momentum = (w1.momentum + w2.momentum) * 0.05;
    double noise    = ((_rng.nextDouble() + _rng.nextDouble()) / 2 - 0.5) * 0.75;

    double raw      = workerScore + synergy + typeBonus + feud + momentum + noise;
    double floor    = _typeFloor(matchType);
    double clamped  = raw.clamp(floor, 5.0);

    return (clamped * 4).round() / 4;
  }

  // WINNER DETERMINATION
  Wrestler determineWinner(Wrestler w1, Wrestler w2) {
    double total = (w1.popularity + w2.popularity).toDouble();
    double w1Chance = w1.popularity / total;
    double momentumShift = (w1.momentum - w2.momentum) * 0.02;
    double adjusted = (w1Chance + momentumShift).clamp(0.15, 0.85);
    return _rng.nextDouble() < adjusted ? w1 : w2;
  }

  // POINTS CALCULATION
  int calculatePoints({
    required double starRating,
    required bool correctPrediction,
    required bool wasUpset,
    required String cardPosition,
    required bool allMatchesBooked,
    double showAvgRating = 0.0,
  }) {
    int pts = 0;

    if      (starRating >= 5.0) pts += 60;
    else if (starRating >= 4.5) pts += 50;
    else if (starRating >= 4.0) pts += 40;
    else if (starRating >= 3.5) pts += 30;
    else if (starRating >= 3.0) pts += 20;
    else if (starRating >= 2.5) pts += 10;

    if (correctPrediction) pts += wasUpset ? 35 : 15;
    if (cardPosition == 'Main Event') pts += 10;
    if (cardPosition == 'Opener' && starRating >= 3.5) pts += 5;
    if (allMatchesBooked) pts += 10;
    if (showAvgRating >= 4.5) pts += 25;
    else if (showAvgRating >= 3.75) pts += 15;

    return pts;
  }

  // POPULARITY + MOMENTUM UPDATE
  void updateAfterMatch({
    required Wrestler wrestler,
    required bool won,
    required double starRating,
    required bool wasMainEvent,
  }) {
    int delta = 0;

    if      (starRating >= 4.5) delta += 5;
    else if (starRating >= 3.75) delta += 3;
    else if (starRating >= 3.0)  delta += 1;
    else if (starRating < 1.5)   delta -= 4;
    else if (starRating < 2.0)   delta -= 2;

    delta += won ? 2 : -1;
    if (wasMainEvent) delta += 2;
    if (wrestler.matchesThisWeek >= 2) delta -= (wrestler.matchesThisWeek - 1) * 2;

    wrestler.momentum = won
        ? min(5, wrestler.momentum + 1)
        : max(-5, wrestler.momentum - 1);

    wrestler.popularity = (wrestler.popularity + delta).clamp(1, 100);
    wrestler.matchesThisWeek = 0;
  }

  // STAMINA RECOVERY
  void recoverStamina(Wrestler wrestler, {bool benchedThisWeek = false, bool promoOnly = false}) {
    if (benchedThisWeek) {
      wrestler.currentStamina = min(wrestler.stamina, wrestler.currentStamina + 15);
    } else if (promoOnly) {
      wrestler.currentStamina = min(wrestler.stamina, wrestler.currentStamina + 8);
    }
    if (wrestler.popularity > 50) wrestler.popularity -= 1;
    if (wrestler.popularity < 50) wrestler.popularity += 1;
  }
}