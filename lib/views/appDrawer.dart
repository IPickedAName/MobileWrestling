import 'package:flutter/material.dart';
import '../firestore_service.dart';
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
                  colors: [Color(0xFF8B0D18), Color(0xFF173256)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: FirestoreService().getProfile(),
                    builder: (context, snapshot) {
                      final profile = snapshot.data ?? const <String, dynamic>{};
                      final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
                          ? profile['name'].toString().trim()
                          : 'Guest Booker';
                      final email = profile['email']?.toString() ?? 'Local session';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0B84B).withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user, color: Color(0xFFE0B84B), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text(email,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
            color: (_isActive ? GameTheme.accentAlt : Colors.white).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _isActive ? GameTheme.accentAlt : Colors.white70,
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
        tileColor: _isActive ? const Color(0xFF22324B) : GameTheme.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isActive ? GameTheme.accentAlt.withOpacity(0.45) : GameTheme.stroke,
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