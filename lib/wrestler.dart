class Wrestler {
  final String name;
  final String promotion;
  final String role;
  final String wrestlerClass;
  final int inRing;
  final int charisma;
  final int promoSkill;
  final int popularity;
  final int morale;
  final int stamina;
  final int currentStamina;
  final int salary;
  final int contractWeeks;
  final int momentum;

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
    required this.momentum,
  });

  factory Wrestler.fromJson(Map<String, dynamic> json) {
    return Wrestler(
      name: json['name'] ?? '',
      promotion: json['promotion'] ?? '',
      role: json['role'] ?? '',
      wrestlerClass: json['class'] ?? '',
      inRing: json['inRing'] ?? 0,
      charisma: json['charisma'] ?? 0,
      promoSkill: json['promoSkill'] ?? 0,
      popularity: json['popularity'] ?? 0,
      morale: json['morale'] ?? 0,
      stamina: json['stamina'] ?? 0,
      currentStamina: json['currentStamina'] ?? 0,
      salary: json['salary'] ?? 0,
      contractWeeks: json['contractWeeks'] ?? 0,
      momentum: json['momentum'] ?? 0,
    );
  }
}