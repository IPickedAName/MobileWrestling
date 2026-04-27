import 'package:flutter/material.dart';
import '../viewmodels/simVM.dart';
import '../viewmodels/draft_VM.dart';
import '../firestore_service.dart';
import 'appDrawer.dart';
import '../widgets/app_nav.dart';

// ─── TEAM NAME START SCREEN ───────────────────────────────────────────────────

class TeamNameStartScreen extends StatefulWidget {
  final SimViewModel sim;
  final DraftViewModel draft;

  const TeamNameStartScreen(
      {super.key, required this.sim, required this.draft});

  @override
  State<TeamNameStartScreen> createState() => _TeamNameStartScreenState();
}

class _TeamNameStartScreenState extends State<TeamNameStartScreen> {
  final TextEditingController teamNameController = TextEditingController();
  bool isStarting = false;
  bool saveFailed = false;
  String? lastSaveError;

  String _formatTeamName(String name) {
    final now = DateTime.now();
    return 'Team "$name" ${now.month}/${now.day}';
  }

  void _startLocally() {
    widget.sim.initSeason(
      widget.draft.myRoster,
      widget.draft.aiRoster,
      arcadeMode: widget.draft.isArcadeMode,
      matchCostResolver: widget.draft.matchCostFor,
    );
  }

  Future<bool> _saveSeasonOnline(String teamName) async {
    try {
      await FirestoreService()
          .createNewSeasonFromDraft(
            teamName: _formatTeamName(teamName),
            roster: widget.draft.myRoster,
          )
          .timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      lastSaveError = e.toString();
      return false;
    }
  }

  Future<void> _startSeason() async {
    final name = teamNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a team name')),
      );
      return;
    }
    setState(() {
      isStarting = true;
      saveFailed = false;
      lastSaveError = null;
    });
    final saved = await _saveSeasonOnline(name);
    if (!mounted) return;
    setState(() {
      isStarting = false;
      saveFailed = !saved;
    });
    if (saved) {
      _startLocally();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Could not save season online: ${lastSaveError ?? 'unknown error'}')),
    );
  }

  Future<void> _retrySave() async {
    final name = teamNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      isStarting = true;
      lastSaveError = null;
    });
    final saved = await _saveSeasonOnline(name);
    if (!mounted) return;
    setState(() {
      isStarting = false;
      saveFailed = !saved;
    });
    if (saved) {
      _startLocally();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Still failed to save: ${lastSaveError ?? 'unknown error'}')),
    );
  }

  @override
  void dispose() {
    teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: AppNav.backButton(context),
        title: const Text('Name Your Team'),
        actions: [AppNav.menuButton()],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/indoor_allIN.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.72)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups,
                      color: Color(0xFFD4AF37), size: 72),
                  const SizedBox(height: 18),
                  const Text(
                    'Name Your Draft Team',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('This will appear on your Stats page.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: teamNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      hintText: 'Example: Nightmare',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isStarting ? null : _startSeason,
                      child: isStarting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('START SEASON'),
                    ),
                  ),
                  if (saveFailed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isStarting ? null : _retrySave,
                        child: const Text('RETRY ONLINE SAVE'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isStarting ? null : _startLocally,
                        child: const Text('CONTINUE OFFLINE'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEASON OVER SCREEN ───────────────────────────────────────────────────────

class SeasonOverScreen extends StatelessWidget {
  final SimViewModel sim;
  final DraftViewModel draft;

  const SeasonOverScreen(
      {super.key, required this.sim, required this.draft});

  @override
  Widget build(BuildContext context) {
    final playerWon = sim.playerTotalPoints >= sim.aiTotalPoints;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: AppNav.backButton(context),
        title: const Text('Season Over'),
        actions: [AppNav.menuButton()],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/indoor_allIN.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.72)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    playerWon
                        ? Icons.emoji_events
                        : Icons.sentiment_dissatisfied,
                    color: playerWon ? Colors.amber : Colors.grey,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    playerWon ? 'YOU WIN THE SEASON!' : 'AI WINS THE SEASON',
                    style: TextStyle(
                      color: playerWon
                          ? const Color(0xFFCC0000)
                          : Colors.grey,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Text('You  ${sim.playerTotalPoints} pts',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text('AI   ${sim.aiTotalPoints} pts',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 20)),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        draft.restartDraft();
                        sim.resetSeasonState();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      child: const Text('NEW GAME SETUP'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        draft.restartDraft();
                        sim.resetSeasonState();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      child: const Text('BACK TO HOME'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
