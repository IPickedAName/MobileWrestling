import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/simVM.dart';
import '../../viewmodels/draft_VM.dart';
import '../../theme/game_theme.dart';
import '../champion_badge.dart';

// ─── SCORE BAR ────────────────────────────────────────────────────────────────

class BookingScoreBar extends StatelessWidget {
  final int playerPts;
  final int aiPts;
  const BookingScoreBar(
      {super.key, required this.playerPts, required this.aiPts});

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
                    color: Color(0xFFE11D48),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const Text('YOU',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const Text('VS',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          Column(children: [
            Text('$aiPts',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const Text('AI',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── TAG ──────────────────────────────────────────────────────────────────────

class BookingTag extends StatelessWidget {
  final String label;
  final Color color;
  const BookingTag(this.label,
      {super.key, this.color = const Color(0xFF2C2C2C)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

// ─── CIRCLE BADGE ─────────────────────────────────────────────────────────────

class BookingCircleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const BookingCircleBadge(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── SLOT CARD ────────────────────────────────────────────────────────────────

class BookingSlotCard extends StatelessWidget {
  final int index;
  final MatchBooking? booking;
  final String position;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final int cost;

  const BookingSlotCard({
    super.key,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C2D12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('- ${DraftViewModel.toM(cost)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                    ),
                  if (booking != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(Icons.close,
                          color: Colors.grey, size: 16),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: booking == null
                  ? const _BookingEmptySlot()
                  : _BookingFilledSlot(booking: booking!),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingEmptySlot extends StatelessWidget {
  const _BookingEmptySlot();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_circle_outline, color: Colors.grey, size: 18),
        SizedBox(width: 8),
        Text('Add Match', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class _BookingFilledSlot extends StatelessWidget {
  final MatchBooking booking;
  const _BookingFilledSlot({required this.booking});

  Widget _nameCell(Wrestler wrestler, {TextAlign align = TextAlign.left}) {
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
              child:
                  Text('VS', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
            BookingTag(booking.matchType),
            const SizedBox(width: 6),
            Flexible(
              child: BookingTag('Pick: ${booking.predictedWinner.name}',
                  color: const Color(0xFF6B0000)),
            ),
          ],
        ),
      ],
    );
  }
}
