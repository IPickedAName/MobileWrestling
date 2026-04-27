import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/simVM.dart';
import '../../utils/wrestler_display.dart';
import 'booking_slot_widgets.dart';

// ─── REST SLOT CARD ─────────────────────────────────────────────────────────

class BookingRestSlotCard extends StatelessWidget {
  final int index;
  final RestBooking? booking;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const BookingRestSlotCard({
    super.key,
    required this.index,
    this.booking,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.10),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Text('REST SLOT ${index + 1}',
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5)),
                const Spacer(),
                const Text('OPTIONAL',
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                if (booking != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close,
                        color: Colors.grey, size: 16),
                  ),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: booking == null
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bedtime_outlined,
                            color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('Assign Rest (+20 STA)',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    )
                  : Row(children: [
                      const Icon(Icons.hotel,
                          color: Colors.tealAccent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(booking!.wrestler.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      BookingTag('+${booking!.recoveryAmount} STA',
                          color: Colors.teal.withValues(alpha: 0.3)),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REST SHEET ─────────────────────────────────────────────────────────────

class BookingRestSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final Wrestler? initial;

  const BookingRestSheet(
      {super.key, required this.sim, required this.slotIndex, this.initial});

  @override
  State<BookingRestSheet> createState() => _BookingRestSheetState();
}

class _BookingRestSheetState extends State<BookingRestSheet> {
  Wrestler? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.sim.availableWrestlers.toList()
      ..sort((a, b) => a.currentStamina.compareTo(b.currentStamina));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text('REST SLOT',
                      style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                  Spacer(),
                  Text('Pick one wrestler',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Rested wrestlers skip the show and recover a big chunk of stamina.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 20),
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
                          final isSel = w.name == selected?.name;
                          return ListTile(
                            onTap: () =>
                                setState(() => selected = isSel ? null : w),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            tileColor: isSel
                                ? Colors.teal.withValues(alpha: 0.12)
                                : null,
                            title: Text(w.name,
                                style: TextStyle(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(
                              '${w.wrestlerClass}  ·  STA ${w.currentStamina}/${w.stamina}  ·  ${staminaLabel(w.currentStamina)}',
                              style: TextStyle(
                                  color: staminaColor(w.currentStamina),
                                  fontSize: 11),
                            ),
                            trailing: isSel
                                ? const Icon(Icons.check_circle,
                                    color: Colors.tealAccent)
                                : const Text('+20 STA',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected != null
                        ? () {
                            widget.sim.setRestSlot(
                                widget.slotIndex, selected!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selected != null ? Colors.teal : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ASSIGN REST',
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
