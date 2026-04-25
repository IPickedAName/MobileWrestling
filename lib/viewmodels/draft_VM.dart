import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/draftAI.dart';

class DraftViewModel extends ChangeNotifier {
  static const String universalTitle = 'Universal Champion';
  static const String intercontinentalTitle = 'Intercontinental Champion';

  List<Wrestler> pool;
  final List<Wrestler> _fullPool;
  final int startingBudget;

  List<Wrestler> myRoster = [];
  List<Wrestler> aiRoster = [];
  int myBudget;
  int aiBudget;
  bool isMyTurn = true;
  int pickNumber = 1;
  bool draftComplete = false;
  String lastPickMessage = '';

  static const int minRosterSize = 10;
  final DraftAI _ai = DraftAI();

  DraftViewModel({required List<Wrestler> pool, required this.startingBudget})
      : pool = List.from(pool),
        _fullPool = List.from(pool),
        myBudget = startingBudget,
        aiBudget = startingBudget;

  bool canAfford(Wrestler w) => w.salary <= myBudget;
  bool get canEndDraft => myRoster.length >= minRosterSize;
  bool get showEndButton => canEndDraft && !draftComplete;

  static String toM(int val) {
    if (val >= 1000) {
      return '\$${(val / 1000).toStringAsFixed(1)}M';
    } else {
      return '\$${val}k';
    }
  }

  String get myBudgetDisplay => toM(myBudget);
  String get aiBudgetDisplay => toM(aiBudget);

  void playerPicks(Wrestler w) {
    if (!isMyTurn || !canAfford(w) || draftComplete) return;
    myRoster.add(w);
    pool.remove(w);
    myBudget -= w.salary;
    pickNumber++;
    isMyTurn = false;
    lastPickMessage = 'You picked ${w.name}';
    notifyListeners();
    _checkDraftEnd();
    if (!draftComplete) {
      Future.delayed(const Duration(milliseconds: 1400), () => _aiPicks());
    }
  }

  void _aiPicks() {
    if (pool.isEmpty || draftComplete) return;
    if (aiRoster.length >= minRosterSize && pool.length <= 5) {
      draftComplete = true;
      _assignChampionsAfterDraft();
      lastPickMessage = 'AI ended the draft';
      notifyListeners();
      return;
    }
    Wrestler pick = _ai.pickWrestler(pool, myRoster, aiBudget);
    aiRoster.add(pick);
    pool.remove(pick);
    aiBudget -= pick.salary;
    pickNumber++;
    isMyTurn = true;
    lastPickMessage = 'AI picked ${pick.name}';
    notifyListeners();
    _checkDraftEnd();
  }

  void playerEndsDraft() {
    if (!canEndDraft) return;
    draftComplete = true;
    _assignChampionsAfterDraft();
    lastPickMessage = 'Draft locked. Champions assigned.';
    notifyListeners();
  }

  void _checkDraftEnd() {
    bool poolEmpty = pool.isEmpty;
    bool cantAfford = pool.every(
        (w) => w.salary > myBudget && w.salary > aiBudget);
    if (poolEmpty || cantAfford) {
      draftComplete = true;
      _assignChampionsAfterDraft();
      notifyListeners();
    }
  }

  void autoDraft() {
    if (draftComplete) return;

    // Auto-fill only the user's roster target and keep draft open for edits/manual picks.
    int safety = 0;
    while (myRoster.length < minRosterSize && pool.isNotEmpty && safety < 250) {
      safety++;

      if (isMyTurn) {
        final affordable = pool.where((w) => w.salary <= myBudget).toList();
        if (affordable.isEmpty) break;
        affordable.sort((a, b) {
          final aScore = a.popularity + a.inRing + a.charisma;
          final bScore = b.popularity + b.inRing + b.charisma;
          return bScore.compareTo(aScore);
        });
        final pick = affordable.first;
        myRoster.add(pick);
        pool.remove(pick);
        myBudget -= pick.salary;
        pickNumber++;
        isMyTurn = false;
      } else {
        final aiAffordable = pool.where((w) => w.salary <= aiBudget).toList();
        if (aiAffordable.isEmpty) {
          isMyTurn = true;
          continue;
        }
        final pick = _ai.pickWrestler(pool, myRoster, aiBudget);
        aiRoster.add(pick);
        pool.remove(pick);
        aiBudget -= pick.salary;
        pickNumber++;
        isMyTurn = true;
      }
    }

    lastPickMessage =
        myRoster.length >= minRosterSize
            ? 'Auto-fill complete. Review roster, then end draft when ready.'
            : 'Auto-fill stopped: not enough budget/picks left.';
    // Always return control to player so draft can be reviewed/locked immediately.
    isMyTurn = true;
    notifyListeners();
  }

  void restartDraft() {
    pool = List.from(_fullPool);
    myRoster = [];
    aiRoster = [];
    myBudget = startingBudget;
    aiBudget = startingBudget;
    isMyTurn = true;
    pickNumber = 1;
    draftComplete = false;
    lastPickMessage = '';
    _clearChampionships(pool);
    notifyListeners();
  }

  void _assignChampionsAfterDraft() {
    _assignChampionsForRoster(myRoster);
    _assignChampionsForRoster(aiRoster);
  }

  void _assignChampionsForRoster(List<Wrestler> roster) {
    _clearChampionships(roster);
    if (roster.isEmpty) return;

    final sorted = List<Wrestler>.from(roster)
      ..sort((a, b) {
        final aScore = (a.popularity * 2) + a.inRing + a.charisma;
        final bScore = (b.popularity * 2) + b.inRing + b.charisma;
        return bScore.compareTo(aScore);
      });

    sorted.first.championshipTitle = universalTitle;
    if (sorted.length > 1) {
      sorted[1].championshipTitle = intercontinentalTitle;
    }
  }

  void _clearChampionships(List<Wrestler> wrestlers) {
    for (final w in wrestlers) {
      w.championshipTitle = null;
    }
  }
}