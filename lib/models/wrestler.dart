class Wrestler {
  final String name;
  final String promotion;
  final String role;
  final String wrestlerClass;
  final int inRing;
  final int charisma;
  final int promoSkill;
  int popularity;
  int morale;
  int stamina;
  int currentStamina;
  final int salary;
  int contractWeeks;
  int momentum;
  int matchesThisWeek;
  Map<String, int> feudHistory;
  String? championshipTitle;

  Wrestler({
    required this.name,
    required this.promotion,
    required this.role,
    required this.wrestlerClass,
    required this.inRing,
    required this.charisma,
    required this.promoSkill,
    required this.popularity,
    required this.morale,
    required this.stamina,
    required this.currentStamina,
    required this.salary,
    required this.contractWeeks,
    this.momentum = 0,
    this.matchesThisWeek = 0,
    Map<String, int>? feudHistory,
    this.championshipTitle,
  }) : feudHistory = feudHistory ?? {};

  factory Wrestler.fromJson(Map<String, dynamic> json) {
    return Wrestler(
      name:           json['name'],
      promotion:      json['promotion'],
      role:           json['role'],
      wrestlerClass:  json['class'],
      inRing:         json['inRing'],
      charisma:       json['charisma'],
      promoSkill:     json['promoSkill'],
      popularity:     json['popularity'],
      morale:         json['morale'],
      stamina:        json['stamina'],
      currentStamina: json['currentStamina'],
      salary:         json['salary'],
      contractWeeks:  json['contractWeeks'],
      momentum:       json['momentum'] ?? 0,
    );
  }

  bool get isChampion => championshipTitle != null;

  // effective inRing accounting for stamina drain
  int get effectiveInRing {
    if (currentStamina >= 75) return inRing;
    if (currentStamina >= 50) return inRing - 5;
    if (currentStamina >= 25) return inRing - 12;
    return 0; // cannot be booked below 25
  }

  bool get canBeBooked => currentStamina >= 25;

  // record a feud encounter with another wrestler
  void addFeudalEncounter(String opponentName) {
    feudHistory[opponentName] = (feudHistory[opponentName] ?? 0) + 1;
  }

  int feudEncountersWith(String opponentName) {
    return feudHistory[opponentName] ?? 0;
  }
}