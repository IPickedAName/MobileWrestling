import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wrestler.dart';
import '../viewmodels/simVM.dart';
import '../viewmodels/draft_VM.dart';
import 'appDrawer.dart';
import '../widgets/champion_badge.dart';
import '../firestore_service.dart';

String _nameWithChampionTag(Wrestler wrestler) {
  return wrestler.name;
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _showingChampionDialog = false;

  void _maybeHandleSeasonSetup(BuildContext context, SimViewModel sim, DraftViewModel draft) {
    if (sim.seasonStarted || !draft.draftComplete) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || sim.seasonStarted) return;

      if (draft.needsChampionSelection) {
        if (_showingChampionDialog) return;
        _showingChampionDialog = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _ChampionSelectionDialog(draft: draft),
        );
        _showingChampionDialog = false;
      }

      if (!mounted || sim.seasonStarted || draft.needsChampionSelection) return;
      sim.initSeason(draft.myRoster, draft.aiRoster);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SimViewModel, DraftViewModel>(
      builder: (context, sim, draft, _) {
        _maybeHandleSeasonSetup(context, sim, draft);

        if (!draft.draftComplete) {
          return _NoDraftScreen();
        }

        if (sim.seasonOver) {
          return _SeasonOverScreen(sim: sim);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Book Your Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Week ${sim.currentWeek} of ${sim.totalWeeks}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Auto book',
                onPressed: sim.seasonStarted && !sim.weekSimulated
                    ? () => sim.autoBookCard()
                    : null,
                icon: const Icon(Icons.auto_fix_high),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1A1A1A),
                onSelected: (value) {
                  switch (value) {
                    case 'autoWeek':
                      sim.autoFinishWeek();
                      if (sim.weekSimulated) {
                        Navigator.pushNamed(context, '/results');
                      }
                      break;
                    case 'skipSeason':
                      sim.autoPlayToSeasonEnd();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'autoWeek',
                    child: Text('Dev: Auto Finish Week',
                        style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'skipSeason',
                    child: Text('Dev: Skip To End Of Season',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              _ScoreBar(playerPts: sim.playerTotalPoints, aiPts: sim.aiTotalPoints),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (int i = 0; i < 4; i++)
                      _SlotCard(
                        index: i,
                        booking: sim.card[i],
                        position: SimViewModel.positions[i],
                        onTap: () => _openSheet(context, sim, i),
                        onClear: () => sim.clearSlot(i),
                      ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Text('PROMO SEGMENTS  —  OPTIONAL',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.4)),
                  ),
                  for (int i = 0; i < 2; i++)
                    _PromoSlotCard(
                      index: i,
                      wrestler: sim.promos[i]?.wrestler,
                      onTap: () => _openPromoSheet(context, sim, i),
                      onClear: () => sim.clearPromoSlot(i),
                    ),
                  ],
                ),
              ),
              _SimulateBar(sim: sim),
            ],
          ),
        );
      },
    );
  }

  void _openPromoSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.promos[index];
    if (existing != null) sim.clearPromoSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PromoSheet(sim: sim, slotIndex: index, initial: existing?.wrestler),
    ).then((_) {
      if (sim.promos[index] == null && existing != null) {
        sim.setPromoSlot(index, existing.wrestler);
      }
    });
  }

  void _openSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.card[index];
    if (existing != null) sim.clearSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingSheet(sim: sim, slotIndex: index, initial: existing),
    ).then((_) {
      // Restore old booking if user dismissed without confirming
      if (sim.card[index] == null && existing != null) {
        sim.setSlot(
          index,
          existing.w1,
          existing.w2,
          existing.matchType,
          existing.predictedWinner,
          w3: existing.w3,
          w4: existing.w4,
        );
      }
    });
  }
}

class _ChampionSelectionDialog extends StatefulWidget {
  final DraftViewModel draft;

  const _ChampionSelectionDialog({required this.draft});

  @override
  State<_ChampionSelectionDialog> createState() => _ChampionSelectionDialogState();
}

class _ChampionSelectionDialogState extends State<_ChampionSelectionDialog> {
  Wrestler? universalChampion;
  Wrestler? intercontinentalChampion;

  @override
  void initState() {
    super.initState();
    final ranked = List<Wrestler>.from(widget.draft.myRoster)
      ..sort((a, b) {
        final aScore = (a.popularity * 2) + a.inRing + a.charisma;
        final bScore = (b.popularity * 2) + b.inRing + b.charisma;
        return bScore.compareTo(aScore);
      });
    if (ranked.isNotEmpty) {
      universalChampion = ranked.first;
    }
    if (ranked.length > 1) {
      intercontinentalChampion = ranked[1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = widget.draft.myRoster;
    final canConfirm =
        universalChampion != null &&
        intercontinentalChampion != null &&
        universalChampion!.name != intercontinentalChampion!.name;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Assign Your Champions',
          style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose two wrestlers from your roster before booking your first show.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text('Universal Title',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Wrestler>(
              value: universalChampion,
              dropdownColor: const Color(0xFF2A2A2A),
              decoration: _champFieldDecoration(),
              items: roster
                  .map((w) => DropdownMenuItem<Wrestler>(
                        value: w,
                        child: Text(w.name,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => universalChampion = value),
            ),
            const SizedBox(height: 14),
            const Text('Intercontinental Title',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Wrestler>(
              value: intercontinentalChampion,
              dropdownColor: const Color(0xFF2A2A2A),
              decoration: _champFieldDecoration(),
              items: roster
                  .map((w) => DropdownMenuItem<Wrestler>(
                        value: w,
                        child: Text(w.name,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => intercontinentalChampion = value),
            ),
            if (universalChampion != null &&
                intercontinentalChampion != null &&
                universalChampion!.name == intercontinentalChampion!.name) ...[
              const SizedBox(height: 10),
              const Text(
                'Pick two different wrestlers.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: canConfirm
              ? () {
                  widget.draft.assignChampions(
                    universalChampion: universalChampion!,
                    intercontinentalChampion: intercontinentalChampion!,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Confirm',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  InputDecoration _champFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF111111),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCC0000)),
      ),
    );
  }
}

// ─── SCORE BAR ───────────────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  final int playerPts;
  final int aiPts;
  const _ScoreBar({required this.playerPts, required this.aiPts});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text('$playerPts',
                style: const TextStyle(
                    color: Color(0xFFCC0000), fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('YOU', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const Text('VS', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Column(children: [
            Text('$aiPts',
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('AI', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── SLOT CARD ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final int index;
  final MatchBooking? booking;
  final String position;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _SlotCard({
    required this.index,
    this.booking,
    required this.position,
    required this.onTap,
    required this.onClear,
  });

  Color get _posColor {
    switch (position) {
      case 'Main Event':
        return const Color(0xFFCC0000);
      case 'Opener':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _posColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _posColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(position.toUpperCase(),
                      style: TextStyle(
                          color: _posColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  if (booking != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: booking == null ? _EmptySlot() : _FilledSlot(booking: booking!),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_circle_outline, color: Colors.grey, size: 18),
        SizedBox(width: 8),
        Text('Add Match', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final MatchBooking booking;
  const _FilledSlot({required this.booking});

  Widget _nameCell(Wrestler wrestler, {TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment:
          align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _nameWithChampionTag(wrestler),
          textAlign: align,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        if (wrestler.isChampion) ...[
          const SizedBox(height: 2),
          ChampionBadge(label: wrestler.championshipTitle, compact: true),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: booking.isTagTeam
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameCell(booking.w1),
                        const SizedBox(height: 4),
                        _nameCell(booking.w2),
                      ],
                    )
                  : _nameCell(booking.w1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('VS', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            Expanded(
              child: booking.isTagTeam
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _nameCell(booking.w3!, align: TextAlign.right),
                        const SizedBox(height: 4),
                        _nameCell(booking.w4!, align: TextAlign.right),
                      ],
                    )
                  : _nameCell(booking.w2, align: TextAlign.right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Tag(booking.matchType),
            const SizedBox(width: 6),
            _Tag('Pick: ${_nameWithChampionTag(booking.predictedWinner)}',
                color: const Color(0xFF6B0000)),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, {this.color = const Color(0xFF2C2C2C)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

// ─── SIMULATE BAR ─────────────────────────────────────────────────────────────

class _SimulateBar extends StatelessWidget {
  final SimViewModel sim;
  const _SimulateBar({required this.sim});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text('${sim.slotsBooked}/4 booked',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          OutlinedButton(
            onPressed: sim.seasonStarted && !sim.weekSimulated
                ? () => sim.autoBookCard()
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('AUTO BOOK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: sim.cardFull
    ? () async {
        sim.simulateWeek();

        if (sim.history.isNotEmpty) {
          final summary = sim.history.last;

          await FirestoreService().recordWeeklyStats(
            weekNumber: sim.currentWeek,
            playerPoints: summary.playerPoints,
            aiPoints: summary.aiPoints,
            avgRating: summary.avgRating,
          );
        }

        if (context.mounted) {
          Navigator.pushNamed(context, '/results');
        }
      }
    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: sim.cardFull ? const Color(0xFFCC0000) : Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SIMULATE WEEK',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── FALLBACK SCREENS ─────────────────────────────────────────────────────────

class _NoDraftScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Book Your Card')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey, size: 52),
            const SizedBox(height: 16),
            const Text('Complete the draft first',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/draft'),
              child: const Text('GO TO DRAFT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonOverScreen extends StatelessWidget {
  final SimViewModel sim;
  const _SeasonOverScreen({required this.sim});

  @override
  Widget build(BuildContext context) {
    final playerWon = sim.playerTotalPoints >= sim.aiTotalPoints;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Season Over')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              playerWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: playerWon ? Colors.amber : Colors.grey,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              playerWon ? 'YOU WIN THE SEASON!' : 'AI WINS THE SEASON',
              style: TextStyle(
                color: playerWon ? const Color(0xFFCC0000) : Colors.grey,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            Text('You  ${sim.playerTotalPoints} pts',
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 6),
            Text('AI   ${sim.aiTotalPoints} pts',
                style: const TextStyle(color: Colors.grey, fontSize: 20)),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false),
              child: const Text('BACK TO HOME'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOOKING SHEET ────────────────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final MatchBooking? initial;

  const _BookingSheet({required this.sim, required this.slotIndex, this.initial});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  Wrestler? w1;
  Wrestler? w2;
  Wrestler? w3;
  Wrestler? w4;
  String matchType = 'Singles';
  Wrestler? predicted;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      w1 = widget.initial!.w1;
      w2 = widget.initial!.w2;
      w3 = widget.initial!.w3;
      w4 = widget.initial!.w4;
      matchType = widget.initial!.matchType;
      predicted = widget.initial!.predictedWinner;
    } else if (matchType == 'Championship') {
      _preloadChampionshipMatch();
    }
  }

  List<Wrestler> get _available => widget.sim.availableWrestlers;
  bool get _isTagTeam => matchType == 'Tag Team';
  int get _requiredCount => _isTagTeam ? 4 : 2;

  List<Wrestler> get _selected {
    final list = <Wrestler>[];
    if (w1 != null) list.add(w1!);
    if (w2 != null) list.add(w2!);
    if (w3 != null) list.add(w3!);
    if (w4 != null) list.add(w4!);
    return list;
  }

  bool get _canConfirm {
    if (_selected.length != _requiredCount || predicted == null) return false;
    if (_isTagTeam) {
      return predicted!.name == w1?.name || predicted!.name == w3?.name;
    }
    return predicted!.name == w1?.name || predicted!.name == w2?.name;
  }

  void _setSelectionFromList(List<Wrestler> picks) {
    w1 = picks.isNotEmpty ? picks[0] : null;
    w2 = picks.length > 1 ? picks[1] : null;
    w3 = picks.length > 2 ? picks[2] : null;
    w4 = picks.length > 3 ? picks[3] : null;
  }

  void _autoPickPrediction() {
    if (_isTagTeam) {
      if (w1 != null && w3 != null) {
        predicted = w1!.popularity >= w3!.popularity ? w1 : w3;
      } else {
        predicted = null;
      }
      return;
    }

    if (w1 != null && w2 != null) {
      predicted = w1!.popularity >= w2!.popularity ? w1 : w2;
    } else {
      predicted = null;
    }
  }

  void _onMatchTypeChanged(String nextType) {
    if (nextType == matchType) return;
    setState(() {
      matchType = nextType;
      if (matchType == 'Championship') {
        _preloadChampionshipMatch();
        return;
      }
      if (!_isTagTeam) {
        w3 = null;
        w4 = null;
        if (predicted != null && predicted!.name != w1?.name && predicted!.name != w2?.name) {
          predicted = null;
        }
      }
      _autoPickPrediction();
    });
  }

  void _preloadChampionshipMatch() {
    final available = _available;
    final champions = available.where((w) => w.isChampion).toList()
      ..sort((a, b) {
        int rank(String? t) {
          if (t == DraftViewModel.universalTitle) return 0;
          if (t == DraftViewModel.intercontinentalTitle) return 1;
          return 2;
        }

        final r = rank(a.championshipTitle).compareTo(rank(b.championshipTitle));
        if (r != 0) return r;
        return b.popularity.compareTo(a.popularity);
      });

    if (champions.isEmpty) return;

    final champion = champions.first;
    final contenders = available.where((w) => w.name != champion.name).toList()
      ..sort((a, b) {
        final aScore = a.popularity + a.inRing + a.charisma;
        final bScore = b.popularity + b.inRing + b.charisma;
        return bScore.compareTo(aScore);
      });

    w1 = champion;
    w2 = contenders.isNotEmpty ? contenders.first : null;
    w3 = null;
    w4 = null;
    _autoPickPrediction();
  }

  void _selectWrestler(Wrestler w) {
    setState(() {
      final picks = List<Wrestler>.from(_selected);
      final existingIndex = picks.indexWhere((p) => p.name == w.name);
      if (existingIndex >= 0) {
        picks.removeAt(existingIndex);
      } else if (picks.length < _requiredCount) {
        picks.add(w);
      }

      _setSelectionFromList(picks);
      _autoPickPrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = SimViewModel.positions[widget.slotIndex];
    final available = _available;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(position.toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFFCC0000),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5)),
                    const Spacer(),
                    Text(
                      '${_selected.length} / $_requiredCount selected',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Match type selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['Singles', 'Championship', 'Tag Team'].map((t) {
                    final sel = matchType == t;
                    return GestureDetector(
                      onTap: () => _onMatchTypeChanged(t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFCC0000) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.grey, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Predict winner
              if (!_isTagTeam && w1 != null && w2 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Predict: ',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      for (final w in [w1!, w2!])
                        GestureDetector(
                          onTap: () => setState(() => predicted = w),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: predicted?.name == w.name
                                  ? const Color(0xFFCC0000)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: predicted?.name == w.name
                                    ? const Color(0xFFCC0000)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(w.name.split(' ').first,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              if (_isTagTeam && w1 != null && w2 != null && w3 != null && w4 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Predict team: ',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      for (final leader in [w1!, w3!])
                        GestureDetector(
                          onTap: () => setState(() => predicted = leader),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: predicted?.name == leader.name
                                  ? const Color(0xFFCC0000)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              leader.name == w1!.name
                                  ? '${w1!.name.split(' ').first} & ${w2?.name.split(' ').first ?? ''}'
                                  : '${w3!.name.split(' ').first} & ${w4?.name.split(' ').first ?? ''}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
              // Wrestler list
              Expanded(
                child: available.isEmpty
                    ? const Center(
                        child: Text('No wrestlers available',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: available.length,
                        itemBuilder: (ctx, i) {
                          final w = available[i];
                          final selectedIndex = _selected.indexWhere((s) => s.name == w.name);
                          final isSelected = selectedIndex >= 0;
                          return ListTile(
                            onTap: () => _selectWrestler(w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          tileColor: isSelected
                            ? const Color(0xFFCC0000).withValues(alpha: 0.12)
                            : null,
                          title: Text(_nameWithChampionTag(w),
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(
                              '${w.wrestlerClass}  ·  Ring ${w.inRing}  ·  Pop ${w.popularity}  ·  STA ${w.currentStamina}/${w.stamina}',
                              style:
                                  const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            trailing: isSelected
                                ? _CircleBadge('${selectedIndex + 1}', const Color(0xFFCC0000))
                                : null,
                          );
                        },
                      ),
              ),
              // Confirm button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canConfirm
                        ? () {
                            widget.sim.setSlot(
                              widget.slotIndex,
                              w1!,
                              w2!,
                              matchType,
                              predicted!,
                              w3: w3,
                              w4: w4,
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canConfirm ? const Color(0xFFCC0000) : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('CONFIRM MATCH',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── PROMO SLOT CARD ─────────────────────────────────────────────────────────

class _PromoSlotCard extends StatelessWidget {
  final int index;
  final Wrestler? wrestler;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PromoSlotCard({
    required this.index,
    this.wrestler,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text('PROMO SEGMENT ${index + 1}',
                      style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  const Text('OPTIONAL',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  if (wrestler != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: wrestler == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.mic_none, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('Assign Promo (Optional)',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.purple, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(wrestler!.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        _Tag(
                          'Promo ${wrestler!.promoSkill}★',
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROMO SHEET ─────────────────────────────────────────────────────────────

class _PromoSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final Wrestler? initial;

  const _PromoSheet({required this.sim, required this.slotIndex, this.initial});

  @override
  State<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends State<_PromoSheet> {
  Wrestler? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.sim.availableWrestlers;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('PROMO SEGMENT',
                        style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5)),
                    const Spacer(),
                    const Text('Pick one wrestler',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No points scored. Recovers stamina and boosts popularity based on promo skill.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
              Expanded(
                child: available.isEmpty
                    ? const Center(
                        child: Text('No wrestlers available',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: available.length,
                        itemBuilder: (ctx, i) {
                          final w = available[i];
                          final isSel = w.name == selected?.name;
                          final staGain = w.promoSkill * 4;
                          final popGain = w.promoSkill;
                          return ListTile(
                            onTap: () =>
                                setState(() => selected = isSel ? null : w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tileColor: isSel
                                ? Colors.purple.withValues(alpha: 0.12)
                                : null,
                            title: Text(w.name,
                                style: TextStyle(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(
                              'Promo ${w.promoSkill}★  ·  STA ${w.currentStamina}/${w.stamina}  ·  Pop ${w.popularity}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                            trailing: isSel
                                ? const Icon(Icons.check_circle,
                                    color: Colors.purple)
                                : Text('+${staGain}STA  +${popGain}Pop',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected != null
                        ? () {
                            widget.sim.setPromoSlot(widget.slotIndex, selected!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selected != null ? Colors.purple : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ASSIGN PROMO',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CircleBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
