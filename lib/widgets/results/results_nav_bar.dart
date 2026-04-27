import 'package:flutter/material.dart';
import '../../viewmodels/simVM.dart';

class ResultsNavBar extends StatelessWidget {
  final int step;
  final SimViewModel sim;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ResultsNavBar(
      {super.key,
      required this.step,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
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
