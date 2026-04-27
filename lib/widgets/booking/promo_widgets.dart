import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/simVM.dart';
import '../../utils/wrestler_display.dart';
import 'booking_slot_widgets.dart';

// ─── PROMO SLOT CARD ─────────────────────────────────────────────────────────

class BookingPromoSlotCard extends StatelessWidget {
  final int index;
  final Wrestler? wrestler;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const BookingPromoSlotCard({
    super.key,
    required this.index,
    this.wrestler,
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
          border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.10),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text('PROMO SEGMENT ${index + 1}',
                      style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  const Text('OPTIONAL',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  if (wrestler != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(Icons.close,
                          color: Colors.grey, size: 16),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: wrestler == null
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('Assign Promo (Optional)',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    )
                  : Row(children: [
                      const Icon(Icons.mic, color: Colors.purple, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(wrestler!.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      BookingTag('Promo ${wrestler!.promoSkill}★',
                          color: Colors.purple.withValues(alpha: 0.3)),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROMO SHEET ─────────────────────────────────────────────────────────────

class BookingPromoSheet extends StatefulWidget {
  final SimViewModel sim;
  final int slotIndex;
  final Wrestler? initial;

  const BookingPromoSheet(
      {super.key, required this.sim, required this.slotIndex, this.initial});

  @override
  State<BookingPromoSheet> createState() => _BookingPromoSheetState();
}

class _BookingPromoSheetState extends State<BookingPromoSheet> {
  Wrestler? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.sim.availableWrestlers;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text('PROMO SEGMENT',
                      style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  const Text('Pick one wrestler',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No points scored. Recovers stamina and boosts popularity based on promo skill.',
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
                                ? Colors.purple.withValues(alpha: 0.12)
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
                              'Promo ${w.promoSkill}★  ·  STA ${w.currentStamina}/${w.stamina}  ·  Pop ${w.popularity}',
                              style: TextStyle(
                                  color: staminaColor(w.currentStamina),
                                  fontSize: 11),
                            ),
                            trailing: isSel
                                ? const Icon(Icons.check_circle,
                                    color: Colors.purple)
                                : Text(
                                    '+${w.promoSkill * 4}STA  +${w.promoSkill}Pop',
                                    style: const TextStyle(
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
                            widget.sim.setPromoSlot(
                                widget.slotIndex, selected!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selected != null ? Colors.purple : Colors.grey[850],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ASSIGN PROMO',
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
