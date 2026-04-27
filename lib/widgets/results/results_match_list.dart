import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/simVM.dart';
import '../../theme/game_theme.dart';
import '../champion_badge.dart';

// ─── MATCH LIST ───────────────────────────────────────────────────────────────

class ResultsMatchList extends StatelessWidget {
  final List<MatchResult> results;
  final List<PromoBooking?> promos;
  const ResultsMatchList(
      {super.key, required this.results, required this.promos});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in results) ResultsResultCard(result: r),
        for (final p in promos)
          if (p != null) ResultsPromoResultCard(promo: p),
      ],
    );
  }
}

// ─── RESULT CARD ─────────────────────────────────────────────────────────────

class ResultsResultCard extends StatelessWidget {
  final MatchResult result;
  const ResultsResultCard({super.key, required this.result});

  Widget _nameWithBadge(Wrestler wrestler, {TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          wrestler.name,
          textAlign: align,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (wrestler.isChampion) ...[
          const SizedBox(height: 2),
          ChampionBadge(label: wrestler.championshipTitle, compact: true),
        ],
      ],
    );
  }

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
        color: GameTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGoodMatch
                ? Colors.amber.withValues(alpha: 0.45)
                : GameTheme.stroke),
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
              child: result.isTagTeam
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameWithBadge(result.w1),
                        const SizedBox(height: 4),
                        _nameWithBadge(result.w2),
                      ],
                    )
                  : Opacity(
                      opacity: winnerIsW1 ? 1 : 0.6,
                      child: _nameWithBadge(result.w1),
                    ),
            ),
            const Text(' VS ',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            Expanded(
              child: result.isTagTeam
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _nameWithBadge(result.w3!, align: TextAlign.right),
                        const SizedBox(height: 4),
                        _nameWithBadge(result.w4!, align: TextAlign.right),
                      ],
                    )
                  : Opacity(
                      opacity: !winnerIsW1 ? 1 : 0.6,
                      child: _nameWithBadge(result.w2, align: TextAlign.right),
                    ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(result.matchType,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10)),
            ),
            const Icon(Icons.emoji_events, color: Colors.amber, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text('${result.winner.name} wins',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Colors.amber, fontSize: 13)),
            ),
            const Spacer(),
            Text(_starStr(result.starRating),
                style: const TextStyle(color: Colors.amber, fontSize: 13)),
          ]),
          if (result.correctPrediction || result.wasUpset) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (result.correctPrediction)
                ResultsBadge(
                    result.wasUpset
                        ? '✓ Upset Pick +35'
                        : '✓ Correct Pick +15',
                    result.wasUpset ? Colors.orange : Colors.green),
              if (result.wasUpset && !result.correctPrediction) ...[
                const SizedBox(width: 6),
                ResultsInfoBadge(
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

// ─── PROMO RESULT CARD ────────────────────────────────────────────────────────

class ResultsPromoResultCard extends StatelessWidget {
  final PromoBooking promo;
  const ResultsPromoResultCard({super.key, required this.promo});

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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text('Promo Skill ${w.promoSkill}★',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${w.promoSkill * 4} STA',
              style:
                  const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          Text('+${w.promoSkill} Pop',
              style:
                  const TextStyle(color: Colors.blueAccent, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── BADGE ────────────────────────────────────────────────────────────────────

class ResultsBadge extends StatelessWidget {
  final String label;
  final Color color;
  const ResultsBadge(this.label, this.color, {super.key});

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

// ─── INFO BADGE ───────────────────────────────────────────────────────────────

class ResultsInfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;
  const ResultsInfoBadge(
      {super.key,
      required this.label,
      required this.color,
      required this.tooltip});

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
