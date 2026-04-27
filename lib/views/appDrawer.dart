import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final current = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: GameTheme.bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WRESTLER HQ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6)),
                  SizedBox(height: 4),
                  Text('Fantasy Booker Control Room',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _SectionTitle('Promotion Circuit'),

            _NavItem(
              icon: Icons.home,
              label: 'Home',
              route: '/home',
              current: current,
            ),
            _NavItem(
              icon: Icons.groups,
              label: 'Draft',
              route: '/draft',
              current: current,
            ),
            _NavItem(
              icon: Icons.sports_kabaddi,
              label: 'Book Matches',
              route: '/booking',
              current: current,
            ),
            _NavItem(
              icon: Icons.bar_chart,
              label: 'Stats',
              route: '/stats',
              current: current,
            ),
            _NavItem(
              icon: Icons.emoji_events,
              label: 'Leaderboard',
              route: '/leaderboard',
              current: current,
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              route: '/profile',
              current: current,
            ),

            const Divider(color: GameTheme.stroke),

            _SectionTitle('Navigation'),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Text(
                'Use Home to set mode and budget before Draft.',
                style: TextStyle(color: Color(0xFF8B95A7), fontSize: 11),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8B95A7),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String? current;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.current,
  });

  bool get _isActive => current == route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (_isActive ? GameTheme.accent : Colors.white).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _isActive ? GameTheme.accent : Colors.white70,
            size: 18,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: _isActive ? Colors.white : Colors.white70,
            fontWeight: _isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        tileColor: _isActive ? const Color(0xFF1C2335) : const Color(0xFF111522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isActive ? GameTheme.accent.withOpacity(0.35) : GameTheme.stroke,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!_isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}