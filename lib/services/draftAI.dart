import '../models/wrestler.dart';

class DraftAI {
  double _value(Wrestler w) {
    return (w.inRing * 0.5) + (w.popularity * 0.3) + (w.charisma * 0.2);
  }

  String _counterClass(String dominantClass) {
    switch (dominantClass) {
      case 'Cruiser':     return 'Giant';
      case 'Bruiser':     return 'Cruiser';
      case 'Fighter':     return 'Bruiser';
      case 'Giant':       return 'Fighter';
      default:            return 'Technician';
    }
  }

  Wrestler pickWrestler(List<Wrestler> pool, List<Wrestler> playerRoster, int aiBudget) {
    // count player's class distribution
    Map<String, int> classCounts = {
      'Giant': 0, 'Cruiser': 0, 'Bruiser': 0, 'Fighter': 0, 'Technician': 0
    };
    for (var w in playerRoster) {
      classCounts[w.wrestlerClass] = (classCounts[w.wrestlerClass] ?? 0) + 1;
    }

    // find player's dominant class
    String dominant = classCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    String counter = _counterClass(dominant);

    // affordable wrestlers only
    List<Wrestler> affordable = pool.where((w) => w.salary <= aiBudget).toList();
    if (affordable.isEmpty) return pool.first;

    // prefer counter class, fall back to best value
    List<Wrestler> preferred = affordable.where((w) => w.wrestlerClass == counter).toList();
    List<Wrestler> candidates = preferred.isNotEmpty ? preferred : affordable;

    candidates.sort((a, b) => _value(b).compareTo(_value(a)));
    return candidates.first;
  }
}