import 'package:flutter/material.dart';
import '../../viewmodels/simVM.dart';

// ─── COMPARISON CHART ────────────────────────────────────────────────────────

class ResultsComparisonChart extends StatelessWidget {
  final SimViewModel sim;
  const ResultsComparisonChart({super.key, required this.sim});

  @override
  Widget build(BuildContext context) {
    final playerResults = sim.weekResults;
    final aiResults = sim.aiWeekResults;
    final summary = sim.history.isNotEmpty ? sim.history.last : null;
    final maxBars = playerResults.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ResultsPointsComparison(summary: summary),
        const SizedBox(height: 24),
        const Row(children: [
          Expanded(
            child: Text('YOU',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ),
          SizedBox(width: 60),
          Expanded(
            child: Text('AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ),
        ]),
        const SizedBox(height: 12),
        for (int i = 0; i < maxBars; i++)
          ResultsMatchBar(
            position: SimViewModel.positions[i],
            playerRating:
                i < playerResults.length ? playerResults[i].starRating : 0,
            aiRating: i < aiResults.length ? aiResults[i].starRating : 0,
          ),
        const SizedBox(height: 8),
        const ResultsScoringLegend(),
      ],
    );
  }
}

// ─── POINTS COMPARISON ───────────────────────────────────────────────────────

class ResultsPointsComparison extends StatelessWidget {
  final WeekSummary? summary;
  const ResultsPointsComparison({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox();
    final playerWon = summary!.playerPoints >= summary!.aiPoints;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: playerWon
                ? const Color(0xFFCC0000).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text('${summary!.playerPoints}',
                style: const TextStyle(
                    color: Color(0xFFCC0000),
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            const Text('YOUR POINTS',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          Column(children: [
            Icon(
              playerWon ? Icons.arrow_upward : Icons.arrow_downward,
              color: playerWon ? Colors.green : Colors.redAccent,
              size: 28,
            ),
            Text(
              playerWon ? 'YOU WIN\nTHIS WEEK' : 'AI WINS\nTHIS WEEK',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: playerWon ? Colors.green : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ]),
          Column(children: [
            Text('${summary!.aiPoints}',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            const Text('AI POINTS',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── MATCH BAR ───────────────────────────────────────────────────────────────

class ResultsMatchBar extends StatelessWidget {
  final String position;
  final double playerRating;
  final double aiRating;
  const ResultsMatchBar(
      {super.key,
      required this.position,
      required this.playerRating,
      required this.aiRating});

  Color _barColor(double rating) {
    if (rating >= 4.5) return Colors.amber;
    if (rating >= 4.0) return const Color(0xFFCC0000);
    if (rating >= 3.0) return Colors.blueGrey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    const maxRating = 5.0;
    const barMaxHeight = 80.0;
    final pHeight = (playerRating / maxRating) * barMaxHeight;
    final aHeight = (aiRating / maxRating) * barMaxHeight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(playerRating > 0 ? playerRating.toStringAsFixed(2) : '—',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: pHeight.clamp(4.0, barMaxHeight),
                    width: 40,
                    decoration: BoxDecoration(
                      color: _barColor(playerRating),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                Text(position.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                        letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(aiRating > 0 ? aiRating.toStringAsFixed(2) : '—',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: aHeight.clamp(4.0, barMaxHeight),
                    width: 40,
                    decoration: BoxDecoration(
                      color: _barColor(aiRating).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SCORING LEGEND ───────────────────────────────────────────────────────────

class ResultsScoringLegend extends StatelessWidget {
  const ResultsScoringLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('5.0★', '60 pts'),
      ('4.5★', '50 pts'),
      ('4.0★', '40 pts'),
      ('3.5★', '30 pts'),
      ('3.0★', '20 pts'),
      ('2.5★', '10 pts'),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 13),
            SizedBox(width: 6),
            Text('SCORING REFERENCE',
                style: TextStyle(
                    color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final r in rows)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(r.$1,
                      style: const TextStyle(
                          color: Colors.amber, fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('= ${r.$2}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ]),
              ...[
                _tipRow('Correct Pick', '+15 pts'),
                _tipRow('Upset Pick', '+35 pts'),
                _tipRow('Main Event', '+10 pts'),
                _tipRow('Full Card', '+10 pts'),
                _tipRow('Avg ≥3.75★', '+15 pts'),
                _tipRow('Avg ≥4.5★', '+25 pts'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(
              color: Color(0xFFCC0000),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    ]);
  }
}
