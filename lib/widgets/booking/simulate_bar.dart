import 'package:flutter/material.dart';
import '../../viewmodels/simVM.dart';
import '../../viewmodels/draft_VM.dart';
import '../../theme/game_theme.dart';
import '../../firestore_service.dart';

class BookingSimulateBar extends StatefulWidget {
  final SimViewModel sim;
  final DraftViewModel draft;
  const BookingSimulateBar(
      {super.key, required this.sim, required this.draft});

  @override
  State<BookingSimulateBar> createState() => _BookingSimulateBarState();
}

class _BookingSimulateBarState extends State<BookingSimulateBar> {
  bool isSaving = false;

  Future<void> _simulateAndSave(BuildContext context) async {
    if (!widget.sim.cardFull || isSaving) return;
    setState(() => isSaving = true);
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
        } catch (_) {}
      }
      if (context.mounted) Navigator.pushNamed(context, '/results');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save weekly stats: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
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
                        style: const TextStyle(
                            color: Color(0xFFfb923c),
                            fontSize: 11,
                            fontWeight: FontWeight.w600))
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('AUTO BOOK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: sim.cardFull && !isSaving
                ? () => _simulateAndSave(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  sim.cardFull ? const Color(0xFFCC0000) : Colors.grey[850],
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('SIMULATE WEEK',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
