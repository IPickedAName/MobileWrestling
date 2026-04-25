import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/draft_VM.dart';
import '../models/wrestler.dart';
import '../widgets/champion_badge.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  String _lastShownMessage = '';

  Color _classColor(String wrestlerClass) {
    switch (wrestlerClass) {
      case 'Giant':      return const Color(0xFF8B0000);
      case 'Cruiser':    return const Color(0xFF00008B);
      case 'Bruiser':    return const Color(0xFF4B0082);
      case 'Fighter':    return const Color(0xFF006400);
      case 'Technician': return const Color(0xFF8B4513);
      default:           return Colors.grey.shade800;
    }
  }

  void _showPickToast(BuildContext context, String message) {
    if (message.isEmpty || message == _lastShownMessage) return;
    _lastShownMessage = message;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF2a2a2a),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DraftViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.lastPickMessage.isNotEmpty) {
        _showPickToast(context, vm.lastPickMessage);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, vm),
            _turnBanner(vm),
            _rosterCounts(vm),
            if (vm.showEndButton) _endDraftButton(context, vm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('AVAILABLE WRESTLERS',
                  style: TextStyle(color: Colors.grey, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
            ),
            Expanded(
              child: vm.draftComplete
                ? _draftDoneCard(context, vm)
                : _wrestlerPool(vm),
            ),
            _rosterPreviews(vm),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DraftViewModel vm) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                child: const Icon(Icons.home_outlined, color: Colors.white54, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Snake Draft',
                style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w600)),
            ],
          ),
          Row(children: [
            Text('Pick ${vm.pickNumber}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 8),
            if (!vm.draftComplete)
              GestureDetector(
                onTap: () {
                  _lastShownMessage = '';
                  vm.autoDraft();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a3a1a),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4ade80), width: 0.5)),
                  child: const Text('⚡ Auto Draft',
                    style: TextStyle(color: Color(0xFF4ade80), fontSize: 12,
                      fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _lastShownMessage = '';
                vm.restartDraft();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF555555), width: 0.5)),
                child: const Row(children: [
                  Text('↺ ',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                  Text('Restart',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _turnBanner(DraftViewModel vm) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: vm.draftComplete
            ? const Color(0xFF1a3a1a)
            : vm.isMyTurn
                ? const Color(0xFFe24b4a)
                : const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            vm.draftComplete ? 'DRAFT COMPLETE'
              : vm.isMyTurn ? 'YOUR PICK' : 'AI IS PICKING...',
            style: TextStyle(
              color: vm.draftComplete
                ? const Color(0xFF4ade80) : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text('Budget: ${vm.myBudgetDisplay}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _rosterCounts(DraftViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Expanded(child: _countCard('YOUR ROSTER',
          vm.myRoster.length, const Color(0xFFe24b4a))),
        const SizedBox(width: 8),
        Expanded(child: _countCard('AI ROSTER',
          vm.aiRoster.length, Colors.grey)),
      ]),
    );
  }

  Widget _countCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text('$count',
          style: TextStyle(color: color, fontSize: 20,
            fontWeight: FontWeight.w600)),
        const Text('picked',
          style: TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }

  Widget _endDraftButton(BuildContext context, DraftViewModel vm) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTap: () => _confirmEndDraft(context, vm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1a3a1a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4ade80), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                color: Color(0xFF4ade80), size: 16),
              const SizedBox(width: 6),
              Text(
                'End Draft  (${vm.myRoster.length} wrestlers — min 10 reached)',
                style: const TextStyle(color: Color(0xFF4ade80),
                  fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEndDraft(BuildContext context, DraftViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        title: const Text('End Draft?',
          style: TextStyle(color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.w600)),
        content: Text(
          'You have ${vm.myRoster.length} wrestlers and '
          '${vm.myBudgetDisplay} remaining.\n\n'
          'Are you sure you want to lock your roster?',
          style: const TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Drafting',
              style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.playerEndsDraft();
            },
            child: const Text('Lock Roster',
              style: TextStyle(color: Color(0xFF4ade80),
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _wrestlerPool(DraftViewModel vm) {
    if (vm.pool.isEmpty) {
      return const Center(
      child: Text('Pool empty',
        style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vm.pool.length,
      itemBuilder: (ctx, i) => _wrestlerTile(vm, vm.pool[i]),
    );
  }

  Widget _wrestlerTile(DraftViewModel vm, Wrestler w) {
    final affordable = vm.canAfford(w);
    final canDraft = vm.isMyTurn && affordable && !vm.draftComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2a2a2a), width: 0.5),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _classColor(w.wrestlerClass),
          child: Text(
            w.name.split(' ').map((e) => e[0]).take(2).join(),
            style: const TextStyle(color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.name,
                style: TextStyle(
                  color: affordable ? Colors.white : Colors.grey,
                  fontSize: 13, fontWeight: FontWeight.w500)),
              if (w.isChampion) ...[
                const SizedBox(height: 3),
                ChampionBadge(label: w.championshipTitle),
              ],
              const SizedBox(height: 2),
              Row(children: [
                _pill(w.promotion, w.promotion == 'WWE'
                  ? const Color(0xFFe24b4a)
                  : const Color(0xFFfbbf24)),
                const SizedBox(width: 4),
                _pill(w.wrestlerClass, _classColor(w.wrestlerClass)),
                const SizedBox(width: 6),
                Text(
                  'IR ${w.inRing}  POP ${w.popularity}'
                  '  STA ${w.currentStamina}',
                  style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
              ]),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(DraftViewModel.toM(w.salary),
            style: TextStyle(
              color: affordable
                ? const Color(0xFF4ade80) : Colors.grey,
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (canDraft)
            GestureDetector(
              onTap: () => vm.playerPicks(w),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFe24b4a),
                  borderRadius: BorderRadius.circular(6)),
                child: const Text('Draft',
                  style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            )
          else if (!affordable)
            const Text('Over budget',
              style: TextStyle(color: Colors.grey, fontSize: 10))
          else if (!vm.isMyTurn)
            const Text('AI turn',
              style: TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 9,
          fontWeight: FontWeight.w600)),
    );
  }

  Widget _rosterPreviews(DraftViewModel vm) {
    if (vm.myRoster.isEmpty && vm.aiRoster.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YOUR side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFe24b4a),
                      shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('YOUR ROSTER',
                    style: TextStyle(color: Color(0xFFe24b4a),
                      fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                SizedBox(
                  height: 58,
                  child: vm.myRoster.isEmpty
                    ? const Center(child: Text('None yet',
                        style: TextStyle(color: Colors.grey,
                          fontSize: 11)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.myRoster.length,
                        itemBuilder: (ctx, i) => _rosterChip(
                          vm.myRoster[i],
                          const Color(0xFF1a2a1a),
                          const Color(0xFF4ade80),
                          Colors.white,
                        ),
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 70,
            color: const Color(0xFF2a2a2a),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          // AI side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('AI ROSTER',
                    style: TextStyle(color: Colors.grey,
                      fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                SizedBox(
                  height: 58,
                  child: vm.aiRoster.isEmpty
                    ? const Center(child: Text('Waiting...',
                        style: TextStyle(color: Colors.grey,
                          fontSize: 11)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.aiRoster.length,
                        itemBuilder: (ctx, i) => _rosterChip(
                          vm.aiRoster[i],
                          const Color(0xFF2a2a2a),
                          Colors.grey,
                          Colors.grey,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rosterChip(Wrestler w, Color bg,
      Color salaryColor, Color nameColor) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: salaryColor.withOpacity(0.3), width: 0.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.name.split(' ').first,
            style: TextStyle(color: nameColor, fontSize: 11)),
          if (w.isChampion)
            const ChampionBadge(compact: true),
          Text(DraftViewModel.toM(w.salary),
            style: TextStyle(color: salaryColor, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _draftDoneCard(BuildContext context, DraftViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Draft Complete!',
            style: TextStyle(color: Color(0xFF4ade80), fontSize: 22,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Your roster: ${vm.myRoster.length} wrestlers',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Budget remaining: ${vm.myBudgetDisplay}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/booking'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFe24b4a),
                borderRadius: BorderRadius.circular(10)),
              child: const Text('Book Your Card →',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}