import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/draftAI.dart';

class DraftViewModel extends ChangeNotifier {
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
  bool get showEndButton => canEndDraft && isMyTurn && !draftComplete;

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
    notifyListeners();
  }

  void _checkDraftEnd() {
    bool poolEmpty = pool.isEmpty;
    bool cantAfford = pool.every(
        (w) => w.salary > myBudget && w.salary > aiBudget);
    if (poolEmpty || cantAfford) {
      draftComplete = true;
      notifyListeners();
    }
  }

  void autoDraft() {
    restartDraft();
    final shuffled = List<Wrestler>.from(pool)..shuffle();

    for (final w in shuffled) {
      if (myRoster.length >= minRosterSize && aiRoster.length >= minRosterSize) break;
      if (myRoster.length < minRosterSize && w.salary <= myBudget) {
        myRoster.add(w);
        pool.remove(w);
        myBudget -= w.salary;
      } else if (aiRoster.length < minRosterSize && w.salary <= aiBudget) {
        aiRoster.add(w);
        pool.remove(w);
        aiBudget -= w.salary;
      }
    }

    draftComplete = true;
    lastPickMessage = 'Auto draft complete!';
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
    notifyListeners();
  }
}