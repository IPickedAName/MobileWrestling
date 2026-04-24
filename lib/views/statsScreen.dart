import 'package:flutter/material.dart';
import '../models/wrestler.dart';
import '../services/wrestlerService.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Wrestler> wrestlers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final loaded = await WrestlerService.loadWrestlers();
      setState(() {
        wrestlers = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load stats';
        isLoading = false;
      });
    }
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
          child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final topPopularity = [...wrestlers]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final topInRing = [...wrestlers]
      ..sort((a, b) => b.inRing.compareTo(a.inRing));
    final topSalary = [...wrestlers]
      ..sort((a, b) => b.salary.compareTo(a.salary));
    final topCharisma = [...wrestlers]
      ..sort((a, b) => b.charisma.compareTo(a.charisma));

    final avgPopularity = wrestlers.map((w) => w.popularity).reduce((a, b) => a + b) / wrestlers.length;
    final avgSalary     = wrestlers.map((w) => w.salary).reduce((a, b) => a + b) / wrestlers.length;
    final avgInRing     = wrestlers.map((w) => w.inRing).reduce((a, b) => a + b) / wrestlers.length;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Stats'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard('Roster', '${wrestlers.length}')),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard('Avg POP', avgPopularity.toStringAsFixed(1))),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard('Avg Ring', avgInRing.toStringAsFixed(1))),
            ],
          ),
          const SizedBox(height: 10),
          _summaryCard('Avg Salary', '\$${avgSalary.toStringAsFixed(0)}k'),
          const SizedBox(height: 24),

          _sectionTitle('Top Popularity'),
          const SizedBox(height: 10),
          ...topPopularity.take(5).map((w) => _wrestlerTile(w, 'POP ${w.popularity}')),

          const SizedBox(height: 20),
          _sectionTitle('Best In-Ring'),
          const SizedBox(height: 10),
          ...topInRing.take(5).map((w) => _wrestlerTile(w, 'IN-RING ${w.inRing}')),

          const SizedBox(height: 20),
          _sectionTitle('Highest Salary'),
          const SizedBox(height: 10),
          ...topSalary.take(5).map((w) => _wrestlerTile(w, '\$${w.salary}k')),

          const SizedBox(height: 20),
          _sectionTitle('Top Charisma'),
          const SizedBox(height: 10),
          ...topCharisma.take(5).map((w) => _wrestlerTile(w, 'CHA ${w.charisma}')),
        ],
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _wrestlerTile(Wrestler wrestler, String stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        title: Text(wrestler.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${wrestler.promotion} • ${wrestler.wrestlerClass}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          stat,
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
