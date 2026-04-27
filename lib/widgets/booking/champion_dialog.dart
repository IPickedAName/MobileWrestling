import 'package:flutter/material.dart';
import '../../models/wrestler.dart';
import '../../viewmodels/draft_VM.dart';
import '../../viewmodels/simVM.dart';

class ChampionSelectionDialog extends StatefulWidget {
  final DraftViewModel draft;
  final SimViewModel sim;

  const ChampionSelectionDialog(
      {super.key, required this.draft, required this.sim});

  @override
  State<ChampionSelectionDialog> createState() =>
      _ChampionSelectionDialogState();
}

class _ChampionSelectionDialogState extends State<ChampionSelectionDialog> {
  Wrestler? universalChampion;
  Wrestler? intercontinentalChampion;

  @override
  void initState() {
    super.initState();
    final ranked = List<Wrestler>.from(widget.draft.myRoster)
      ..sort((a, b) {
        final aScore = (a.popularity * 2) + a.inRing + a.charisma;
        final bScore = (b.popularity * 2) + b.inRing + b.charisma;
        return bScore.compareTo(aScore);
      });
    if (ranked.isNotEmpty) universalChampion = ranked.first;
    if (ranked.length > 1) intercontinentalChampion = ranked[1];
  }

  @override
  Widget build(BuildContext context) {
    final roster = widget.draft.myRoster;
    final canConfirm = universalChampion != null &&
        intercontinentalChampion != null &&
        universalChampion!.name != intercontinentalChampion!.name;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Assign Your Champions',
          style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose two wrestlers from your roster before booking your first show.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Universal Title',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Wrestler>(
                initialValue: universalChampion,
                dropdownColor: const Color(0xFF2A2A2A),
                decoration: _champFieldDecoration(),
                items: roster
                    .map((w) => DropdownMenuItem<Wrestler>(
                          value: w,
                          child: Text(w.name,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => universalChampion = value),
              ),
              const SizedBox(height: 14),
              const Text('Intercontinental Title',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Wrestler>(
                initialValue: intercontinentalChampion,
                dropdownColor: const Color(0xFF2A2A2A),
                decoration: _champFieldDecoration(),
                items: roster
                    .map((w) => DropdownMenuItem<Wrestler>(
                          value: w,
                          child: Text(w.name,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => intercontinentalChampion = value),
              ),
              if (universalChampion != null &&
                  intercontinentalChampion != null &&
                  universalChampion!.name == intercontinentalChampion!.name) ...[
                const SizedBox(height: 10),
                const Text('Pick two different wrestlers.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: canConfirm
              ? () {
                  widget.draft.assignChampions(
                    universalChampion: universalChampion!,
                    intercontinentalChampion: intercontinentalChampion!,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Confirm',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  InputDecoration _champFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF111111),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCC0000)),
      ),
    );
  }
}
