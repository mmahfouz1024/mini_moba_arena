import 'package:flutter/material.dart';

enum Team { blue, red }

enum HeroRole { fighter, mage, tank, marksman }

enum ArenaMode { arena3v3, duel1v1 }

class SkillDef {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final double cooldown;
  final double manaCost;
  final double range;
  final double radius;
  final double baseDamage;
  final double scaling;
  final bool isDash;
  final bool isSelfBuffOrHeal;
  final double stunDuration;
  final double slowDuration;
  final bool isMultiShot;
  final Color color;
  final IconData icon;

  const SkillDef({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    required this.cooldown,
    required this.manaCost,
    required this.range,
    required this.radius,
    required this.baseDamage,
    required this.scaling,
    this.isDash = false,
    this.isSelfBuffOrHeal = false,
    this.stunDuration = 0,
    this.slowDuration = 0,
    this.isMultiShot = false,
    required this.color,
    this.icon = Icons.auto_awesome,
  });
}

class HeroDef {
  final String id;
  final String nameEn;
  final String nameAr;
  final String titleEn;
  final String titleAr;
  final String portraitAsset;
  final HeroRole role;
  final Color primaryColor;
  final Color secondaryColor;
  final double maxHp;
  final double maxMana;
  final double attackDamage;
  final double attackRange;
  final double moveSpeed;
  final double attackCooldown;
  final int unlockCostGold;
  final List<SkillDef> skills;

  const HeroDef({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.titleEn,
    required this.titleAr,
    required this.portraitAsset,
    required this.role,
    required this.primaryColor,
    required this.secondaryColor,
    required this.maxHp,
    required this.maxMana,
    required this.attackDamage,
    required this.attackRange,
    required this.moveSpeed,
    required this.attackCooldown,
    required this.unlockCostGold,
    required this.skills,
  });
}

class HeroCatalog {
  static const List<HeroDef> heroes = [
    HeroDef(
      id: 'kael',
      nameEn: 'Kael',
      nameAr: 'كايل',
      titleEn: 'Blade Vanguard',
      titleAr: 'طليعة النصل',
      portraitAsset: 'assets/images/heroes/kael.png',
      role: HeroRole.fighter,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF93C5FD),
      maxHp: 980,
      maxMana: 420,
      attackDamage: 68,
      attackRange: 95,
      moveSpeed: 225,
      attackCooldown: 0.68,
      unlockCostGold: 0,
      skills: [
        SkillDef(
          id: 'kael_s1',
          nameEn: 'Phantom Dash',
          nameAr: 'اندفاع الشبح',
          descEn: 'Dash forward slashing enemies in path',
          descAr: 'اندفع للأمام واضرب الأعداء في طريقك',
          cooldown: 4.5,
          manaCost: 45,
          range: 240,
          radius: 75,
          baseDamage: 120,
          scaling: 1.15,
          isDash: true,
          color: Color(0xFF38BDF8),
          icon: Icons.bolt,
        ),
        SkillDef(
          id: 'kael_s2',
          nameEn: 'Whirlwind Edge',
          nameAr: 'إعصار السيف',
          descEn: 'Spin slash damaging nearby enemies & slowing them',
          descAr: 'ضربة دائرية تضر وتبطئ الأعداء القريبين',
          cooldown: 5.5,
          manaCost: 55,
          range: 0,
          radius: 155,
          baseDamage: 145,
          scaling: 1.25,
          slowDuration: 1.5,
          color: Color(0xFF60A5FA),
          icon: Icons.cyclone,
        ),
        SkillDef(
          id: 'kael_ult',
          nameEn: 'Execution Leap',
          nameAr: 'وثبة الحسم',
          descEn: 'Leap to target zone dealing massive stun & burst',
          descAr: 'اقفز نحو الهدف بضربة مدمرة وصاعقة',
          cooldown: 14.0,
          manaCost: 100,
          range: 310,
          radius: 140,
          baseDamage: 290,
          scaling: 1.7,
          isDash: true,
          stunDuration: 1.1,
          color: Color(0xFFFACC15),
          icon: Icons.gavel,
        ),
      ],
    ),
    HeroDef(
      id: 'lyra',
      nameEn: 'Lyra',
      nameAr: 'ليرا',
      titleEn: 'Arcane Ember',
      titleAr: 'لهيب السحر',
      portraitAsset: 'assets/images/heroes/lyra.png',
      role: HeroRole.mage,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFFE9D5FF),
      maxHp: 760,
      maxMana: 620,
      attackDamage: 54,
      attackRange: 255,
      moveSpeed: 210,
      attackCooldown: 0.78,
      unlockCostGold: 0,
      skills: [
        SkillDef(
          id: 'lyra_s1',
          nameEn: 'Starfire Bolt',
          nameAr: 'شعلة النجوم',
          descEn: 'Launch explosive arcane orb in target direction',
          descAr: 'أطلق كرة سحرية متفجرة في الاتجاه المحدد',
          cooldown: 3.6,
          manaCost: 50,
          range: 380,
          radius: 78,
          baseDamage: 150,
          scaling: 1.35,
          color: Color(0xFFC084FC),
          icon: Icons.local_fire_department,
        ),
        SkillDef(
          id: 'lyra_s2',
          nameEn: 'Frost Ring',
          nameAr: 'حلقة الصقيع',
          descEn: 'Freeze enemies around you with stun & burst',
          descAr: 'جمد الأعداء حولك مع ضرر وشلل مؤقت',
          cooldown: 7.0,
          manaCost: 70,
          range: 0,
          radius: 165,
          baseDamage: 130,
          scaling: 1.1,
          stunDuration: 1.0,
          color: Color(0xFF38BDF8),
          icon: Icons.ac_unit,
        ),
        SkillDef(
          id: 'lyra_ult',
          nameEn: 'Meteor Cataclysm',
          nameAr: 'سقوط النيزك',
          descEn: 'Call down a huge meteor strike at target spot',
          descAr: 'أسقط نيزكاً ضخماً في المنطقة المحددة',
          cooldown: 15.0,
          manaCost: 120,
          range: 360,
          radius: 175,
          baseDamage: 340,
          scaling: 1.8,
          slowDuration: 2.0,
          color: Color(0xFFF43F5E),
          icon: Icons.flare,
        ),
      ],
    ),
    HeroDef(
      id: 'vex',
      nameEn: 'Vex',
      nameAr: 'فيكس',
      titleEn: 'Iron Bulwark',
      titleAr: 'الحصن الحديدي',
      portraitAsset: 'assets/images/heroes/vex.png',
      role: HeroRole.tank,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFFA7F3D0),
      maxHp: 1380,
      maxMana: 400,
      attackDamage: 56,
      attackRange: 90,
      moveSpeed: 205,
      attackCooldown: 0.82,
      unlockCostGold: 200,
      skills: [
        SkillDef(
          id: 'vex_s1',
          nameEn: 'Shield Bash',
          nameAr: 'اندفاع الدرع',
          descEn: 'Charge forward stunning the targets hit',
          descAr: 'اندفع للأمام وصعق الأعداء عند الاصطدام',
          cooldown: 5.2,
          manaCost: 45,
          range: 230,
          radius: 85,
          baseDamage: 110,
          scaling: 0.9,
          isDash: true,
          stunDuration: 1.0,
          color: Color(0xFF34D399),
          icon: Icons.security,
        ),
        SkillDef(
          id: 'vex_s2',
          nameEn: 'Titan Aegis',
          nameAr: 'درع الجبار',
          descEn: 'Gain a heavy shield and restore health',
          descAr: 'احصل على درع قوي واستعد جزءاً من الصحة',
          cooldown: 8.5,
          manaCost: 60,
          range: 0,
          radius: 120,
          baseDamage: 0,
          scaling: 1.0,
          isSelfBuffOrHeal: true,
          color: Color(0xFF6EE7B7),
          icon: Icons.shield,
        ),
        SkillDef(
          id: 'vex_ult',
          nameEn: 'Seismic Slam',
          nameAr: 'ضربة الزلزال',
          descEn: 'Smash the arena shocking and slowing all enemies nearby',
          descAr: 'اضرب الأرض بقوة لصعق وإبطاء كل الأعداء حولك',
          cooldown: 14.5,
          manaCost: 95,
          range: 0,
          radius: 210,
          baseDamage: 240,
          scaling: 1.25,
          stunDuration: 1.4,
          color: Color(0xFFF59E0B),
          icon: Icons.public,
        ),
      ],
    ),
    HeroDef(
      id: 'sera',
      nameEn: 'Sera',
      nameAr: 'سيرا',
      titleEn: 'Wind Marksman',
      titleAr: 'رامية الرياح',
      portraitAsset: 'assets/images/heroes/sera.png',
      role: HeroRole.marksman,
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFFDE68A),
      maxHp: 740,
      maxMana: 460,
      attackDamage: 74,
      attackRange: 295,
      moveSpeed: 230,
      attackCooldown: 0.56,
      unlockCostGold: 300,
      skills: [
        SkillDef(
          id: 'sera_s1',
          nameEn: 'Piercing Arrow',
          nameAr: 'السهم الخارق',
          descEn: 'Fire a long-range sniper shot dealing high damage',
          descAr: 'أطلق سهماً بعيد المدى بضرر عالٍ جداً',
          cooldown: 4.0,
          manaCost: 45,
          range: 430,
          radius: 62,
          baseDamage: 165,
          scaling: 1.4,
          color: Color(0xFFFBBF24),
          icon: Icons.arrow_forward,
        ),
        SkillDef(
          id: 'sera_s2',
          nameEn: 'Gale Step',
          nameAr: 'خطوة الريح',
          descEn: 'Quick tactical dash with temporary speed burst',
          descAr: 'قفزة تكتيكية سريعة مع زيادة سرعة الحركة',
          cooldown: 6.2,
          manaCost: 40,
          range: 210,
          radius: 60,
          baseDamage: 50,
          scaling: 0.5,
          isDash: true,
          isSelfBuffOrHeal: true,
          color: Color(0xFF38BDF8),
          icon: Icons.air,
        ),
        SkillDef(
          id: 'sera_ult',
          nameEn: 'Starlight Volley',
          nameAr: 'وابل النجوم',
          descEn: 'Unleash a fan of 5 high-damage energy arrows',
          descAr: 'أطلق 5 أسهم طاقة متتابعة في مروحة واسعة',
          cooldown: 13.0,
          manaCost: 95,
          range: 390,
          radius: 95,
          baseDamage: 270,
          scaling: 1.65,
          isMultiShot: true,
          slowDuration: 1.4,
          color: Color(0xFFF97316),
          icon: Icons.auto_awesome,
        ),
      ],
    ),
  ];

  static HeroDef byId(String id) =>
      heroes.firstWhere((h) => h.id == id, orElse: () => heroes.first);
}

class ShopItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final String statLabelEn;
  final String statLabelAr;
  final int cost;
  final double bonusAttack;
  final double bonusHp;
  final double bonusSpeed;
  final double cdrBonus;
  final double lifesteal;
  final Color color;

  const ShopItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.statLabelEn,
    required this.statLabelAr,
    required this.cost,
    this.bonusAttack = 0,
    this.bonusHp = 0,
    this.bonusSpeed = 0,
    this.cdrBonus = 0,
    this.lifesteal = 0,
    required this.color,
  });
}

class ShopCatalog {
  static const List<ShopItem> items = [
    ShopItem(
      id: 'boots',
      nameEn: 'Swift Boots',
      nameAr: 'أحذية السرعة',
      statLabelEn: '+32 Speed',
      statLabelAr: '+32 سرعة حركة',
      cost: 160,
      bonusSpeed: 32,
      color: Color(0xFF38BDF8),
    ),
    ShopItem(
      id: 'crimson_blade',
      nameEn: 'Crimson Blade',
      nameAr: 'النصل القرمزي',
      statLabelEn: '+26 ATK, +12% Lifesteal',
      statLabelAr: '+26 هجوم، +12% امتصاص حياة',
      cost: 280,
      bonusAttack: 26,
      lifesteal: 0.12,
      color: Color(0xFFF43F5E),
    ),
    ShopItem(
      id: 'arcane_orb',
      nameEn: 'Chrono Orb',
      nameAr: 'جوهرة الزمن',
      statLabelEn: '+22 ATK, 18% CDR',
      statLabelAr: '+22 هجوم، 18% تقليل انتظار',
      cost: 290,
      bonusAttack: 22,
      cdrBonus: 0.18,
      color: Color(0xFFA855F7),
    ),
    ShopItem(
      id: 'aegis_armor',
      nameEn: 'Aegis Plate',
      nameAr: 'درع الحماية',
      statLabelEn: '+320 Max HP',
      statLabelAr: '+320 صحة قصوى',
      cost: 260,
      bonusHp: 320,
      color: Color(0xFF10B981),
    ),
    ShopItem(
      id: 'mythic_crown',
      nameEn: 'Mythic Crown',
      nameAr: 'التاج الأسطوري',
      statLabelEn: '+42 ATK, +240 HP',
      statLabelAr: '+42 هجوم، +240 صحة',
      cost: 440,
      bonusAttack: 42,
      bonusHp: 240,
      color: Color(0xFFFACC15),
    ),
  ];
}

class PlayerMetaProfile {
  int accountGold;
  int rankPoints;
  int wins;
  int losses;
  int totalKills;
  List<String> unlockedHeroIds;
  String selectedHeroId;
  bool soundEnabled;
  bool hapticsEnabled;
  bool isArabic;

  PlayerMetaProfile({
    this.accountGold = 120,
    this.rankPoints = 100,
    this.wins = 0,
    this.losses = 0,
    this.totalKills = 0,
    List<String>? unlockedHeroIds,
    this.selectedHeroId = 'kael',
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.isArabic = true,
  }) : unlockedHeroIds = unlockedHeroIds ?? ['kael', 'lyra'];

  String rankName(bool isAr) {
    if (rankPoints >= 1000) return isAr ? 'أسطوري (Mythic)' : 'Mythic';
    if (rankPoints >= 700) return isAr ? 'أسطورة (Legend)' : 'Legend';
    if (rankPoints >= 450) return isAr ? 'أستاذ عظيم (Grandmaster)' : 'Grandmaster';
    if (rankPoints >= 250) return isAr ? 'محترف (Master)' : 'Master';
    if (rankPoints >= 140) return isAr ? 'نخبة (Elite)' : 'Elite';
    return isAr ? 'محارب (Warrior)' : 'Warrior';
  }

  Map<String, dynamic> toJson() => {
        'accountGold': accountGold,
        'rankPoints': rankPoints,
        'wins': wins,
        'losses': losses,
        'totalKills': totalKills,
        'unlockedHeroIds': unlockedHeroIds,
        'selectedHeroId': selectedHeroId,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'isArabic': isArabic,
      };

  factory PlayerMetaProfile.fromJson(Map<String, dynamic> json) => PlayerMetaProfile(
        accountGold: json['accountGold'] as int? ?? 120,
        rankPoints: json['rankPoints'] as int? ?? 100,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        totalKills: json['totalKills'] as int? ?? 0,
        unlockedHeroIds: (json['unlockedHeroIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['kael', 'lyra'],
        selectedHeroId: json['selectedHeroId'] as String? ?? 'kael',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        isArabic: json['isArabic'] as bool? ?? true,
      );
}
