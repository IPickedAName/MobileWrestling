import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simVM.dart';
import '../viewmodels/draft_VM.dart';
import '../firestore_service.dart';
import '../theme/game_theme.dart';
import 'appDrawer.dart';
import '../widgets/app_nav.dart';
import '../widgets/booking/champion_dialog.dart';
import '../widgets/booking/booking_slot_widgets.dart';
import '../widgets/booking/simulate_bar.dart';
import '../widgets/booking/booking_sheet.dart';
import '../widgets/booking/promo_widgets.dart';
import '../widgets/booking/rest_widgets.dart';
import 'season_screens.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _showingChampionDialog = false;
  static const Color _aewGold = Color(0xFFD4AF37);

  void _maybeHandleSeasonSetup(
  BuildContext context,
  SimViewModel sim,
  DraftViewModel draft,
) {
  if (sim.seasonStarted || !draft.draftComplete) return;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted || sim.seasonStarted) return;

    if (draft.needsChampionSelection) {
      if (_showingChampionDialog) return;

      _showingChampionDialog = true;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ChampionSelectionDialog(draft: draft, sim: sim),
      );

      _showingChampionDialog = false;
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Consumer2<SimViewModel, DraftViewModel>(
      builder: (context, sim, draft, _) {
        _maybeHandleSeasonSetup(context, sim, draft);

        if (!draft.draftComplete) return const _NoDraftScreen();
        if (!sim.seasonStarted && !draft.needsChampionSelection) {
          return TeamNameStartScreen(sim: sim, draft: draft);
        }
        if (sim.seasonOver) return SeasonOverScreen(sim: sim, draft: draft);


        return Scaffold(
          backgroundColor: GameTheme.bg,
          drawer: const AppDrawer(),
          appBar: AppBar(
            leading: AppNav.backButton(context),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Book Your Card',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _aewGold)),
                Text('Week ${sim.currentWeek} of ${sim.totalWeeks}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE6D7A3))),
              ],
            ),
            actions: [
              AppNav.menuButton(),
              IconButton(
                tooltip: 'Auto book',
                onPressed: sim.seasonStarted && !sim.weekSimulated
                    ? () => sim.autoBookCard()
                    : null,
                icon: const Icon(Icons.auto_fix_high),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1A1A1A),
                onSelected: (value) async {
                  switch (value) {
                    case 'autoWeek':
                      final historyBefore = sim.history.length;
                      sim.autoFinishWeek();
                      if (sim.history.length > historyBefore) {
                        final summary = sim.history.last;
                        draft.applyWeeklyFinance(
                          week: summary.week,
                          playerPoints: summary.playerPoints,
                          aiPoints: summary.aiPoints,
                          avgRating: summary.avgRating,
                          matchRevenue: summary.matchRevenue,
                          cardCost: summary.cardCost,
                        );
                        try {
                          await FirestoreService().recordWeeklyStats(
                            weekNumber: summary.week,
                            playerPoints: summary.playerPoints,
                            aiPoints: summary.aiPoints,
                            avgRating: summary.avgRating,
                          );
                        } catch (_) {
                          // Local simulation still works without Firebase sync.
                        }
                      }
                      if (sim.weekSimulated && context.mounted) {
                        Navigator.pushNamed(context, '/results');
                      }
                      break;
                    case 'skipSeason':
                      final historyBefore = sim.history.length;
                      sim.autoPlayToSeasonEnd();
                      for (int i = historyBefore; i < sim.history.length; i++) {
                        final summary = sim.history[i];
                        draft.applyWeeklyFinance(
                          week: summary.week,
                          playerPoints: summary.playerPoints,
                          aiPoints: summary.aiPoints,
                          avgRating: summary.avgRating,
                          matchRevenue: summary.matchRevenue,
                          cardCost: summary.cardCost,
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'autoWeek',
                    child: Text('Dev: Auto Finish Week',
                        style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'skipSeason',
                    child: Text('Dev: Skip To End Of Season',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              BookingScoreBar(playerPts: sim.playerTotalPoints, aiPts: sim.aiTotalPoints),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF131A29), Color(0xFF0F1422)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roster: ${sim.playerRoster.length} total  •  ${sim.availableWrestlers.length} available this week',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cash: ${draft.seasonCashDisplay}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4ade80),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${draft.gameModeLabel}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: draft.isArcadeMode
                            ? const Color(0xFFfacc15)
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sim.playerRoster.where((w) => w.currentStamina < 50).length} below 50 stamina — use promo/rest slots to recover.',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (int i = 0; i < 4; i++)
                      BookingSlotCard(
                        index: i,
                        booking: sim.card[i],
                        position: SimViewModel.positions[i],
                        cost: draft.matchCostFor(sim.card[i]?.matchType ?? ''),
                        onTap: () => _openSheet(context, sim, i),
                        onClear: () => sim.clearSlot(i),
                      ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Text('PROMO SEGMENTS  â€”  OPTIONAL',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.4)),
                  ),
                  for (int i = 0; i < 2; i++)
                    BookingPromoSlotCard(
                      index: i,
                      wrestler: sim.promos[i]?.wrestler,
                      onTap: () => _openPromoSheet(context, sim, i),
                      onClear: () => sim.clearPromoSlot(i),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Text('REST SLOTS  â€”  RECOVERY',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.4)),
                  ),
                  for (int i = 0; i < 2; i++)
                    BookingRestSlotCard(
                      index: i,
                      booking: sim.rests[i],
                      onTap: () => _openRestSheet(context, sim, i),
                      onClear: () => sim.clearRestSlot(i),
                    ),
                  ],
                ),
              ),
              BookingSimulateBar(sim: sim, draft: draft),
            ],
          ),
        );
      },
    );
  }

  void _openPromoSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.promos[index];
    if (existing != null) sim.clearPromoSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingPromoSheet(sim: sim, slotIndex: index, initial: existing?.wrestler),
    ).then((_) {
      if (sim.promos[index] == null && existing != null) {
        sim.setPromoSlot(index, existing.wrestler);
      }
    });
  }

  void _openRestSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.rests[index];
    if (existing != null) sim.clearRestSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingRestSheet(sim: sim, slotIndex: index, initial: existing?.wrestler),
    ).then((_) {
      if (sim.rests[index] == null && existing != null) {
        sim.setRestSlot(index, existing.wrestler, recoveryAmount: existing.recoveryAmount);
      }
    });
  }

  void _openSheet(BuildContext context, SimViewModel sim, int index) {
    final existing = sim.card[index];
    if (existing != null) sim.clearSlot(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingMatchSheet(sim: sim, slotIndex: index, initial: existing),
    ).then((_) {
      // Restore old booking if user dismissed without confirming
      if (sim.card[index] == null && existing != null) {
        sim.setSlot(
          index,
          existing.w1,
          existing.w2,
          existing.matchType,
          existing.predictedWinner,
          w3: existing.w3,
          w4: existing.w4,
        );
      }
    });
  }
}

// ─── FALLBACK SCREENS ─────────────────────────────────────────────────────────

class _NoDraftScreen extends StatelessWidget {
  const _NoDraftScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: AppNav.backButton(context),
        title: const Text('Book Your Card'),
        actions: [AppNav.menuButton()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey, size: 52),
            const SizedBox(height: 16),
            const Text('Complete the draft first',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/draft'),
              child: const Text('GO TO DRAFT'),
            ),
          ],
        ),
      ),
    );
  }
}
