import 'package:flutter/material.dart';

Color staminaColor(int stamina) {
  if (stamina >= 75) return const Color(0xFF4ade80);
  if (stamina >= 50) return const Color(0xFFfacc15);
  if (stamina >= 25) return const Color(0xFFfb923c);
  return const Color(0xFFef4444);
}

String staminaLabel(int stamina) {
  if (stamina >= 75) return 'Fresh';
  if (stamina >= 50) return 'Manage';
  if (stamina >= 25) return 'Risk';
  return 'Exhausted';
}
