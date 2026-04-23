import 'package:flutter/material.dart';
import 'auth_viewmodel.dart';
import 'login_screen.dart';
import 'draft_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final authViewModel = AuthViewModel();
    await authViewModel.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
              backgroundColor: color.withOpacity(0.18),
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
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _homeCard(
            context: context,
            icon: Icons.groups,
            title: 'Draft Screen',
            subtitle: 'Browse wrestlers and start building your roster',
            color: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DraftScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View bio, avatar, and account details',
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.bar_chart,
            title: 'Stats',
            subtitle: 'See wrestler rankings and summary stats',
            color: Colors.greenAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.cloud_upload,
            title: 'Upload Wrestlers to Firestore',
            subtitle: 'Run once to move your JSON into Firebase',
            color: Colors.orangeAccent,
            onTap: () async {
              await FirestoreService().uploadWrestlersFromJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wrestlers uploaded to Firestore'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 14),
          _homeCard(
            context: context,
            icon: Icons.sports_kabaddi,
            title: 'Book Matches',
            subtitle: 'Coming next',
            color: Colors.purpleAccent,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}