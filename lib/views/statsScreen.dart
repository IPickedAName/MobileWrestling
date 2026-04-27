import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firestore_service.dart';
import '../viewmodels/draft_VM.dart';
import 'appDrawer.dart';
import '../widgets/app_nav.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  static const Color _tnaBlue = Color(0xFF1E40AF);

  bool isLoading = true;
  bool isRepairing = false;
  String errorMessage = '';

  List<Map<String, dynamic>> seasons = [];
  String? selectedSeasonId;

  Map<String, dynamic> currentStats = {};
  List<Map<String, dynamic>> weeklyStats = [];

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatTeamName(String name) {
    final now = DateTime.now();
    return 'Team "$name" ${now.month}/${now.day}';
  }

  double _winRate(int wins, int losses) {
    final total = wins + losses;
    if (total == 0) return 0;
    return wins / total;
  }

  Future<void> loadStats() async {
    try {
      final loadedSeasons = await _firestoreService.getSeasons();
      final activeId = await _firestoreService.getActiveSeasonId();

      String? seasonToLoad = activeId;

      if (seasonToLoad == null && loadedSeasons.isNotEmpty) {
        seasonToLoad = loadedSeasons.first['seasonId'];
      }

      Map<String, dynamic> stats = {};
      List<Map<String, dynamic>> weeks = [];

      if (seasonToLoad != null) {
        final loadedStats =
            await _firestoreService.getCurrentStatsForSeason(seasonToLoad);
        final loadedWeeks =
            await _firestoreService.getWeeklyStatsForSeason(seasonToLoad);

        stats = loadedStats ?? {};
        weeks = loadedWeeks;
      }

      setState(() {
        seasons = loadedSeasons;
        selectedSeasonId = seasonToLoad;
        currentStats = stats;
        weeklyStats = weeks;
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load stats: $e';
        isLoading = false;
      });
    }
  }

  Future<void> switchSeason(String seasonId) async {
    try {
      await _firestoreService.setActiveSeason(seasonId);

      final loadedStats =
          await _firestoreService.getCurrentStatsForSeason(seasonId);
      final loadedWeeks =
          await _firestoreService.getWeeklyStatsForSeason(seasonId);

      setState(() {
        selectedSeasonId = seasonId;
        currentStats = loadedStats ?? {};
        weeklyStats = loadedWeeks;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch season: $e')),
      );
    }
  }

  Future<void> _repairSeasonFromDraft() async {
    final draft = context.read<DraftViewModel>();
    if (draft.myRoster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drafted roster found yet.')),
      );
      return;
    }

    final controller = TextEditingController();
    final teamName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Create Cloud Season', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Team Name',
              hintText: 'Example: Nightmare',
              labelStyle: TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(dialogContext, text);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (teamName == null || teamName.trim().isEmpty) return;

    setState(() {
      isRepairing = true;
    });

    try {
      await _firestoreService.createNewSeasonFromDraft(
        teamName: _formatTeamName(teamName.trim()),
        roster: draft.myRoster,
      );
      await loadStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud season created. Stats are now connected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create cloud season: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRepairing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        drawer: const AppDrawer(),
        appBar: AppBar(
          leading: AppNav.backButton(context),
          backgroundColor: _tnaBlue,
          foregroundColor: Colors.white,
          title: const Text('Stats'),
          actions: [AppNav.menuButton()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        drawer: const AppDrawer(),
        appBar: AppBar(
          leading: AppNav.backButton(context),
          backgroundColor: _tnaBlue,
          foregroundColor: Colors.white,
          title: const Text('Stats'),
          actions: [AppNav.menuButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: loadStats,
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int totalPoints = _asInt(currentStats['totalPoints']);
    final int wins = _asInt(currentStats['wins']);
    final int losses = _asInt(currentStats['losses']);
    final int weeksPlayed = _asInt(currentStats['weeksPlayed']);
    final int pointDiff = weeklyStats.fold<int>(
      0,
      (sum, week) => sum + (_asInt(week['playerPoints']) - _asInt(week['aiPoints'])),
    );

    final double bestRating = _asDouble(currentStats['bestRating']);
    final double averageRating = _asDouble(currentStats['averageRating']);
    final double winRate = _winRate(wins, losses);

    final selectedSeason = seasons.where((s) => s['seasonId'] == selectedSeasonId).toList();
    final teamName = selectedSeason.isNotEmpty
        ? (selectedSeason.first['teamName'] ?? 'Unnamed Team').toString()
        : 'No Active Season';

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: AppNav.backButton(context),
        backgroundColor: _tnaBlue,
        foregroundColor: Colors.white,
        title: const Text('Stats'),
        actions: [
          AppNav.menuButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _seasonHero(teamName: teamName, winRate: winRate, weeksPlayed: weeksPlayed),

            const SizedBox(height: 14),

            if (seasons.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No cloud season found yet.',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you started offline or save failed, create a cloud season from your current draft to enable stats syncing.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: isRepairing ? null : loadStats,
                          child: const Text('RELOAD'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: isRepairing ? null : _repairSeasonFromDraft,
                          child: isRepairing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('CREATE FROM DRAFT'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              _seasonDropdown(),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _summaryCard('Points', '$totalPoints', Icons.military_tech, const Color(0xFFef4444)),
                _summaryCard('Wins', '$wins', Icons.emoji_events_outlined, const Color(0xFF22c55e)),
                _summaryCard('Losses', '$losses', Icons.close_rounded, const Color(0xFFf97316)),
                _summaryCard('Weeks', '$weeksPlayed', Icons.event_note, const Color(0xFF38bdf8)),
                _summaryCard('Best Star', bestRating.toStringAsFixed(2), Icons.star_border, const Color(0xFFfacc15)),
                _summaryCard('Avg Star', averageRating.toStringAsFixed(2), Icons.auto_graph, const Color(0xFFa78bfa)),
              ],
            ),

            const SizedBox(height: 16),

            _trendCard(pointDiff: pointDiff, winRate: winRate),

            const SizedBox(height: 24),

            const Text(
              'Weekly History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

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
                  'No weekly stats yet. Simulate a week to start tracking this draft.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ...weeklyStats.map((week) => _weekTile(week)),
          ],
        ),
      ),
    );
  }

  Widget _seasonDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSeasonId,
          dropdownColor: const Color(0xFF1A1A1A),
          isExpanded: true,
          iconEnabledColor: Colors.white,
          items: seasons.map((season) {
            final id = season['seasonId'];
            final teamName = season['teamName'] ?? 'Unnamed Team';

            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                teamName,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              switchSeason(value);
            }
          },
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color accent) {
    return Container(
      width: 107,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _seasonHero({
    required String teamName,
    required double winRate,
    required int weeksPlayed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7f1d1d), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.query_stats, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Win rate ${(winRate * 100).toStringAsFixed(1)}%  •  $weeksPlayed weeks tracked',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard({required int pointDiff, required double winRate}) {
    final positive = pointDiff >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: positive ? const Color(0xFF4ade80) : const Color(0xFFfb7185),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Point differential: ${positive ? '+' : ''}$pointDiff   •   Conversion: ${(winRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekTile(Map<String, dynamic> week) {
    final int weekNumber = _asInt(week['weekNumber']);
    final int playerPoints = _asInt(week['playerPoints']);
    final int aiPoints = _asInt(week['aiPoints']);
    final String result = week['result'] ?? '';
    final double avgRating = _asDouble(week['avgRating']);
    final int diff = playerPoints - aiPoints;
    final positive = diff >= 0;

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
          'You $playerPoints  •  AI $aiPoints  •  Diff ${positive ? '+' : ''}$diff  •  Star ${avgRating.toStringAsFixed(2)}',
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