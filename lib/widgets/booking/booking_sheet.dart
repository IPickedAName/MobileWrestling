import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/simVM.dart';
import '../../viewmodels/draft_VM.dart';
import '../champion_badge.dart';
import '../../utils/wrestler_display.dart';
import 'booking_slot_widgets.dart';

class BookingMatchSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final MatchBooking? initial;

  const BookingMatchSheet(
      {super.key, required this.sim, required this.slotIndex, this.initial});

  @override
  State<BookingMatchSheet> createState() => _BookingMatchSheetState();
}

class _BookingMatchSheetState extends State<BookingMatchSheet> {
  Wrestler? w1;
  Wrestler? w2;
  Wrestler? w3;
  Wrestler? w4;
  String matchType = 'Singles';
  Wrestler? predicted;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      w1 = widget.initial!.w1;
      w2 = widget.initial!.w2;
      w3 = widget.initial!.w3;
      w4 = widget.initial!.w4;
      matchType = widget.initial!.matchType;
      predicted = widget.initial!.predictedWinner;
    } else if (matchType == 'Championship') {
      _preloadChampionshipMatch();
    }
  }

  List<Wrestler> get _available => widget.sim.availableWrestlers;
  bool get _isTagTeam => matchType == 'Tag Team';
  int get _requiredCount => _isTagTeam ? 4 : 2;

  List<Wrestler> get _selected {
    final list = <Wrestler>[];
    if (w1 != null) list.add(w1!);
    if (w2 != null) list.add(w2!);
    if (w3 != null) list.add(w3!);
    if (w4 != null) list.add(w4!);
    return list;
  }

  bool get _canConfirm {
    if (_selected.length != _requiredCount || predicted == null) return false;
    if (_isTagTeam) {
      return predicted!.name == w1?.name || predicted!.name == w3?.name;
    }
    return predicted!.name == w1?.name || predicted!.name == w2?.name;
  }

  void _setSelectionFromList(List<Wrestler> picks) {
    w1 = picks.isNotEmpty ? picks[0] : null;
    w2 = picks.length > 1 ? picks[1] : null;
    w3 = picks.length > 2 ? picks[2] : null;
    w4 = picks.length > 3 ? picks[3] : null;
  }

  void _autoPickPrediction() {
    if (_isTagTeam) {
      predicted =
          (w1 != null && w3 != null) ? (w1!.popularity >= w3!.popularity ? w1 : w3) : null;
      return;
    }
    predicted =
        (w1 != null && w2 != null) ? (w1!.popularity >= w2!.popularity ? w1 : w2) : null;
  }

  void _onMatchTypeChanged(String nextType) {
    if (nextType == matchType) return;
    setState(() {
      matchType = nextType;
      if (matchType == 'Championship') {
        _preloadChampionshipMatch();
        return;
      }
      if (!_isTagTeam) {
        w3 = null;
        w4 = null;
        if (predicted != null &&
            predicted!.name != w1?.name &&
            predicted!.name != w2?.name) {
          predicted = null;
        }
      }
      _autoPickPrediction();
    });
  }

  void _preloadChampionshipMatch() {
    final available = _available;
    final champions = available.where((w) => w.isChampion).toList()
      ..sort((a, b) {
        int rank(String? t) {
          if (t == DraftViewModel.universalTitle) return 0;
          if (t == DraftViewModel.intercontinentalTitle) return 1;
          return 2;
        }
        final r = rank(a.championshipTitle).compareTo(rank(b.championshipTitle));
        if (r != 0) return r;
        return b.popularity.compareTo(a.popularity);
      });
    if (champions.isEmpty) return;
    final champion = champions.first;
    final contenders = available.where((w) => w.name != champion.name).toList()
      ..sort((a, b) {
        final aScore = a.popularity + a.inRing + a.charisma;
        final bScore = b.popularity + b.inRing + b.charisma;
        return bScore.compareTo(aScore);
      });
    w1 = champion;
    w2 = contenders.isNotEmpty ? contenders.first : null;
    w3 = null;
    w4 = null;
    _autoPickPrediction();
  }

  void _selectWrestler(Wrestler w) {
    setState(() {
      final picks = List<Wrestler>.from(_selected);
      final idx = picks.indexWhere((p) => p.name == w.name);
      if (idx >= 0) {
        picks.removeAt(idx);
      } else if (picks.length < _requiredCount) {
        picks.add(w);
      }
      _setSelectionFromList(picks);
      _autoPickPrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = SimViewModel.positions[widget.slotIndex];
    final available = _available;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text(position.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFFCC0000),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  Text('${_selected.length} / $_requiredCount selected',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 10),
              // Match type selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['Singles', 'Championship', 'Tag Team'].map((t) {
                    final sel = matchType == t;
                    return GestureDetector(
                      onTap: () => _onMatchTypeChanged(t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFCC0000)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.grey,
                                fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Singles predict
              if (!_isTagTeam && w1 != null && w2 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Predict: ',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      for (final w in [w1!, w2!])
                        GestureDetector(
                          onTap: () => setState(() => predicted = w),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: predicted?.name == w.name
                                  ? const Color(0xFFCC0000)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: predicted?.name == w.name
                                      ? const Color(0xFFCC0000)
                                      : Colors.transparent),
                            ),
                            child: Text(w.name.split(' ').first,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              // Tag team predict
              if (_isTagTeam &&
                  w1 != null &&
                  w2 != null &&
                  w3 != null &&
                  w4 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Predict team: ',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      for (final leader in [w1!, w3!])
                        Flexible(
                          child: GestureDetector(
                            onTap: () => setState(() => predicted = leader),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: predicted?.name == leader.name
                                    ? const Color(0xFFCC0000)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                leader.name == w1!.name
                                    ? '${w1!.name.split(' ').first} & ${w2?.name.split(' ').first ?? ''}'
                                    : '${w3!.name.split(' ').first} & ${w4?.name.split(' ').first ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
              // Wrestler list
              Expanded(
                child: available.isEmpty
                    ? const Center(
                        child: Text('No wrestlers available',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: available.length,
                        itemBuilder: (ctx, i) {
                          final w = available[i];
                          final selectedIndex =
                              _selected.indexWhere((s) => s.name == w.name);
                          final isSelected = selectedIndex >= 0;
                          return ListTile(
                            onTap: () => _selectWrestler(w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tileColor: isSelected
                                ? const Color(0xFFCC0000)
                                    .withValues(alpha: 0.12)
                                : null,
                            title: Text(w.name,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(
                              '${w.wrestlerClass}  ·  Ring ${w.inRing}  ·  Pop ${w.popularity}  ·  STA ${w.currentStamina}/${w.stamina}',
                              style: TextStyle(
                                  color: staminaColor(w.currentStamina),
                                  fontSize: 11),
                            ),
                            trailing: isSelected
                                ? BookingCircleBadge(
                                    '${selectedIndex + 1}',
                                    const Color(0xFFCC0000))
                                : null,
                          );
                        },
                      ),
              ),
              // Confirm button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canConfirm
                        ? () {
                            widget.sim.setSlot(
                              widget.slotIndex,
                              w1!,
                              w2!,
                              matchType,
                              predicted!,
                              w3: w3,
                              w4: w4,
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canConfirm
                          ? const Color(0xFFCC0000)
                          : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('CONFIRM MATCH',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
