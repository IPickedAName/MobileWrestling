import 'package:flutter/material.dart';
import '../../viewmodels/simVM.dart';
import '../../theme/game_theme.dart';

const Color kTnaBlue = Color(0xFF1E40AF);

// ─── STEP INDICATOR ──────────────────────────────────────────────────────────

class ResultsStepIndicator extends StatelessWidget {
  final int step;
  const ResultsStepIndicator({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['YOUR SHOW', 'AI SHOW', 'BREAKDOWN'];
    return Container(
      color: GameTheme.panel,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == step;
          final done = i < step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(labels[i],
                          style: TextStyle(
                              color: active
                                  ? kTnaBlue
                                  : done
                                      ? Colors.green
                                      : Colors.grey,
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Container(
                        height: 2,
                        color: active
                            ? kTnaBlue
                            : done
                                ? Colors.green
                                : const Color(0xFF2A2A2A),
                      ),
                    ],
                  ),
                ),
                if (i < 2)
                  Icon(Icons.chevron_right,
                      color: i < step ? Colors.green : Colors.grey, size: 16),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── SUMMARY BAR ─────────────────────────────────────────────────────────────

class ResultsSummaryBar extends StatelessWidget {
  final WeekSummary summary;
  const ResultsSummaryBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final lead = summary.playerPoints - summary.aiPoints;
    return Container(
      color: const Color(0xFF121929),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ResultsStat('YOU', '+${summary.playerPoints}', kTnaBlue),
          ResultsStat(
              'AVG ★', summary.avgRating.toStringAsFixed(2), Colors.amber),
          ResultsStat('AI', '+${summary.aiPoints}', Colors.white70),
          ResultsStat(
            'LEAD',
            lead >= 0 ? '+$lead' : '$lead',
            lead >= 0 ? Colors.green : Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

// ─── STAT ─────────────────────────────────────────────────────────────────────

class ResultsStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const ResultsStat(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }
}
