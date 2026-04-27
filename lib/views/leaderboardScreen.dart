import 'package:flutter/material.dart';
import '../firestore_service.dart';
import '../theme/game_theme.dart';
import 'appDrawer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _firestore.getMyLeaderboardStanding(),
            builder: (context, snapshot) {
              final me = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              if (me == null) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GameTheme.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GameTheme.stroke),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Play at least one week to appear on the global leaderboard.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF132035),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${me['rank']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me['displayName']?.toString() ?? 'You',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            me['teamName']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${me['totalPoints'] ?? 0} pts',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.watchGlobalLeaderboard(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No leaderboard entries yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                entries.sort((a, b) {
                  final p = (b['totalPoints'] as num? ?? 0).toInt().compareTo((a['totalPoints'] as num? ?? 0).toInt());
                  if (p != 0) return p;
                  final w = (b['wins'] as num? ?? 0).toInt().compareTo((a['wins'] as num? ?? 0).toInt());
                  if (w != 0) return w;
                  return (b['averageRating'] as num? ?? 0).toDouble().compareTo((a['averageRating'] as num? ?? 0).toDouble());
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final rank = i + 1;
                    final top3 = rank <= 3;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: GameTheme.panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: top3 ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : GameTheme.stroke,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: top3 ? const Color(0xFFD4AF37) : Colors.white70,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['displayName']?.toString() ?? 'Unknown Booker',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  e['teamName']?.toString() ?? 'Unknown Team',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(e['totalPoints'] as num? ?? 0).toInt()} pts',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'W ${(e['wins'] as num? ?? 0).toInt()} / L ${(e['losses'] as num? ?? 0).toInt()}',
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
