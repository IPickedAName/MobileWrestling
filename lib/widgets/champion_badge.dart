import 'package:flutter/material.dart';

class ChampionBadge extends StatelessWidget {
  final String? label;
  final bool compact;

  const ChampionBadge({super.key, this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final text = label ?? 'Champion';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFfacc15).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFfacc15).withValues(alpha: 0.45),
            width: 0.6,
          ),
        ),
        child: const Text(
          'CH',
          style: TextStyle(
            color: Color(0xFFfacc15),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFfacc15).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFfacc15).withValues(alpha: 0.45),
          width: 0.7,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFfacc15),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
