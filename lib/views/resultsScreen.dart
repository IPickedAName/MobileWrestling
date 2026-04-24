import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simVM.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimViewModel>(
      builder: (context, sim, _) {
        if (sim.weekResults.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: const Text('Results')),
            body: const Center(
              child: Text('No results yet', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final summary = sim.history.isNotEmpty ? sim.history.last : null;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text('Week ${sim.currentWeek} Results'),
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              if (summary != null) _SummaryBar(summary: summary),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sim.weekResults.length,
                  itemBuilder: (ctx, i) => _ResultCard(result: sim.weekResults[i]),
                ),
              ),
              _BottomBar(sim: sim),
            ],
          ),
        );
      },
    );
  }
}

// ─── SUMMARY BAR ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final WeekSummary summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final lead = summary.playerPoints - summary.aiPoints;
    final leadStr = lead >= 0 ? '+$lead' : '$lead';
    final leadColor = lead >= 0 ? const Color(0xFFCC0000) : Colors.blueGrey;

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              label: 'YOU',
              value: '+${summary.playerPoints}',
              color: const Color(0xFFCC0000)),
          _StatItem(
              label: 'AVG ★',
              value: summary.avgRating.toStringAsFixed(2),
              color: Colors.amber),
          _StatItem(label: 'AI', value: '+${summary.aiPoints}', color: Colors.white70),
          _StatItem(label: 'LEAD', value: leadStr, color: leadColor),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

// ─── RESULT CARD ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final MatchResult result;
  const _ResultCard({required this.result});

  String _starStr(double r) {
    final full = r.floor();
    final half = (r - full) >= 0.25;
    return '${'★' * full}${half ? '½' : ''}  (${r.toStringAsFixed(2)})';
  }

  Color get _borderColor {
    if (result.starRating >= 4.5) return Colors.amber;
    if (result.starRating >= 4.0) return Colors.amber.withValues(alpha: 0.4);
    return const Color(0xFF2A2A2A);
  }

  @override
  Widget build(BuildContext context) {
    final winnerIsW1 = result.winner.name == result.w1.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position + points
          Row(
            children: [
              Text(result.position.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10, letterSpacing: 1.4)),
              const Spacer(),
              Text('+${result.points} pts',
                  style: const TextStyle(
                      color: Color(0xFFCC0000),
                      fontWeight: FontWeight.bold,
                      fontSize: 17)),
            ],
          ),
          const SizedBox(height: 10),
          // Wrestlers
          Row(
            children: [
              Expanded(
                child: Text(result.w1.name,
                    style: TextStyle(
                        color: winnerIsW1 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              const Text(' VS ',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(
                child: Text(result.w2.name,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: !winnerIsW1 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Winner + star rating
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 15),
              const SizedBox(width: 4),
              Text('${result.winner.name} wins',
                  style: const TextStyle(color: Colors.amber, fontSize: 13)),
              const Spacer(),
              Text(_starStr(result.starRating),
                  style: const TextStyle(color: Colors.amber, fontSize: 13)),
            ],
          ),
          // Badges
          if (result.correctPrediction || result.wasUpset) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (result.correctPrediction)
                  _Badge(
                      result.wasUpset ? '✓ Upset Prediction' : '✓ Correct Pick',
                      result.wasUpset ? Colors.orange : Colors.green),
                if (result.wasUpset && !result.correctPrediction) ...[
                  const SizedBox(width: 6),
                  _Badge('UPSET', Colors.orange),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── BOTTOM BAR ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final SimViewModel sim;
  const _BottomBar({required this.sim});

  @override
  Widget build(BuildContext context) {
    final isLastWeek = sim.currentWeek >= sim.totalWeeks;

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${sim.playerTotalPoints} pts',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('AI: ${sim.aiTotalPoints} pts',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              sim.advanceWeek();
              Navigator.pushReplacementNamed(context, '/booking');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC0000),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isLastWeek ? 'END SEASON' : 'NEXT WEEK →',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
