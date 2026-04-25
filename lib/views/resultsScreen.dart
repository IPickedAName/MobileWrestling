import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simVM.dart';
import 'appDrawer.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _step = 0; // 0 = your show, 1 = AI show, 2 = comparison

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
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Text(_stepTitle),
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('${_step + 1} / 3',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _StepIndicator(step: _step),
              if (summary != null) _SummaryBar(summary: summary),
              Expanded(child: _buildPage(sim)),
              _NavBar(
                step: _step,
                sim: sim,
                onNext: () => setState(() => _step++),
                onBack: () => setState(() => _step--),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Your Show';
      case 1: return 'AI\'s Show';
      default: return 'Comparison';
    }
  }

  Widget _buildPage(SimViewModel sim) {
    switch (_step) {
      case 0:
        return _MatchList(results: sim.weekResults, promos: sim.promos);
      case 1:
        return sim.aiWeekResults.isEmpty
            ? const Center(
                child: Text('AI results unavailable',
                    style: TextStyle(color: Colors.grey)))
            : _MatchList(results: sim.aiWeekResults, promos: const []);
      default:
        return _ComparisonChart(sim: sim);
    }
  }
}

// ─── STEP INDICATOR ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['YOUR SHOW', 'AI SHOW', 'BREAKDOWN'];
    return Container(
      color: const Color(0xFF0D0D0D),
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
                                  ? const Color(0xFFCC0000)
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
                            ? const Color(0xFFCC0000)
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

class _SummaryBar extends StatelessWidget {
  final WeekSummary summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final lead = summary.playerPoints - summary.aiPoints;
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('YOU', '+${summary.playerPoints}', const Color(0xFFCC0000)),
          _Stat('AVG ★', summary.avgRating.toStringAsFixed(2), Colors.amber),
          _Stat('AI', '+${summary.aiPoints}', Colors.white70),
          _Stat('LEAD',
              lead >= 0 ? '+$lead' : '$lead',
              lead >= 0 ? Colors.green : Colors.redAccent),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

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

// ─── MATCH LIST (used for both your show and AI show) ────────────────────────

class _MatchList extends StatelessWidget {
  final List<MatchResult> results;
  final List<PromoBooking?> promos;
  const _MatchList({required this.results, required this.promos});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in results) _ResultCard(result: r),
        for (final p in promos)
          if (p != null) _PromoResultCard(promo: p),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MatchResult result;
  const _ResultCard({required this.result});

  String _starStr(double r) {
    final full = r.floor();
    final half = (r - full) >= 0.25;
    return '${'★' * full}${half ? '½' : ''}  (${r.toStringAsFixed(2)})';
  }

  @override
  Widget build(BuildContext context) {
    final winnerIsW1 = result.winner.name == result.w1.name;
    final isGoodMatch = result.starRating >= 4.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGoodMatch
                ? Colors.amber.withValues(alpha: 0.45)
                : const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(result.position.toUpperCase(),
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10, letterSpacing: 1.4)),
            const Spacer(),
            Text('+${result.points} pts',
                style: const TextStyle(
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(result.w1.name,
                  style: TextStyle(
                      color: winnerIsW1 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
            const Text(' VS ', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Expanded(
              child: Text(result.w2.name,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: !winnerIsW1 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 15),
            const SizedBox(width: 4),
            Text('${result.winner.name} wins',
                style: const TextStyle(color: Colors.amber, fontSize: 13)),
            const Spacer(),
            Text(_starStr(result.starRating),
                style: const TextStyle(color: Colors.amber, fontSize: 13)),
          ]),
          if (result.correctPrediction || result.wasUpset) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (result.correctPrediction)
                _Badge(
                    result.wasUpset ? '✓ Upset Pick +35' : '✓ Correct Pick +15',
                    result.wasUpset ? Colors.orange : Colors.green),
              if (result.wasUpset && !result.correctPrediction) ...[
                const SizedBox(width: 6),
                _InfoBadge(
                  label: 'UPSET',
                  color: Colors.orange,
                  tooltip:
                      'A lower-popularity wrestler won.\nCorrectly predicting an upset earns +35 pts instead of +15.',
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}

class _PromoResultCard extends StatelessWidget {
  final PromoBooking promo;
  const _PromoResultCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final w = promo.wrestler;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.mic, color: Colors.purple, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text('Promo Skill ${w.promoSkill}★',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${w.promoSkill * 4} STA',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          Text('+${w.promoSkill} Pop',
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── COMPARISON CHART ────────────────────────────────────────────────────────

class _ComparisonChart extends StatelessWidget {
  final SimViewModel sim;
  const _ComparisonChart({required this.sim});

  @override
  Widget build(BuildContext context) {
    final playerResults = sim.weekResults;
    final aiResults = sim.aiWeekResults;
    final summary = sim.history.isNotEmpty ? sim.history.last : null;
    final maxBars = playerResults.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Points totals
        _PointsComparison(summary: summary),
        const SizedBox(height: 24),
        // Section header
        Row(children: [
          const Expanded(
            child: Text('YOU',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFCC0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(width: 60),
          const Expanded(
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
        // Match bars
        for (int i = 0; i < maxBars; i++)
          _MatchBar(
            position: SimViewModel.positions[i],
            playerRating: i < playerResults.length ? playerResults[i].starRating : 0,
            aiRating: i < aiResults.length ? aiResults[i].starRating : 0,
          ),
        const SizedBox(height: 8),
        // Scoring legend
        _ScoringLegend(),
      ],
    );
  }
}

class _PointsComparison extends StatelessWidget {
  final WeekSummary? summary;
  const _PointsComparison({this.summary});

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

class _MatchBar extends StatelessWidget {
  final String position;
  final double playerRating;
  final double aiRating;
  const _MatchBar(
      {required this.position,
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
          // Player bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(playerRating > 0
                    ? playerRating.toStringAsFixed(2)
                    : '—',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
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
          // Position label
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                Text(position.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 9, letterSpacing: 1)),
              ],
            ),
          ),
          // AI bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(aiRating > 0
                    ? aiRating.toStringAsFixed(2)
                    : '—',
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
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

class _ScoringLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('5.0★', '60 pts'), ('4.5★', '50 pts'), ('4.0★', '40 pts'),
      ('3.5★', '30 pts'), ('3.0★', '20 pts'), ('2.5★', '10 pts'),
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
                      style: const TextStyle(color: Colors.amber, fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('= ${r.$2}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              const SizedBox(width: 8),
              _tipRow('Correct Pick', '+15 pts'),
              _tipRow('Upset Pick', '+35 pts'),
              _tipRow('Main Event', '+10 pts'),
              _tipRow('Full Card', '+10 pts'),
              _tipRow('Avg ≥3.75★', '+15 pts'),
              _tipRow('Avg ≥4.5★', '+25 pts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(
              color: Color(0xFFCC0000), fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ─── NAV BAR ─────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int step;
  final SimViewModel sim;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _NavBar(
      {required this.step,
      required this.sim,
      required this.onNext,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    final isFirst = step == 0;

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text('← Back'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: isLast
                ? () {
                    sim.advanceWeek();
                    Navigator.pushReplacementNamed(context, '/booking');
                  }
                : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC0000),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isLast
                  ? (sim.currentWeek >= sim.totalWeeks
                      ? 'END SEASON'
                      : 'NEXT WEEK →')
                  : 'Next →',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

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
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;
  const _InfoBadge(
      {required this.label, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, color: color, size: 11),
        ]),
      ),
    );
  }
}
