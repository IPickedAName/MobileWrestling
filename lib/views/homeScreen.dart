import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_viewmodel.dart';
import '../firestore_service.dart';
import '../viewmodels/draft_VM.dart';
import 'appDrawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _modePanel(BuildContext context, DraftViewModel vm) {
    final locked = vm.draftComplete;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vm.isArcadeMode ? const Color(0xFFfacc15) : Colors.white12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
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
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
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

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Season Hub'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, Booker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your roster, build your card, and dominate the season.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _modePanel(context, draft),
          const SizedBox(height: 14),
          _budgetPanel(context, draft),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.groups,
            title: 'Draft',
            subtitle: 'Browse wrestlers and build your roster',
            color: Colors.redAccent,
            onTap: () => Navigator.pushNamed(context, '/draft'),
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.sports_kabaddi,
            title: 'Book Matches',
            subtitle: 'Set up your card and run the show',
            color: Colors.purpleAccent,
            onTap: () => Navigator.pushNamed(context, '/booking'),
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.bar_chart,
            title: 'Stats',
            subtitle: 'Wrestler rankings and season summaries',
            color: Colors.greenAccent,
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View your bio, avatar, and account details',
            color: Colors.blueAccent,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.cloud_upload,
            title: 'Upload Wrestlers to Firestore',
            subtitle: 'Run once to seed Firebase from your JSON',
            color: Colors.orangeAccent,
            onTap: () async {
              await FirestoreService().uploadWrestlersFromJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrestlers uploaded to Firestore')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
