import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wrestler.dart';
import '../viewmodels/simVM.dart';
import '../viewmodels/draft_VM.dart';
import 'appDrawer.dart';
import '../widgets/champion_badge.dart';
import '../firestore_service.dart';
import '../theme/game_theme.dart';

String _nameWithChampionTag(Wrestler wrestler) {
  return wrestler.name;
}

Color _staminaColor(int stamina) {
  if (stamina >= 75) return const Color(0xFF4ade80);
  if (stamina >= 50) return const Color(0xFFfacc15);
  if (stamina >= 25) return const Color(0xFFfb923c);
  return const Color(0xFFef4444);
}

String _staminaLabel(int stamina) {
  if (stamina >= 75) return 'Fresh';
  if (stamina >= 50) return 'Manage';
  if (stamina >= 25) return 'Risk';
  return 'Exhausted';
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _showingChampionDialog = false;
  final bool _creatingSeason = false;
  static const Color _aewGold = Color(0xFFD4AF37);

  Future<String?> _askForTeamName(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Name Your Team',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Example: Nightmare',
              hintStyle: TextStyle(color: Colors.white38),
              labelText: 'Team Name',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  String _formatTeamName(String name) {
    final now = DateTime.now();
    return 'Team "$name" ${now.month}/${now.day}';
  }

  void _maybeHandleSeasonSetup(
  BuildContext context,
  SimViewModel sim,
  DraftViewModel draft,
) {
  if (sim.seasonStarted || !draft.draftComplete) return;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted || sim.seasonStarted) return;

    if (draft.needsChampionSelection) {
      if (_showingChampionDialog) return;

      _showingChampionDialog = true;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ChampionSelectionDialog(
          draft: draft,
          sim: sim,
        ),
      );

      _showingChampionDialog = false;
    }
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

if (!sim.seasonStarted && !draft.needsChampionSelection) {
  return _TeamNameStartScreen(
    sim: sim,
    draft: draft,
  );
}

if (sim.seasonOver) {
  return _SeasonOverScreen(sim: sim, draft: draft);
}


        return Scaffold(
          backgroundColor: GameTheme.bg,
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Book Your Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _aewGold)),
                Text('Week ${sim.currentWeek} of ${sim.totalWeeks}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE6D7A3))),
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
                onSelected: (value) async {
                  switch (value) {
                    case 'autoWeek':
                      final historyBefore = sim.history.length;
                      sim.autoFinishWeek();
                      if (sim.history.length > historyBefore) {
                        final summary = sim.history.last;
                        draft.applyWeeklyFinance(
                          week: summary.week,
                          playerPoints: summary.playerPoints,
                          aiPoints: summary.aiPoints,
                          avgRating: summary.avgRating,
                          matchRevenue: summary.matchRevenue,
                          cardCost: summary.cardCost,
                        );
                        try {
                          await FirestoreService().recordWeeklyStats(
                            weekNumber: summary.week,
                            playerPoints: summary.playerPoints,
                            aiPoints: summary.aiPoints,
                            avgRating: summary.avgRating,
                          );
                        } catch (_) {
                          // Local simulation still works without Firebase sync.
                        }
                      }
                      if (sim.weekSimulated && context.mounted) {
                        Navigator.pushNamed(context, '/results');
                      }
                      break;
                    case 'skipSeason':
                      final historyBefore = sim.history.length;
                      sim.autoPlayToSeasonEnd();
                      for (int i = historyBefore; i < sim.history.length; i++) {
                        final summary = sim.history[i];
                        draft.applyWeeklyFinance(
                          week: summary.week,
                          playerPoints: summary.playerPoints,
                          aiPoints: summary.aiPoints,
                          avgRating: summary.avgRating,
                          matchRevenue: summary.matchRevenue,
                          cardCost: summary.cardCost,
                        );
                      }
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
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF131A29), Color(0xFF0F1422)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roster: ${sim.playerRoster.length} total  •  ${sim.availableWrestlers.length} available this week',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cash: ${draft.seasonCashDisplay}',
                      style: const TextStyle(
                        color: Color(0xFF4ade80),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${draft.gameModeLabel}',
                      style: TextStyle(
                        color: draft.isArcadeMode
                            ? const Color(0xFFfacc15)
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sim.playerRoster.where((w) => w.currentStamina < 50).length} wrestlers below 50 stamina. Use promo or rest slots to recover.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (int i = 0; i < 4; i++)
                      _SlotCard(
                        index: i,
                        booking: sim.card[i],
                        position: SimViewModel.positions[i],
                        cost: draft.matchCostFor(sim.card[i]?.matchType ?? ''),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Text('REST SLOTS  —  RECOVERY',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.4)),
                  ),
                  for (int i = 0; i < 2; i++)
                    _RestSlotCard(
                      index: i,
                      booking: sim.rests[i],
                      onTap: () => _openRestSheet(context, sim, i),
                      onClear: () => sim.clearRestSlot(i),
                    ),
                  ],
                ),
              ),
              _SimulateBar(sim: sim, draft: draft),
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

  void _openRestSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.rests[index];
    if (existing != null) sim.clearRestSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RestSheet(sim: sim, slotIndex: index, initial: existing?.wrestler),
    ).then((_) {
      if (sim.rests[index] == null && existing != null) {
        sim.setRestSlot(index, existing.wrestler, recoveryAmount: existing.recoveryAmount);
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
  final SimViewModel sim;

  const _ChampionSelectionDialog({required this.draft, required this.sim});

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
  child: SingleChildScrollView(
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
              initialValue: universalChampion,
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
              initialValue: intercontinentalChampion,
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
          child: const Text(
            'Confirm',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
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
      color: GameTheme.panel,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text('$playerPts',
                style: const TextStyle(
                    color: Color(0xFFE11D48), fontSize: 22, fontWeight: FontWeight.bold)),
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
  final int cost;

  const _SlotCard({
    required this.index,
    this.booking,
    required this.position,
    required this.onTap,
    required this.onClear,
    this.cost = 0,
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
          color: GameTheme.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _posColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _posColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
                  if (booking != null && cost > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C2D12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '- ${DraftViewModel.toM(cost)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

// ─── SIMULATE BAR ─────────────────────────────────────────────────────────────

class _SimulateBar extends StatefulWidget {
  final SimViewModel sim;
  final DraftViewModel draft;
  const _SimulateBar({required this.sim, required this.draft});

  @override
  State<_SimulateBar> createState() => _SimulateBarState();
}

class _SimulateBarState extends State<_SimulateBar> {
  bool isSaving = false;

  Future<void> _simulateAndSave(BuildContext context) async {
    if (!widget.sim.cardFull || isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      widget.sim.simulateWeek();

      if (widget.sim.history.isNotEmpty) {
        final summary = widget.sim.history.last;
        widget.draft.applyWeeklyFinance(
          week: summary.week,
          playerPoints: summary.playerPoints,
          aiPoints: summary.aiPoints,
          avgRating: summary.avgRating,
          matchRevenue: summary.matchRevenue,
          cardCost: summary.cardCost,
        );

        try {
          await FirestoreService().recordWeeklyStats(
            weekNumber: summary.week,
            playerPoints: summary.playerPoints,
            aiPoints: summary.aiPoints,
            avgRating: summary.avgRating,
          );
        } catch (_) {
          // Local simulation still works without Firebase sync.
        }
      }

      if (context.mounted) {
        Navigator.pushNamed(context, '/results');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save weekly stats: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sim = widget.sim;
    final draft = widget.draft;

    return Container(
      color: GameTheme.panel,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${sim.slotsBooked}/4 booked',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Builder(builder: (context) {
                final totalCost = draft.cardTotalCost(sim.card);
                return totalCost > 0
                    ? Text('Card cost: -${DraftViewModel.toM(totalCost)}',
                        style: const TextStyle(color: Color(0xFFfb923c), fontSize: 11, fontWeight: FontWeight.w600))
                    : const SizedBox.shrink();
              }),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: sim.seasonStarted && !sim.weekSimulated && !isSaving
                ? () => sim.autoBookCard()
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text(
              'AUTO BOOK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: sim.cardFull && !isSaving
                ? () => _simulateAndSave(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  sim.cardFull ? const Color(0xFFCC0000) : Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SIMULATE WEEK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
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
      drawer: const AppDrawer(),
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
class _TeamNameStartScreen extends StatefulWidget {
  final SimViewModel sim;
  final DraftViewModel draft;

  const _TeamNameStartScreen({
    required this.sim,
    required this.draft,
  });

  @override
  State<_TeamNameStartScreen> createState() => _TeamNameStartScreenState();
}

class _TeamNameStartScreenState extends State<_TeamNameStartScreen> {
  final TextEditingController teamNameController = TextEditingController();
  bool isStarting = false;
  bool saveFailed = false;
  String? lastSaveError;

  String _formatTeamName(String name) {
    final now = DateTime.now();
    return 'Team "$name" ${now.month}/${now.day}';
  }

  void _startLocally() {
    widget.sim.initSeason(
      widget.draft.myRoster,
      widget.draft.aiRoster,
      arcadeMode: widget.draft.isArcadeMode,
      matchCostResolver: widget.draft.matchCostFor,
    );
  }

  Future<bool> _saveSeasonOnline(String teamName) async {
    try {
      await FirestoreService()
          .createNewSeasonFromDraft(
            teamName: _formatTeamName(teamName),
            roster: widget.draft.myRoster,
          )
          .timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      lastSaveError = e.toString();
      return false;
    }
  }

  Future<void> _startSeason() async {
    final name = teamNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a team name')),
      );
      return;
    }

    setState(() {
      isStarting = true;
      saveFailed = false;
      lastSaveError = null;
    });

    final saved = await _saveSeasonOnline(name);

    if (!mounted) return;
    setState(() {
      isStarting = false;
      saveFailed = !saved;
    });

    if (saved) {
      _startLocally();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save season online: ${lastSaveError ?? 'unknown error'}')),
    );
  }

  Future<void> _retrySave() async {
    final name = teamNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      isStarting = true;
      lastSaveError = null;
    });

    final saved = await _saveSeasonOnline(name);

    if (!mounted) return;
    setState(() {
      isStarting = false;
      saveFailed = !saved;
    });

    if (saved) {
      _startLocally();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Still failed to save: ${lastSaveError ?? 'unknown error'}')),
    );
  }

  @override
  void dispose() {
    teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Name Your Team'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/indoor_allIN.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.72)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.groups,
                  color: Color(0xFFD4AF37),
                  size: 72,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Name Your Draft Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will appear on your Stats page.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: teamNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    hintText: 'Example: Nightmare',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isStarting ? null : _startSeason,
                    child: isStarting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('START SEASON'),
                  ),
                ),
                if (saveFailed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isStarting ? null : _retrySave,
                      child: const Text('RETRY ONLINE SAVE'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isStarting ? null : _startLocally,
                      child: const Text('CONTINUE OFFLINE'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _SeasonOverScreen extends StatelessWidget {
  final SimViewModel sim;
  final DraftViewModel draft;

  const _SeasonOverScreen({
    required this.sim,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final playerWon = sim.playerTotalPoints >= sim.aiTotalPoints;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Season Over'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/indoor_allIN.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.72),
            ),
          ),
          Center(
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
                Text(
                  'You  ${sim.playerTotalPoints} pts',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI   ${sim.aiTotalPoints} pts',
                  style: const TextStyle(color: Colors.grey, fontSize: 20),
                ),
                const SizedBox(height: 36),

                ElevatedButton(
      onPressed: () {
        draft.restartDraft();
        sim.resetSeasonState();

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
      child: const Text('NEW GAME SETUP'),
    ),

    const SizedBox(height: 12),

    OutlinedButton(
      onPressed: () {
        draft.restartDraft();
        sim.resetSeasonState();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
      child: const Text('BACK TO HOME'),
    ),
              ],
            ),
          ),
        ],
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
                              style: TextStyle(
                                  color: _staminaColor(w.currentStamina), fontSize: 11),
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

class _RestSlotCard extends StatelessWidget {
  final int index;
  final RestBooking? booking;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _RestSlotCard({
    required this.index,
    this.booking,
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
          border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text('REST SLOT ${index + 1}',
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  const Text('OPTIONAL',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  if (booking != null) ...[
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
              child: booking == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.bedtime_outlined, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('Assign Rest (+20 STA)',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.hotel, color: Colors.tealAccent, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(booking!.wrestler.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        _Tag(
                          '+${booking!.recoveryAmount} STA',
                          color: Colors.teal.withValues(alpha: 0.3),
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
                              style: TextStyle(
                                  color: _staminaColor(w.currentStamina), fontSize: 11),
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

class _RestSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final Wrestler? initial;

  const _RestSheet({required this.sim, required this.slotIndex, this.initial});

  @override
  State<_RestSheet> createState() => _RestSheetState();
}

class _RestSheetState extends State<_RestSheet> {
  Wrestler? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.sim.availableWrestlers.toList()
      ..sort((a, b) => a.currentStamina.compareTo(b.currentStamina));

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('REST SLOT',
                        style: TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5)),
                    Spacer(),
                    Text('Pick one wrestler',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Rested wrestlers skip the show and recover a big chunk of stamina.',
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
                          return ListTile(
                            onTap: () => setState(() => selected = isSel ? null : w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tileColor: isSel
                                ? Colors.teal.withValues(alpha: 0.12)
                                : null,
                            title: Text(w.name,
                                style: TextStyle(
                                    color: isSel ? Colors.white : Colors.grey[300],
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(
                              '${w.wrestlerClass}  ·  STA ${w.currentStamina}/${w.stamina}  ·  ${_staminaLabel(w.currentStamina)}',
                              style: TextStyle(
                                color: _staminaColor(w.currentStamina),
                                fontSize: 11,
                              ),
                            ),
                            trailing: isSel
                                ? const Icon(Icons.check_circle, color: Colors.tealAccent)
                                : const Text('+20 STA',
                                    style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                            widget.sim.setRestSlot(widget.slotIndex, selected!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selected != null ? Colors.teal : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ASSIGN REST',
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
