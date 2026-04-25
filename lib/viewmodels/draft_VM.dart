import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/draft_picker.dart';
import 'simVM.dart';

enum GameMode { standard, arcade }

class DraftViewModel extends ChangeNotifier {
  static const String universalTitle = 'Universal Champion';
  static const String intercontinentalTitle = 'Intercontinental Champion';

  // Budget presets in thousands ($5M, $13M, $15M)
  static const List<int> budgetPresets = [5000, 13000, 15000];
  static const List<String> budgetPresetLabels = ['\$5M  Tight', '\$13M  Balanced', '\$15M  Premium'];

  List<Wrestler> pool;
  final List<Wrestler> _fullPool;
  int startingBudget;

  List<Wrestler> myRoster = [];
  List<Wrestler> aiRoster = [];
  int myBudget;
  int aiBudget;
  bool isMyTurn = true;
  int pickNumber = 1;
  bool draftComplete = false;
  bool playerChampionsChosen = false;
  String lastPickMessage = '';
  bool _seasonCashInitialized = false;
  int seasonCash = 0;
  int _lastFinanceWeekApplied = 0;
  GameMode _gameMode = GameMode.standard;

  static const int minRosterSize = 10;
  final DraftPicker _ai = DraftPicker();

  DraftViewModel({required List<Wrestler> pool, required this.startingBudget})
      : pool = List.from(pool),
        _fullPool = List.from(pool),
        myBudget = startingBudget,
        aiBudget = startingBudget;

  bool canAfford(Wrestler w) => w.salary <= myBudget;
  bool get canEndDraft => myRoster.length >= minRosterSize;
  bool get showEndButton => canEndDraft && !draftComplete;
  List<Wrestler> get freeAgents => List.unmodifiable(pool);
  String get seasonCashDisplay => toM(seasonCash);
  GameMode get gameMode => _gameMode;
  bool get isArcadeMode => _gameMode == GameMode.arcade;
  String get gameModeLabel => isArcadeMode ? 'Arcade' : 'Standard';

  void setGameMode(GameMode mode) {
    if (_gameMode == mode) return;
    _gameMode = mode;
    notifyListeners();
  }

  /// Change starting budget before any picks are made.
  void setBudgetPreset(int budget) {
    if (myRoster.isNotEmpty || draftComplete) return;
    startingBudget = budget;
    myBudget = budget;
    aiBudget = budget;
    notifyListeners();
  }

  /// Cost to book this match type (in thousands). Singles = free.
  int matchCostFor(String matchType) {
    switch (matchType) {
      case 'Championship':
        return (startingBudget * 0.01).round();   // 1% of budget
      case 'Tag Team':
        return (startingBudget * 0.005).round();  // 0.5% of budget
      default:
        return 0;
    }
  }

  /// Total cost for a full card (null slots ignored).
  int cardTotalCost(List<MatchBooking?> card) =>
      card.whereType<MatchBooking>().fold(0, (s, m) => s + matchCostFor(m.matchType));

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
      _initializeSeasonCashIfNeeded();
      lastPickMessage = 'AI ended the draft. Choose your champions next.';
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
    _initializeSeasonCashIfNeeded();
    lastPickMessage = 'Draft locked. Choose your champions next.';
    notifyListeners();
  }

  void _checkDraftEnd() {
    bool poolEmpty = pool.isEmpty;
    bool cantAfford = pool.every(
        (w) => w.salary > myBudget && w.salary > aiBudget);
    if (poolEmpty || cantAfford) {
      draftComplete = true;
      _initializeSeasonCashIfNeeded();
      lastPickMessage = 'Draft complete. Choose your champions next.';
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
    playerChampionsChosen = false;
    _seasonCashInitialized = false;
    seasonCash = 0;
    _lastFinanceWeekApplied = 0;
    lastPickMessage = '';
    _clearChampionships(_fullPool);
    notifyListeners();
  }

  bool get needsChampionSelection => draftComplete && !playerChampionsChosen;

  void applyWeeklyFinance({
    required int week,
    required int playerPoints,
    required int aiPoints,
    required double avgRating,
    int matchRevenue = 0,
    int cardCost = 0,
  }) {
    if (week <= _lastFinanceWeekApplied) return;

    int delta;
    if (isArcadeMode) {
      delta = 420;
      delta += (playerPoints - aiPoints) * 3;
      if (avgRating >= 4.25) {
        delta += 260;
      } else if (avgRating >= 3.75) {
        delta += 170;
      } else if (avgRating < 2.75) {
        delta -= 70;
      }
    } else {
      delta = 250;
      delta += (playerPoints - aiPoints) * 2;
      if (avgRating >= 4.25) {
        delta += 220;
      } else if (avgRating >= 3.75) {
        delta += 120;
      } else if (avgRating < 2.75) {
        delta -= 120;
      }
    }
    delta += matchRevenue;
    delta -= cardCost;

    seasonCash = (seasonCash + delta).clamp(0, 999999);
    _lastFinanceWeekApplied = week;
    notifyListeners();
  }

  void assignChampions({
    required Wrestler universalChampion,
    required Wrestler intercontinentalChampion,
  }) {
    if (universalChampion.name == intercontinentalChampion.name) return;

    _clearChampionships(_fullPool);
    universalChampion.championshipTitle = universalTitle;
    intercontinentalChampion.championshipTitle = intercontinentalTitle;
    playerChampionsChosen = true;
    _initializeSeasonCashIfNeeded();
    _assignChampionsForRoster(aiRoster);
    notifyListeners();
  }

  void _initializeSeasonCashIfNeeded() {
    if (_seasonCashInitialized) return;
    final seedBonus = isArcadeMode ? 1200 : 0;
    seasonCash = (myBudget + seedBonus).clamp(0, 999999);
    _seasonCashInitialized = true;
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