import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firestore_service.dart';
import '../viewmodels/simVM.dart';
import 'appDrawer.dart';


class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = true;
  String errorMessage = '';
  bool usingLocalStats = false;
  Map<String, dynamic> currentStats = {};
  List<Map<String, dynamic>> weeklyStats = [];

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final stats = await _firestoreService.getCurrentStats();
      final weeks = await _firestoreService.getWeeklyStats();

      if (!mounted) return;

      if (stats == null && weeks.isEmpty) {
        _loadLocalStats();
        return;
      }

      setState(() {
        currentStats = stats ?? {};
        weeklyStats = weeks;
        isLoading = false;
        usingLocalStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      _loadLocalStats();
    }
  }

  void _loadLocalStats() {
    final sim = context.read<SimViewModel>();
    final wins = sim.history.where((week) => week.playerPoints >= week.aiPoints).length;
    final losses = sim.history.length - wins;
    final bestRating = sim.history.isEmpty
        ? 0.0
        : sim.history
            .map((week) => week.avgRating)
            .reduce((a, b) => a > b ? a : b);
    final averageRating = sim.history.isEmpty
        ? 0.0
        : sim.history.map((week) => week.avgRating).reduce((a, b) => a + b) /
            sim.history.length;

    setState(() {
      currentStats = {
        'totalPoints': sim.playerTotalPoints,
        'wins': wins,
        'losses': losses,
        'weeksPlayed': sim.history.length,
        'bestRating': bestRating,
        'averageRating': averageRating,
      };
      weeklyStats = sim.history
          .map((week) => {
                'weekNumber': week.week,
                'playerPoints': week.playerPoints,
                'aiPoints': week.aiPoints,
                'avgRating': week.avgRating,
                'result': week.playerPoints >= week.aiPoints ? 'W' : 'L',
              })
          .toList();
      usingLocalStats = true;
      errorMessage = '';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Stats'),
        ),
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final int totalPoints = currentStats['totalPoints'] ?? 0;
    final int wins = currentStats['wins'] ?? 0;
    final int losses = currentStats['losses'] ?? 0;
    final int weeksPlayed = currentStats['weeksPlayed'] ?? 0;

    final double bestRating =
        ((currentStats['bestRating'] ?? 0.0) as num).toDouble();

    final double averageRating =
        ((currentStats['averageRating'] ?? 0.0) as num).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Stats'),
      ),
      body: RefreshIndicator(
        onRefresh: loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: _summaryCard('Points', '$totalPoints')),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard('Wins', '$wins')),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard('Losses', '$losses')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _summaryCard('Weeks', '$weeksPlayed')),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    'Best ★',
                    bestRating.toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    'Avg ★',
                    averageRating.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Weekly History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (usingLocalStats) ...[
              const SizedBox(height: 8),
              const Text(
                'Showing local session stats. Firebase sync is unavailable.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            if (weeklyStats.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'No weekly stats yet. Simulate a week to start tracking.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ...weeklyStats.map((week) {
                return _weekTile(week);
              }),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _weekTile(Map<String, dynamic> week) {
    final int weekNumber = week['weekNumber'] ?? 0;
    final int playerPoints = week['playerPoints'] ?? 0;
    final int aiPoints = week['aiPoints'] ?? 0;
    final String result = week['result'] ?? '';
    final double avgRating = ((week['avgRating'] ?? 0.0) as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: result == 'W'
              ? Colors.green.withOpacity(0.35)
              : Colors.red.withOpacity(0.35),
        ),
      ),
      child: ListTile(
        title: Text(
          'Week $weekNumber',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'You: $playerPoints pts • AI: $aiPoints pts • Avg ★ ${avgRating.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          result,
          style: TextStyle(
            color: result == 'W' ? Colors.greenAccent : Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}