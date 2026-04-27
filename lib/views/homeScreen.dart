import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_viewmodel.dart';
import '../firestore_service.dart';
import '../viewmodels/draft_VM.dart';
import '../viewmodels/simVM.dart';
import '../theme/game_theme.dart';
import 'appDrawer.dart';
import '../widgets/app_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF95A0B3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _hero(DraftViewModel vm) {
    final locked = vm.myRoster.isNotEmpty || vm.draftComplete;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3B1A26)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/pyro_entrance.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x66000000), Color(0xCC0B1220)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Build Your Next Promotion Run',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locked
                        ? 'Draft is in progress or complete. Restart draft to change setup options.'
                        : 'Pick your mode and budget first, then start drafting your roster.',
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _pill('Mode: ${vm.gameModeLabel}', vm.isArcadeMode ? GameTheme.warn : Colors.white70),
                      _pill('Budget: ${DraftViewModel.toM(vm.startingBudget)}', GameTheme.ok),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _modePanel(BuildContext context, DraftViewModel vm) {
    final locked = vm.draftComplete;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vm.isArcadeMode ? const Color(0xFFfacc15).withOpacity(0.55) : GameTheme.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports, color: Color(0xFFfacc15), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Game Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                vm.gameModeLabel,
                style: TextStyle(
                  color: vm.isArcadeMode ? const Color(0xFFfacc15) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Arcade gives more cash, easier transfers, and lighter stamina pressure.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Standard'),
                selected: !vm.isArcadeMode,
                onSelected: locked ? null : (_) => vm.setGameMode(GameMode.standard),
                selectedColor: Colors.white24,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              ChoiceChip(
                label: const Text('Arcade'),
                selected: vm.isArcadeMode,
                onSelected: locked ? null : (_) => vm.setGameMode(GameMode.arcade),
                selectedColor: const Color(0xFF8B6B00),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: 10),
            const Text(
              'Mode is locked after draft completion. Restart draft to switch.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _budgetPanel(BuildContext context, DraftViewModel vm) {
    final locked = vm.myRoster.isNotEmpty || vm.draftComplete;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GameTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameTheme.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF4ade80), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Starting Budget',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DraftViewModel.toM(vm.startingBudget),
                style: const TextStyle(color: Color(0xFF4ade80), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Higher budget = more expensive championship & tag matches.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(DraftViewModel.budgetPresets.length, (i) {
              final budget = DraftViewModel.budgetPresets[i];
              final label = DraftViewModel.budgetPresetLabels[i];
              final selected = vm.startingBudget == budget;
              return ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.white70)),
                selected: selected,
                onSelected: locked ? null : (_) => vm.setBudgetPreset(budget),
                selectedColor: const Color(0xFF1B4332),
                backgroundColor: const Color(0xFF2A2A2A),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            locked
                ? 'Budget is locked once the draft starts.'
                : 'Championship: -${DraftViewModel.toM((vm.startingBudget * 0.01).round())} / week booked   •   Tag Team: -${DraftViewModel.toM((vm.startingBudget * 0.005).round())} / week booked',
            style: TextStyle(
              color: locked ? Colors.orangeAccent : Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    context.read<DraftViewModel>().restartDraft();
    context.read<SimViewModel>().resetSeasonState();
    final auth = AuthViewModel();
    await auth.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _homeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GameTheme.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameTheme.stroke),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _uploadUtilityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameTheme.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Utility',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  'Upload wrestlers JSON to Firestore (one-time setup)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () async {
              await FirestoreService().uploadWrestlersFromJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrestlers uploaded to Firestore')),
                );
              }
            },
            child: const Text('UPLOAD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftViewModel>();
    final setupLocked = draft.myRoster.isNotEmpty || draft.draftComplete;
    return Scaffold(
      backgroundColor: GameTheme.bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Season Hub'),
        leading: IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
        actions: [
          AppNav.menuButton(),
          AppNav.backButton(context, fallbackRoute: '/welcome'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          _hero(draft),
          const SizedBox(height: 28),

          _sectionLabel('Game Setup'),
          _modePanel(context, draft),
          const SizedBox(height: 18),
          _budgetPanel(context, draft),
          if (!setupLocked)
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 2),
              child: Text(
                'Setup unlocks your economy style before draft. Once picks start, setup locks.',
                style: TextStyle(color: Color(0xFF95A0B3), fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),

          _sectionLabel('Promotion Circuit'),
          _homeCard(
            context: context,
            icon: Icons.groups,
            title: 'Draft',
            subtitle: 'Browse wrestlers and build your roster',
            color: Colors.redAccent,
            onTap: () => Navigator.pushNamed(context, '/draft'),
          ),
          const SizedBox(height: 18),
          _homeCard(
            context: context,
            icon: Icons.sports_kabaddi,
            title: 'Book Matches',
            subtitle: 'Set up your card and run the show',
            color: Colors.purpleAccent,
            onTap: () => Navigator.pushNamed(context, '/booking'),
          ),
          const SizedBox(height: 18),
          _homeCard(
            context: context,
            icon: Icons.bar_chart,
            title: 'Stats',
            subtitle: 'Wrestler rankings and season summaries',
            color: Colors.greenAccent,
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),
          const SizedBox(height: 18),
          _homeCard(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View your bio, avatar, and account details',
            color: Colors.blueAccent,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),

          const SizedBox(height: 24),

          _sectionLabel('Utilities'),
          const SizedBox(height: 6),
          _uploadUtilityCard(context),
        ],
      ),
    );
  }
}
