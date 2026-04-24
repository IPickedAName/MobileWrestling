import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wrestler.dart';
import '../viewmodels/simVM.dart';
import '../viewmodels/draft_VM.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SimViewModel, DraftViewModel>(
      builder: (context, sim, draft, _) {
        // Auto-init season after draft completes
        if (!sim.seasonStarted && draft.draftComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            sim.initSeason(draft.myRoster, draft.aiRoster);
          });
        }

        if (!draft.draftComplete) {
          return _NoDraftScreen();
        }

        if (sim.seasonOver) {
          return _SeasonOverScreen(sim: sim);
        }

        return Scaffold(
          backgroundColor: Colors.black,
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
        sim.setSlot(index, existing.w1, existing.w2, existing.matchType, existing.predictedWinner);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(booking.w1.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('VS', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            Expanded(
              child: Text(booking.w2.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Tag(booking.matchType),
            const SizedBox(width: 6),
            _Tag('Pick: ${booking.predictedWinner.name}',
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
          ElevatedButton(
            onPressed: sim.cardFull
                ? () {
                    sim.simulateWeek();
                    Navigator.pushNamed(context, '/results');
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
  String matchType = 'Singles';
  Wrestler? predicted;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      w1 = widget.initial!.w1;
      w2 = widget.initial!.w2;
      matchType = widget.initial!.matchType;
      predicted = widget.initial!.predictedWinner;
    }
  }

  List<Wrestler> get _available => widget.sim.availableWrestlers;

  bool get _canConfirm => w1 != null && w2 != null && predicted != null;

  void _selectWrestler(Wrestler w) {
    setState(() {
      if (w1?.name == w.name) {
        // deselect w1; shift w2 up if present
        w1 = w2;
        w2 = null;
        predicted = null;
      } else if (w2?.name == w.name) {
        w2 = null;
        predicted = null;
      } else if (w1 == null) {
        w1 = w;
      } else {
        // replace w2 (or set if empty)
        w2 = w;
        predicted = null;
      }
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
                      w1 != null && w2 != null
                          ? '2 / 2 selected'
                          : w1 != null
                              ? '1 / 2 selected'
                              : 'Pick 2 wrestlers',
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
                      onTap: () => setState(() => matchType = t),
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
              // Predict winner (shown when both selected)
              if (w1 != null && w2 != null)
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
                          final isW1 = w.name == w1?.name;
                          final isW2 = w.name == w2?.name;
                          final isSelected = isW1 || isW2;
                          return ListTile(
                            onTap: () => _selectWrestler(w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tileColor: isW1
                                ? const Color(0xFFCC0000).withValues(alpha: 0.12)
                                : isW2
                                    ? Colors.blue.withValues(alpha: 0.12)
                                    : null,
                            title: Text(w.name,
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
                            trailing: isW1
                                ? _CircleBadge('1', const Color(0xFFCC0000))
                                : isW2
                                    ? const _CircleBadge('2', Colors.blue)
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
                                widget.slotIndex, w1!, w2!, matchType, predicted!);
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
