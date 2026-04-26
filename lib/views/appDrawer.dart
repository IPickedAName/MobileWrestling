import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final current = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: ListView( // 🔥 FIX: was Column → now scrollable
          padding: EdgeInsets.zero,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('wRESTler',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Fantasy Booker',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 8),

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
              icon: Icons.person,
              label: 'Profile',
              route: '/profile',
              current: current,
            ),

            const Divider(color: Color(0xFF2A2A2A)),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Season Hub',
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
            ),
          ],
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
    return ListTile(
      leading: Icon(
        icon,
        color: _isActive ? const Color(0xFFCC0000) : Colors.white60,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: _isActive ? Colors.white : Colors.white70,
          fontWeight: _isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      tileColor: _isActive
          ? const Color(0xFFCC0000).withOpacity(0.08) // 🔥 fix deprecated call
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!_isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}