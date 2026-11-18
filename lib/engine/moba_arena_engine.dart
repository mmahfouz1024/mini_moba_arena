import 'dart:math';
import 'package:flutter/material.dart';
import '../models/moba_models.dart';

class Vec2 {
  double x;
  double y;
  Vec2(this.x, this.y);

  Vec2 copy() => Vec2(x, y);
  double distanceTo(Vec2 other) => sqrt((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y));

  Vec2 normalized() {
    final len = sqrt(x * x + y * y);
    if (len < 1e-6) return Vec2(1, 0);
    return Vec2(x / len, y / len);
  }
}

class ObstacleCircle {
  final Vec2 pos;
  final double radius;
  const ObstacleCircle(this.pos, this.radius);
}

class HeroEntity {
  final String uid;
  final HeroDef def;
  final Team team;
  final bool isPlayer;

  Vec2 pos;
  double facingAngle;
  double hp;
  double maxHp;
  double mana;
  double maxMana;
  double attackDamage;
  double moveSpeed;
  double cdrBonus;
  double lifesteal;

  int level = 1;
  double xp = 0;
  int gold = 180;
  int kills = 0;
  int deaths = 0;
  int assists = 0;
  int turretDamage = 0;

  List<double> skillCooldowns = [0, 0, 0];
  double basicCooldown = 0;
  double healSpellCooldown = 0;

  double respawnTimer = 0;
  double stunTimer = 0;
  double slowTimer = 0;
  double speedBuffTimer = 0;
  double bossBuffTimer = 0;
  double shieldAmount = 0;
  double recallTimer = 0;
  double turretAggroTimer = 0;
  String? lastHitByHeroUid;
  double lastHitTimer = 0;

  final List<String> boughtItemIds = [];

  HeroEntity({
    required this.uid,
    required this.def,
    required this.team,
    required this.isPlayer,
    required this.pos,
    required this.facingAngle,
  })  : hp = def.maxHp,
        maxHp = def.maxHp,
        mana = def.maxMana,
        maxMana = def.maxMana,
        attackDamage = def.attackDamage,
        moveSpeed = def.moveSpeed,
        cdrBonus = 0,
        lifesteal = 0;

  bool get isAlive => respawnTimer <= 0 && hp > 0;
  double get xpForNextLevel => 120.0 + (level - 1) * 90.0;
}

class MinionEntity {
  final String uid;
  final Team team;
  final bool isRanged;
  Vec2 pos;
  double hp;
  final double maxHp;
  final double damage;
  final double range;
  final double speed;
  double attackCooldown = 0;
  int waypointIndex = 0;

  MinionEntity({
    required this.uid,
    required this.team,
    required this.isRanged,
    required this.pos,
    required this.maxHp,
    required this.damage,
    required this.range,
    required this.speed,
  }) : hp = maxHp;

  bool get isAlive => hp > 0;
}

class TurretEntity {
  final String uid;
  final Team team;
  final bool isNexus;
  final Vec2 pos;
  double hp;
  final double maxHp;
  final double range;
  final double damage;
  double attackCooldown = 0;
  String? currentTargetUid;
  Vec2? currentTargetPos;

  TurretEntity({
    required this.uid,
    required this.team,
    required this.isNexus,
    required this.pos,
    required this.maxHp,
    required this.range,
    required this.damage,
  }) : hp = maxHp;

  bool get isAlive => hp > 0;
}

class JungleBoss {
  final String uid;
  final String nameEn;
  final String nameAr;
  final Vec2 homePos;
  Vec2 pos;
  double hp;
  final double maxHp;
  double respawnTimer = 0;
  double attackCooldown = 0;
  final Color color;

  JungleBoss({
    required this.uid,
    required this.nameEn,
    required this.nameAr,
    required this.homePos,
    required this.maxHp,
    required this.color,
  })  : pos = homePos.copy(),
        hp = maxHp;

  bool get isAlive => respawnTimer <= 0 && hp > 0;
}

class ProjectileEntity {
  final String ownerUid;
  final Team team;
  Vec2 pos;
  final Vec2 dir;
  final double speed;
  double remainingRange;
  final double radius;
  final double damage;
  final double stunDuration;
  final double slowDuration;
  final bool aoeOnHit;
  final double aoeRadius;
  final Color color;
  bool expired = false;

  ProjectileEntity({
    required this.ownerUid,
    required this.team,
    required this.pos,
    required this.dir,
    required this.speed,
    required this.remainingRange,
    required this.radius,
    required this.damage,
    this.stunDuration = 0,
    this.slowDuration = 0,
    this.aoeOnHit = false,
    this.aoeRadius = 0,
    required this.color,
  });
}

class VfxPulse {
  final Vec2 pos;
  final double maxRadius;
  final Color color;
  double age = 0;
  final double duration;

  VfxPulse({
    required this.pos,
    required this.maxRadius,
    required this.color,
    this.duration = 0.35,
  });

  double get progress => (age / duration).clamp(0.0, 1.0);
  bool get isFinished => age >= duration;
}

class FloatingText {
  Vec2 pos;
  final String text;
  final Color color;
  double age = 0;
  final double duration;

  FloatingText({
    required this.pos,
    required this.text,
    required this.color,
    this.duration = 0.85,
  });

  bool get isFinished => age >= duration;
}

class ArenaSoundEvent {
  final String asset;
  const ArenaSoundEvent(this.asset);
}

class MobaArenaEngine {
  static const double worldWidth = 2400;
  static const double worldHeight = 1400;

  final ArenaMode mode;
  final HeroDef playerHeroDef;
  final Random _rng;

  late List<HeroEntity> heroes;
  late HeroEntity player;
  final List<MinionEntity> minions = [];
  late List<TurretEntity> turrets;
  late List<JungleBoss> bosses;
  final List<ProjectileEntity> projectiles = [];
  final List<VfxPulse> vfxPulses = [];
  final List<FloatingText> floatingTexts = [];
  final List<ArenaSoundEvent> pendingSounds = [];

  final List<ObstacleCircle> obstacles = [
    ObstacleCircle(Vec2(820, 520), 62),
    ObstacleCircle(Vec2(1580, 880), 62),
    ObstacleCircle(Vec2(1030, 960), 54),
    ObstacleCircle(Vec2(1370, 440), 54),
  ];

  final List<Vec2> _blueWaypoints = [
    Vec2(480, 1040),
    Vec2(810, 880),
    Vec2(1200, 700),
    Vec2(1590, 520),
    Vec2(1920, 360),
    Vec2(2190, 210),
  ];

  late final List<Vec2> _redWaypoints = _blueWaypoints.reversed.toList();

  double matchTime = 0;
  double _waveTimer = 2.0;
  int _uidCounter = 0;
  Team? winner;
  String? announcementEn;
  String? announcementAr;
  double announcementTimer = 0;

  Vec2 playerMoveInput = Vec2(0, 0);

  MobaArenaEngine({
    required this.mode,
    required this.playerHeroDef,
    Random? rng,
  }) : _rng = rng ?? Random() {
    _setupMatch();
  }

  String _nextUid(String prefix) => '${prefix}_${_uidCounter++}';

  Vec2 _basePos(Team team) => team == Team.blue ? Vec2(190, 1210) : Vec2(2210, 190);

  void _setupMatch() {
    turrets = [
      TurretEntity(
        uid: 'blue_nexus',
        team: Team.blue,
        isNexus: true,
        pos: _basePos(Team.blue),
        maxHp: 2800,
        range: 275,
        damage: 135,
      ),
      TurretEntity(
        uid: 'blue_inner',
        team: Team.blue,
        isNexus: false,
        pos: Vec2(500, 1030),
        maxHp: 1700,
        range: 245,
        damage: 105,
      ),
      TurretEntity(
        uid: 'blue_outer',
        team: Team.blue,
        isNexus: false,
        pos: Vec2(820, 875),
        maxHp: 1350,
        range: 235,
        damage: 92,
      ),
      TurretEntity(
        uid: 'red_nexus',
        team: Team.red,
        isNexus: true,
        pos: _basePos(Team.red),
        maxHp: 2800,
        range: 275,
        damage: 135,
      ),
      TurretEntity(
        uid: 'red_inner',
        team: Team.red,
        isNexus: false,
        pos: Vec2(1900, 370),
        maxHp: 1700,
        range: 245,
        damage: 105,
      ),
      TurretEntity(
        uid: 'red_outer',
        team: Team.red,
        isNexus: false,
        pos: Vec2(1580, 525),
        maxHp: 1350,
        range: 235,
        damage: 92,
      ),
    ];

    bosses = [
      JungleBoss(
        uid: 'river_lord',
        nameEn: 'River Lord',
        nameAr: 'سيد النهر',
        homePos: Vec2(960, 320),
        maxHp: 1500,
        color: const Color(0xFFF59E0B),
      ),
      JungleBoss(
        uid: 'arcane_turtle',
        nameEn: 'Arcane Turtle',
        nameAr: 'سلحفاة الطاقة',
        homePos: Vec2(1440, 1080),
        maxHp: 1100,
        color: const Color(0xFF06B6D4),
      ),
    ];

    heroes = [];
    player = HeroEntity(
      uid: 'player',
      def: playerHeroDef,
      team: Team.blue,
      isPlayer: true,
      pos: Vec2(280, 1140),
      facingAngle: -0.45,
    );
    heroes.add(player);

    final others = HeroCatalog.heroes.where((h) => h.id != playerHeroDef.id).toList();
    if (mode == ArenaMode.arena3v3) {
      heroes.add(
        HeroEntity(
          uid: 'blue_bot_1',
          def: others[0],
          team: Team.blue,
          isPlayer: false,
          pos: Vec2(250, 1080),
          facingAngle: -0.45,
        ),
      );
      heroes.add(
        HeroEntity(
          uid: 'blue_bot_2',
          def: others[1],
          team: Team.blue,
          isPlayer: false,
          pos: Vec2(340, 1180),
          facingAngle: -0.45,
        ),
      );

      final redPool = [HeroCatalog.heroes[0], HeroCatalog.heroes[1], HeroCatalog.heroes[2]];
      heroes.add(
        HeroEntity(
          uid: 'red_bot_1',
          def: redPool[0],
          team: Team.red,
          isPlayer: false,
          pos: Vec2(2110, 260),
          facingAngle: 2.65,
        ),
      );
      heroes.add(
        HeroEntity(
          uid: 'red_bot_2',
          def: redPool[1],
          team: Team.red,
          isPlayer: false,
          pos: Vec2(2140, 320),
          facingAngle: 2.65,
        ),
      );
      heroes.add(
        HeroEntity(
          uid: 'red_bot_3',
          def: redPool[2],
          team: Team.red,
          isPlayer: false,
          pos: Vec2(2040, 220),
          facingAngle: 2.65,
        ),
      );
    } else {
      // 1v1 Duel
      final opponent = others.first;
      heroes.add(
        HeroEntity(
          uid: 'red_bot_1',
          def: opponent,
          team: Team.red,
          isPlayer: false,
          pos: Vec2(2110, 260),
          facingAngle: 2.65,
        ),
      );
    }
  }

  void update(double dt) {
    if (winner != null) return;
    final clampedDt = dt.clamp(0.0, 0.05);
    matchTime += clampedDt;

    if (announcementTimer > 0) {
      announcementTimer = max(0, announcementTimer - clampedDt);
      if (announcementTimer == 0) {
        announcementEn = null;
        announcementAr = null;
      }
    }

    _waveTimer -= clampedDt;
    if (_waveTimer <= 0) {
      _spawnMinionWave();
      _waveTimer = 14.0;
    }

    for (final hero in heroes) {
      _updateHero(hero, clampedDt);
    }

    _updateMinions(clampedDt);
    _updateTurrets(clampedDt);
    _updateBosses(clampedDt);
    _updateProjectiles(clampedDt);
    _updateVfx(clampedDt);

    // Check Nexus destruction
    final blueNexus = turrets.firstWhere((t) => t.uid == 'blue_nexus');
    final redNexus = turrets.firstWhere((t) => t.uid == 'red_nexus');
    if (!redNexus.isAlive) {
      winner = Team.blue;
      pendingSounds.add(const ArenaSoundEvent('victory.wav'));
    } else if (!blueNexus.isAlive) {
      winner = Team.red;
    }
  }

  void _spawnMinionWave() {
    for (final team in [Team.blue, Team.red]) {
      final start = team == Team.blue ? Vec2(290, 1135) : Vec2(2110, 265);
      for (var i = 0; i < 3; i++) {
        final offset = Vec2((i - 1) * 26.0, (1 - i) * 18.0);
        final isRanged = i == 2;
        minions.add(
          MinionEntity(
            uid: _nextUid('minion'),
            team: team,
            isRanged: isRanged,
            pos: Vec2(start.x + offset.x, start.y + offset.y),
            maxHp: isRanged ? 210 : 320,
            damage: isRanged ? 28 : 22,
            range: isRanged ? 185 : 58,
            speed: 120,
          ),
        );
      }
    }
  }

  void _updateHero(HeroEntity hero, double dt) {
    if (!hero.isAlive) {
      hero.respawnTimer -= dt;
      if (hero.respawnTimer <= 0) {
        hero.respawnTimer = 0;
        hero.hp = hero.maxHp;
        hero.mana = hero.maxMana;
        hero.pos = _basePos(hero.team);
        hero.stunTimer = 0;
        hero.slowTimer = 0;
      }
      return;
    }

    // Passive regen + Gold trickle
    hero.mana = min(hero.maxMana, hero.mana + 12.0 * dt);
    hero.hp = min(hero.maxHp, hero.hp + 4.5 * dt);
    if (matchTime.floor() != (matchTime - dt).floor()) {
      hero.gold += 3;
    }

    // Fountain healing near own base
    if (hero.pos.distanceTo(_basePos(hero.team)) < 175) {
      hero.hp = min(hero.maxHp, hero.hp + 130 * dt);
      hero.mana = min(hero.maxMana, hero.mana + 100 * dt);
    }

    // Timers
    for (var i = 0; i < 3; i++) {
      if (hero.skillCooldowns[i] > 0) {
        hero.skillCooldowns[i] = max(0, hero.skillCooldowns[i] - dt);
      }
    }
    if (hero.basicCooldown > 0) hero.basicCooldown = max(0, hero.basicCooldown - dt);
    if (hero.healSpellCooldown > 0) hero.healSpellCooldown = max(0, hero.healSpellCooldown - dt);
    if (hero.stunTimer > 0) hero.stunTimer = max(0, hero.stunTimer - dt);
    if (hero.slowTimer > 0) hero.slowTimer = max(0, hero.slowTimer - dt);
    if (hero.speedBuffTimer > 0) hero.speedBuffTimer = max(0, hero.speedBuffTimer - dt);
    if (hero.bossBuffTimer > 0) hero.bossBuffTimer = max(0, hero.bossBuffTimer - dt);
    if (hero.turretAggroTimer > 0) hero.turretAggroTimer = max(0, hero.turretAggroTimer - dt);
    if (hero.lastHitTimer > 0) {
      hero.lastHitTimer = max(0, hero.lastHitTimer - dt);
      if (hero.lastHitTimer == 0) hero.lastHitByHeroUid = null;
    }

    // Recall channel
    if (hero.recallTimer > 0) {
      hero.recallTimer -= dt;
      if (hero.recallTimer <= 0) {
        hero.recallTimer = 0;
        hero.pos = _basePos(hero.team);
        vfxPulses.add(VfxPulse(pos: hero.pos.copy(), maxRadius: 75, color: Colors.cyanAccent));
      }
    }

    if (hero.stunTimer > 0) return;

    if (hero.isPlayer) {
      final len = sqrt(playerMoveInput.x * playerMoveInput.x + playerMoveInput.y * playerMoveInput.y);
      if (len > 0.08) {
        hero.recallTimer = 0;
        final dir = Vec2(playerMoveInput.x / len, playerMoveInput.y / len);
        final speed = _effectiveSpeed(hero) * min(1.0, len);
        hero.facingAngle = atan2(dir.y, dir.x);
        _moveWithCollisions(hero.pos, dir.x * speed * dt, dir.y * speed * dt, 24);
      }
    } else {
      _updateBotHero(hero, dt);
    }
  }

  double _effectiveSpeed(HeroEntity hero) {
    var s = hero.moveSpeed;
    if (hero.slowTimer > 0) s *= 0.6;
    if (hero.speedBuffTimer > 0) s *= 1.35;
    if (hero.bossBuffTimer > 0) s *= 1.12;
    return s;
  }

  void _updateBotHero(HeroEntity bot, double dt) {
    // Auto-buy affordable items
    for (final item in ShopCatalog.items) {
      if (!bot.boughtItemIds.contains(item.id) && bot.gold >= item.cost && bot.boughtItemIds.length < 4) {
        buyShopItem(bot, item.id);
        break;
      }
    }

    final home = _basePos(bot.team);
    final enemyBase = _basePos(bot.team == Team.blue ? Team.red : Team.blue);

    // Check turret danger: if inside an enemy turret range with no allied minion inside that turret range, back off!
    for (final t in turrets) {
      if (t.isAlive && t.team != bot.team && bot.pos.distanceTo(t.pos) < t.range + 20) {
        final hasMinionShield = minions.any(
          (m) => m.isAlive && m.team == bot.team && m.pos.distanceTo(t.pos) < t.range,
        );
        if (!hasMinionShield) {
          final away = Vec2(home.x - bot.pos.x, home.y - bot.pos.y).normalized();
          bot.facingAngle = atan2(away.y, away.x);
          _moveWithCollisions(bot.pos, away.x * _effectiveSpeed(bot) * dt, away.y * _effectiveSpeed(bot) * dt, 24);
          return;
        }
      }
    }

    // Low HP retreat
    if (bot.hp < bot.maxHp * 0.27) {
      if (bot.healSpellCooldown <= 0) {
        triggerHealSpell(bot);
      }
      final away = Vec2(home.x - bot.pos.x, home.y - bot.pos.y).normalized();
      bot.facingAngle = atan2(away.y, away.x);
      _moveWithCollisions(bot.pos, away.x * _effectiveSpeed(bot) * dt, away.y * _effectiveSpeed(bot) * dt, 24);
      return;
    }

    // Find closest enemy hero, minion, or turret
    HeroEntity? nearestEnemyHero;
    var bestHeroDist = 520.0;
    for (final h in heroes) {
      if (h.isAlive && h.team != bot.team) {
        final d = bot.pos.distanceTo(h.pos);
        if (d < bestHeroDist) {
          bestHeroDist = d;
          nearestEnemyHero = h;
        }
      }
    }

    if (nearestEnemyHero != null) {
      final aim = Vec2(nearestEnemyHero.pos.x - bot.pos.x, nearestEnemyHero.pos.y - bot.pos.y).normalized();
      bot.facingAngle = atan2(aim.y, aim.x);

      // Cast skills if ready and in range
      for (var sIdx = 2; sIdx >= 0; sIdx--) {
        final skill = bot.def.skills[sIdx];
        final maxUseRange = skill.range > 0 ? skill.range : skill.radius;
        if (bot.skillCooldowns[sIdx] <= 0 && bot.mana >= skill.manaCost && bestHeroDist <= maxUseRange + 20) {
          castSkill(bot, sIdx, aimDir: aim);
          break;
        }
      }

      if (bestHeroDist <= bot.def.attackRange) {
        performBasicAttack(bot);
      } else {
        _moveWithCollisions(bot.pos, aim.x * _effectiveSpeed(bot) * dt, aim.y * _effectiveSpeed(bot) * dt, 24);
      }
      return;
    }

    // Otherwise find closest enemy minion or turret
    Vec2? targetPos;
    var bestDist = double.infinity;
    for (final m in minions) {
      if (m.isAlive && m.team != bot.team) {
        final d = bot.pos.distanceTo(m.pos);
        if (d < bestDist && d < 460) {
          bestDist = d;
          targetPos = m.pos;
        }
      }
    }
    if (targetPos == null) {
      for (final t in turrets) {
        if (t.isAlive && t.team != bot.team) {
          final d = bot.pos.distanceTo(t.pos);
          if (d < bestDist && d < 420) {
            final hasMinions = minions.any((m) => m.isAlive && m.team == bot.team && m.pos.distanceTo(t.pos) < t.range);
            if (hasMinions) {
              bestDist = d;
              targetPos = t.pos;
            }
          }
        }
      }
    }

    if (targetPos != null) {
      final dir = Vec2(targetPos.x - bot.pos.x, targetPos.y - bot.pos.y).normalized();
      bot.facingAngle = atan2(dir.y, dir.x);
      if (bestDist <= bot.def.attackRange) {
        performBasicAttack(bot);
      } else {
        _moveWithCollisions(bot.pos, dir.x * _effectiveSpeed(bot) * dt, dir.y * _effectiveSpeed(bot) * dt, 24);
      }
    } else {
      // Advance along lane toward center / enemy base
      final laneTarget = enemyBase;
      final dir = Vec2(laneTarget.x - bot.pos.x, laneTarget.y - bot.pos.y).normalized();
      bot.facingAngle = atan2(dir.y, dir.x);
      _moveWithCollisions(bot.pos, dir.x * _effectiveSpeed(bot) * dt, dir.y * _effectiveSpeed(bot) * dt, 24);
    }
  }

  void _moveWithCollisions(Vec2 pos, double dx, double dy, double radius) {
    pos.x = (pos.x + dx).clamp(radius + 20, worldWidth - radius - 20);
    pos.y = (pos.y + dy).clamp(radius + 20, worldHeight - radius - 20);

    for (final obs in obstacles) {
      final dist = pos.distanceTo(obs.pos);
      final minDist = radius + obs.radius;
      if (dist < minDist && dist > 1e-4) {
        final push = Vec2((pos.x - obs.pos.x) / dist, (pos.y - obs.pos.y) / dist);
        pos.x = obs.pos.x + push.x * minDist;
        pos.y = obs.pos.y + push.y * minDist;
      }
    }
  }

  void performBasicAttack(HeroEntity hero) {
    if (!hero.isAlive || hero.basicCooldown > 0 || hero.stunTimer > 0) return;
    hero.recallTimer = 0;
    hero.basicCooldown = hero.def.attackCooldown;

    final isCrit = _rng.nextDouble() < 0.12;
    final dmg = hero.attackDamage *
        (hero.bossBuffTimer > 0 ? 1.25 : 1.0) *
        (isCrit ? 1.45 : 1.0);
    final range = hero.def.attackRange + 12;

    // Target priority: enemy hero -> enemy minion -> boss -> enemy turret
    HeroEntity? heroTarget;
    var bestHeroDist = range;
    for (final h in heroes) {
      if (h.isAlive && h.team != hero.team) {
        final d = hero.pos.distanceTo(h.pos);
        if (d <= bestHeroDist) {
          bestHeroDist = d;
          heroTarget = h;
        }
      }
    }

    if (heroTarget != null) {
      final dir = Vec2(heroTarget.pos.x - hero.pos.x, heroTarget.pos.y - hero.pos.y).normalized();
      hero.facingAngle = atan2(dir.y, dir.x);
      if (hero.def.attackRange > 140) {
        projectiles.add(
          ProjectileEntity(
            ownerUid: hero.uid,
            team: hero.team,
            pos: hero.pos.copy(),
            dir: dir,
            speed: 620,
            remainingRange: hero.def.attackRange + 40,
            radius: 16,
            damage: dmg,
            color: hero.def.secondaryColor,
          ),
        );
      } else {
        _damageHero(heroTarget, dmg, hero);
        vfxPulses.add(VfxPulse(pos: heroTarget.pos.copy(), maxRadius: 42, color: hero.def.secondaryColor, duration: 0.2));
      }
      if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('attack.wav'));
      return;
    }

    MinionEntity? minionTarget;
    var bestMinionDist = range;
    for (final m in minions) {
      if (m.isAlive && m.team != hero.team) {
        final d = hero.pos.distanceTo(m.pos);
        if (d <= bestMinionDist) {
          bestMinionDist = d;
          minionTarget = m;
        }
      }
    }
    if (minionTarget != null) {
      final dir = Vec2(minionTarget.pos.x - hero.pos.x, minionTarget.pos.y - hero.pos.y).normalized();
      hero.facingAngle = atan2(dir.y, dir.x);
      _damageMinion(minionTarget, dmg, hero);
      vfxPulses.add(VfxPulse(pos: minionTarget.pos.copy(), maxRadius: 34, color: hero.def.secondaryColor, duration: 0.18));
      if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('attack.wav'));
      return;
    }

    for (final b in bosses) {
      if (b.isAlive && hero.pos.distanceTo(b.pos) <= range + 25) {
        final dir = Vec2(b.pos.x - hero.pos.x, b.pos.y - hero.pos.y).normalized();
        hero.facingAngle = atan2(dir.y, dir.x);
        _damageBoss(b, dmg, hero);
        vfxPulses.add(VfxPulse(pos: b.pos.copy(), maxRadius: 44, color: b.color, duration: 0.2));
        if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('attack.wav'));
        return;
      }
    }

    for (final t in turrets) {
      if (t.isAlive && t.team != hero.team && hero.pos.distanceTo(t.pos) <= range + 35) {
        final dir = Vec2(t.pos.x - hero.pos.x, t.pos.y - hero.pos.y).normalized();
        hero.facingAngle = atan2(dir.y, dir.x);
        _damageTurret(t, dmg, hero);
        vfxPulses.add(VfxPulse(pos: t.pos.copy(), maxRadius: 48, color: hero.def.secondaryColor, duration: 0.2));
        if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('attack.wav'));
        return;
      }
    }

    // Swing into air if nothing in range
    vfxPulses.add(
      VfxPulse(
        pos: Vec2(hero.pos.x + cos(hero.facingAngle) * 40, hero.pos.y + sin(hero.facingAngle) * 40),
        maxRadius: 35,
        color: hero.def.secondaryColor.withValues(alpha: 0.5),
        duration: 0.16,
      ),
    );
    if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('attack.wav'));
  }

  void castSkill(HeroEntity hero, int skillIndex, {Vec2? aimDir}) {
    if (!hero.isAlive || hero.stunTimer > 0 || skillIndex < 0 || skillIndex > 2) return;
    final skill = hero.def.skills[skillIndex];
    if (hero.skillCooldowns[skillIndex] > 0 || hero.mana < skill.manaCost) return;

    hero.recallTimer = 0;
    hero.mana -= skill.manaCost;
    hero.skillCooldowns[skillIndex] = skill.cooldown * (1.0 - hero.cdrBonus);

    Vec2 dir;
    if (aimDir != null && (aimDir.x.abs() > 0.05 || aimDir.y.abs() > 0.05)) {
      dir = aimDir.normalized();
    } else {
      dir = _smartAimDirection(hero, skill.range > 0 ? skill.range : skill.radius);
    }
    hero.facingAngle = atan2(dir.y, dir.x);

    final power = skill.baseDamage + hero.attackDamage * skill.scaling + (hero.level - 1) * 18;

    if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('skill.wav'));

    if (skill.isSelfBuffOrHeal && !skill.isDash) {
      hero.shieldAmount += 240 + hero.level * 25;
      hero.hp = min(hero.maxHp, hero.hp + 160 + hero.level * 15);
      hero.speedBuffTimer = 2.5;
      vfxPulses.add(VfxPulse(pos: hero.pos.copy(), maxRadius: 90, color: skill.color, duration: 0.45));
      floatingTexts.add(FloatingText(pos: hero.pos.copy(), text: '+SHIELD', color: skill.color));
      return;
    }

    if (skill.isDash) {
      if (skill.isSelfBuffOrHeal) {
        hero.speedBuffTimer = 2.0;
      }
      final stepDist = skill.range;
      final steps = 5;
      for (var i = 0; i < steps; i++) {
        _moveWithCollisions(hero.pos, dir.x * (stepDist / steps), dir.y * (stepDist / steps), 24);
      }
      _applyAoeSkill(
        hero: hero,
        center: hero.pos,
        radius: skill.radius,
        damage: power,
        stun: skill.stunDuration,
        slow: skill.slowDuration,
        color: skill.color,
      );
      return;
    }

    if (skill.range == 0) {
      // Self-centered AoE
      _applyAoeSkill(
        hero: hero,
        center: hero.pos,
        radius: skill.radius,
        damage: power,
        stun: skill.stunDuration,
        slow: skill.slowDuration,
        color: skill.color,
      );
      return;
    }

    if (skill.isMultiShot) {
      final baseAngle = atan2(dir.y, dir.x);
      for (final offset in [-0.32, -0.16, 0.0, 0.16, 0.32]) {
        final shotDir = Vec2(cos(baseAngle + offset), sin(baseAngle + offset));
        projectiles.add(
          ProjectileEntity(
            ownerUid: hero.uid,
            team: hero.team,
            pos: hero.pos.copy(),
            dir: shotDir,
            speed: 680,
            remainingRange: skill.range,
            radius: 22,
            damage: power * 0.42,
            slowDuration: skill.slowDuration,
            color: skill.color,
          ),
        );
      }
      return;
    }

    if (skill.id.endsWith('ult')) {
      // Targeted AoE zone at range (e.g., Meteor Cataclysm)
      final targetCenter = Vec2(
        (hero.pos.x + dir.x * min(skill.range * 0.72, 260)).clamp(40, worldWidth - 40),
        (hero.pos.y + dir.y * min(skill.range * 0.72, 260)).clamp(40, worldHeight - 40),
      );
      _applyAoeSkill(
        hero: hero,
        center: targetCenter,
        radius: skill.radius,
        damage: power,
        stun: skill.stunDuration,
        slow: skill.slowDuration,
        color: skill.color,
      );
      return;
    }

    // Standard skillshot projectile
    projectiles.add(
      ProjectileEntity(
        ownerUid: hero.uid,
        team: hero.team,
        pos: hero.pos.copy(),
        dir: dir,
        speed: 640,
        remainingRange: skill.range,
        radius: 26,
        damage: power,
        stunDuration: skill.stunDuration,
        slowDuration: skill.slowDuration,
        aoeOnHit: true,
        aoeRadius: skill.radius,
        color: skill.color,
      ),
    );
  }

  Vec2 _smartAimDirection(HeroEntity hero, double maxRange) {
    HeroEntity? nearest;
    var best = maxRange + 80;
    for (final h in heroes) {
      if (h.isAlive && h.team != hero.team) {
        final d = hero.pos.distanceTo(h.pos);
        if (d < best) {
          best = d;
          nearest = h;
        }
      }
    }
    if (nearest != null) {
      return Vec2(nearest.pos.x - hero.pos.x, nearest.pos.y - hero.pos.y).normalized();
    }
    for (final m in minions) {
      if (m.isAlive && m.team != hero.team && hero.pos.distanceTo(m.pos) <= maxRange + 50) {
        return Vec2(m.pos.x - hero.pos.x, m.pos.y - hero.pos.y).normalized();
      }
    }
    return Vec2(cos(hero.facingAngle), sin(hero.facingAngle));
  }

  void _applyAoeSkill({
    required HeroEntity hero,
    required Vec2 center,
    required double radius,
    required double damage,
    required double stun,
    required double slow,
    required Color color,
  }) {
    vfxPulses.add(VfxPulse(pos: center.copy(), maxRadius: radius, color: color, duration: 0.42));

    for (final target in heroes) {
      if (target.isAlive && target.team != hero.team && center.distanceTo(target.pos) <= radius + 20) {
        _damageHero(target, damage, hero);
        if (stun > 0) target.stunTimer = max(target.stunTimer, stun);
        if (slow > 0) target.slowTimer = max(target.slowTimer, slow);
      }
    }

    for (final m in minions) {
      if (m.isAlive && m.team != hero.team && center.distanceTo(m.pos) <= radius + 16) {
        _damageMinion(m, damage * 0.85, hero);
      }
    }

    for (final b in bosses) {
      if (b.isAlive && center.distanceTo(b.pos) <= radius + 34) {
        _damageBoss(b, damage, hero);
      }
    }
  }

  void triggerHealSpell(HeroEntity hero) {
    if (!hero.isAlive || hero.healSpellCooldown > 0) return;
    hero.healSpellCooldown = 18.0;
    final amount = hero.maxHp * 0.24;
    hero.hp = min(hero.maxHp, hero.hp + amount);
    hero.speedBuffTimer = max(hero.speedBuffTimer, 1.8);
    vfxPulses.add(VfxPulse(pos: hero.pos.copy(), maxRadius: 75, color: const Color(0xFF10B981), duration: 0.4));
    floatingTexts.add(FloatingText(pos: hero.pos.copy(), text: '+${amount.round()} HP', color: const Color(0xFF34D399)));
  }

  void triggerRecall(HeroEntity hero) {
    if (!hero.isAlive) return;
    hero.recallTimer = 2.6;
    floatingTexts.add(FloatingText(pos: hero.pos.copy(), text: 'RECALLING...', color: Colors.cyanAccent));
  }

  bool buyShopItem(HeroEntity hero, String itemId) {
    if (hero.boughtItemIds.contains(itemId) || hero.boughtItemIds.length >= 6) return false;
    final item = ShopCatalog.items.firstWhere((e) => e.id == itemId);
    if (hero.gold < item.cost) return false;

    hero.gold -= item.cost;
    hero.boughtItemIds.add(itemId);
    hero.attackDamage += item.bonusAttack;
    hero.maxHp += item.bonusHp;
    hero.hp += item.bonusHp;
    hero.moveSpeed += item.bonusSpeed;
    hero.cdrBonus = (hero.cdrBonus + item.cdrBonus).clamp(0.0, 0.4);
    hero.lifesteal = (hero.lifesteal + item.lifesteal).clamp(0.0, 0.35);
    return true;
  }

  void _damageHero(HeroEntity target, double amount, HeroEntity? attacker) {
    if (!target.isAlive) return;
    target.recallTimer = 0;

    var remaining = amount;
    if (target.shieldAmount > 0) {
      final absorbed = min(target.shieldAmount, remaining);
      target.shieldAmount -= absorbed;
      remaining -= absorbed;
    }

    target.hp -= remaining;

    if (attacker != null) {
      target.lastHitByHeroUid = attacker.uid;
      target.lastHitTimer = 6.0;

      if (attacker.lifesteal > 0 && remaining > 0) {
        attacker.hp = min(attacker.maxHp, attacker.hp + remaining * attacker.lifesteal);
      }

      // Check if attacker hit an enemy hero inside an enemy turret -> trigger turret aggro!
      for (final t in turrets) {
        if (t.isAlive && t.team == target.team && attacker.pos.distanceTo(t.pos) <= t.range) {
          attacker.turretAggroTimer = 3.0;
        }
      }
    }

    floatingTexts.add(
      FloatingText(
        pos: Vec2(target.pos.x, target.pos.y - 24),
        text: '-${amount.round()}',
        color: target.isPlayer ? const Color(0xFFF43F5E) : Colors.white,
      ),
    );

    if (target.hp <= 0) {
      target.hp = 0;
      target.deaths++;
      target.respawnTimer = 5.0 + target.level * 1.1;
      vfxPulses.add(VfxPulse(pos: target.pos.copy(), maxRadius: 90, color: const Color(0xFFF43F5E), duration: 0.5));
      if (attacker != null) {
        attacker.kills++;
        attacker.gold += 140;
        _grantXp(attacker, 110);
        if (attacker.isPlayer) pendingSounds.add(const ArenaSoundEvent('kill.wav'));
        floatingTexts.add(FloatingText(pos: attacker.pos.copy(), text: '+140g KILL!', color: const Color(0xFFFACC15)));
      }
    }
  }

  void _damageMinion(MinionEntity minion, double amount, HeroEntity? attacker) {
    if (!minion.isAlive) return;
    minion.hp -= amount;
    if (minion.hp <= 0) {
      minion.hp = 0;
      if (attacker != null) {
        attacker.gold += 26;
        _grantXp(attacker, 36);
        if (attacker.isPlayer) {
          floatingTexts.add(FloatingText(pos: minion.pos.copy(), text: '+26g', color: const Color(0xFFFACC15)));
        }
      }
    }
  }

  void _damageBoss(JungleBoss boss, double amount, HeroEntity? attacker) {
    if (!boss.isAlive) return;
    boss.hp -= amount;
    floatingTexts.add(FloatingText(pos: Vec2(boss.pos.x, boss.pos.y - 30), text: '-${amount.round()}', color: boss.color));
    if (boss.hp <= 0) {
      boss.hp = 0;
      boss.respawnTimer = 32.0;
      vfxPulses.add(VfxPulse(pos: boss.pos.copy(), maxRadius: 120, color: boss.color, duration: 0.55));
      if (attacker != null) {
        for (final h in heroes.where((h) => h.team == attacker.team)) {
          h.gold += 110;
          h.bossBuffTimer = 28.0;
          h.shieldAmount += 220;
          _grantXp(h, 90);
        }
        announcementEn = 'River Boss Slain!';
        announcementAr = 'تم القضاء على زعيم النهر!';
        announcementTimer = 3.0;
        if (attacker.isPlayer) pendingSounds.add(const ArenaSoundEvent('kill.wav'));
      }
    }
  }

  void _damageTurret(TurretEntity turret, double amount, HeroEntity? attacker) {
    if (!turret.isAlive) return;
    turret.hp -= amount;
    if (attacker != null) {
      attacker.turretDamage += amount.round();
    }
    if (turret.hp <= 0) {
      turret.hp = 0;
      vfxPulses.add(VfxPulse(pos: turret.pos.copy(), maxRadius: 130, color: const Color(0xFFF59E0B), duration: 0.6));
      if (!turret.isNexus) {
        for (final h in heroes.where((h) => h.team != turret.team)) {
          h.gold += 120;
          _grantXp(h, 80);
        }
        announcementEn = 'Turret Destroyed!';
        announcementAr = 'تم تدمير برج!';
        announcementTimer = 3.0;
        pendingSounds.add(const ArenaSoundEvent('kill.wav'));
      }
    }
  }

  void _grantXp(HeroEntity hero, double amount) {
    if (hero.level >= 10) return;
    hero.xp += amount;
    while (hero.level < 10 && hero.xp >= hero.xpForNextLevel) {
      hero.xp -= hero.xpForNextLevel;
      hero.level++;
      hero.maxHp += 95;
      hero.hp += 95;
      hero.maxMana += 35;
      hero.mana += 35;
      hero.attackDamage += 7.5;
      vfxPulses.add(VfxPulse(pos: hero.pos.copy(), maxRadius: 70, color: const Color(0xFFFACC15), duration: 0.45));
      if (hero.isPlayer) pendingSounds.add(const ArenaSoundEvent('levelup.wav'));
    }
  }

  void _updateMinions(double dt) {
    minions.removeWhere((m) => !m.isAlive);
    for (final m in minions) {
      if (m.attackCooldown > 0) m.attackCooldown = max(0, m.attackCooldown - dt);

      // Find nearest enemy minion, hero, or turret in aggro range
      MinionEntity? targetMinion;
      var bestMinionD = 200.0;
      for (final other in minions) {
        if (other.isAlive && other.team != m.team) {
          final d = m.pos.distanceTo(other.pos);
          if (d < bestMinionD) {
            bestMinionD = d;
            targetMinion = other;
          }
        }
      }

      if (targetMinion != null) {
        if (bestMinionD <= m.range) {
          if (m.attackCooldown <= 0) {
            m.attackCooldown = 1.05;
            _damageMinion(targetMinion, m.damage, null);
          }
        } else {
          final dir = Vec2(targetMinion.pos.x - m.pos.x, targetMinion.pos.y - m.pos.y).normalized();
          m.pos.x += dir.x * m.speed * dt;
          m.pos.y += dir.y * m.speed * dt;
        }
        continue;
      }

      TurretEntity? targetTurret;
      var bestTurretD = 220.0;
      for (final t in turrets) {
        if (t.isAlive && t.team != m.team) {
          final d = m.pos.distanceTo(t.pos);
          if (d < bestTurretD) {
            bestTurretD = d;
            targetTurret = t;
          }
        }
      }

      if (targetTurret != null) {
        if (bestTurretD <= m.range + 35) {
          if (m.attackCooldown <= 0) {
            m.attackCooldown = 1.1;
            _damageTurret(targetTurret, m.damage, null);
          }
        } else {
          final dir = Vec2(targetTurret.pos.x - m.pos.x, targetTurret.pos.y - m.pos.y).normalized();
          m.pos.x += dir.x * m.speed * dt;
          m.pos.y += dir.y * m.speed * dt;
        }
        continue;
      }

      final waypoints = m.team == Team.blue ? _blueWaypoints : _redWaypoints;
      if (m.waypointIndex < waypoints.length) {
        final wp = waypoints[m.waypointIndex];
        final d = m.pos.distanceTo(wp);
        if (d < 32) {
          m.waypointIndex++;
        } else {
          final dir = Vec2(wp.x - m.pos.x, wp.y - m.pos.y).normalized();
          m.pos.x += dir.x * m.speed * dt;
          m.pos.y += dir.y * m.speed * dt;
        }
      }
    }
  }

  void _updateTurrets(double dt) {
    for (final t in turrets) {
      if (!t.isAlive) {
        t.currentTargetPos = null;
        t.currentTargetUid = null;
        continue;
      }
      if (t.attackCooldown > 0) t.attackCooldown = max(0, t.attackCooldown - dt);

      HeroEntity? aggroHero;
      MinionEntity? minionTarget;
      HeroEntity? nearestHero;

      for (final h in heroes) {
        if (h.isAlive && h.team != t.team && h.pos.distanceTo(t.pos) <= t.range) {
          if (h.turretAggroTimer > 0) {
            aggroHero = h;
            break;
          }
          nearestHero ??= h;
        }
      }

      if (aggroHero == null) {
        var bestM = t.range;
        for (final m in minions) {
          if (m.isAlive && m.team != t.team) {
            final d = m.pos.distanceTo(t.pos);
            if (d <= bestM) {
              bestM = d;
              minionTarget = m;
            }
          }
        }
      }

      if (aggroHero != null) {
        t.currentTargetUid = aggroHero.uid;
        t.currentTargetPos = aggroHero.pos;
        if (t.attackCooldown <= 0) {
          t.attackCooldown = 1.15;
          _fireTurretShot(t, aggroHero.pos);
        }
      } else if (minionTarget != null) {
        t.currentTargetUid = minionTarget.uid;
        t.currentTargetPos = minionTarget.pos;
        if (t.attackCooldown <= 0) {
          t.attackCooldown = 1.15;
          _fireTurretShot(t, minionTarget.pos);
        }
      } else if (nearestHero != null) {
        t.currentTargetUid = nearestHero.uid;
        t.currentTargetPos = nearestHero.pos;
        if (t.attackCooldown <= 0) {
          t.attackCooldown = 1.15;
          _fireTurretShot(t, nearestHero.pos);
        }
      } else {
        t.currentTargetUid = null;
        t.currentTargetPos = null;
      }
    }
  }

  void _fireTurretShot(TurretEntity turret, Vec2 targetPos) {
    final dir = Vec2(targetPos.x - turret.pos.x, targetPos.y - turret.pos.y).normalized();
    projectiles.add(
      ProjectileEntity(
        ownerUid: turret.uid,
        team: turret.team,
        pos: turret.pos.copy(),
        dir: dir,
        speed: 520,
        remainingRange: turret.range + 40,
        radius: 20,
        damage: turret.damage,
        color: turret.team == Team.blue ? const Color(0xFF38BDF8) : const Color(0xFFF43F5E),
      ),
    );
  }

  void _updateBosses(double dt) {
    for (final b in bosses) {
      if (!b.isAlive) {
        b.respawnTimer -= dt;
        if (b.respawnTimer <= 0) {
          b.respawnTimer = 0;
          b.hp = b.maxHp;
          b.pos = b.homePos.copy();
        }
        continue;
      }
      if (b.attackCooldown > 0) b.attackCooldown = max(0, b.attackCooldown - dt);

      HeroEntity? target;
      var best = 160.0;
      for (final h in heroes) {
        if (h.isAlive && h.pos.distanceTo(b.pos) < best) {
          best = h.pos.distanceTo(b.pos);
          target = h;
        }
      }
      if (target != null && b.attackCooldown <= 0) {
        b.attackCooldown = 1.3;
        _damageHero(target, 42, null);
      } else if (target == null && b.hp < b.maxHp) {
        b.hp = min(b.maxHp, b.hp + 35 * dt);
      }
    }
  }

  void _updateProjectiles(double dt) {
    for (final p in projectiles) {
      if (p.expired) continue;
      final step = p.speed * dt;
      p.pos.x += p.dir.x * step;
      p.pos.y += p.dir.y * step;
      p.remainingRange -= step;

      if (p.remainingRange <= 0 ||
          p.pos.x < 0 ||
          p.pos.x > worldWidth ||
          p.pos.y < 0 ||
          p.pos.y > worldHeight) {
        p.expired = true;
        continue;
      }

      HeroEntity? attacker;
      for (final h in heroes) {
        if (h.uid == p.ownerUid) {
          attacker = h;
          break;
        }
      }

      for (final h in heroes) {
        if (h.isAlive && h.team != p.team && h.pos.distanceTo(p.pos) <= p.radius + 20) {
          p.expired = true;
          if (p.aoeOnHit && attacker != null) {
            _applyAoeSkill(
              hero: attacker,
              center: p.pos,
              radius: p.aoeRadius,
              damage: p.damage,
              stun: p.stunDuration,
              slow: p.slowDuration,
              color: p.color,
            );
          } else {
            _damageHero(h, p.damage, attacker);
            if (p.stunDuration > 0) h.stunTimer = max(h.stunTimer, p.stunDuration);
            if (p.slowDuration > 0) h.slowTimer = max(h.slowTimer, p.slowDuration);
            vfxPulses.add(VfxPulse(pos: p.pos.copy(), maxRadius: 40, color: p.color, duration: 0.25));
          }
          break;
        }
      }
      if (p.expired) continue;

      for (final m in minions) {
        if (m.isAlive && m.team != p.team && m.pos.distanceTo(p.pos) <= p.radius + 14) {
          p.expired = true;
          if (p.aoeOnHit && attacker != null) {
            _applyAoeSkill(
              hero: attacker,
              center: p.pos,
              radius: p.aoeRadius,
              damage: p.damage,
              stun: p.stunDuration,
              slow: p.slowDuration,
              color: p.color,
            );
          } else {
            _damageMinion(m, p.damage, attacker);
            vfxPulses.add(VfxPulse(pos: p.pos.copy(), maxRadius: 30, color: p.color, duration: 0.2));
          }
          break;
        }
      }
      if (p.expired) continue;

      for (final b in bosses) {
        if (b.isAlive && attacker != null && b.pos.distanceTo(p.pos) <= p.radius + 32) {
          p.expired = true;
          _damageBoss(b, p.damage, attacker);
          vfxPulses.add(VfxPulse(pos: p.pos.copy(), maxRadius: 48, color: p.color, duration: 0.25));
          break;
        }
      }
    }
    projectiles.removeWhere((p) => p.expired);
  }

  void _updateVfx(double dt) {
    for (final v in vfxPulses) {
      v.age += dt;
    }
    vfxPulses.removeWhere((v) => v.isFinished);

    for (final f in floatingTexts) {
      f.age += dt;
      f.pos.y -= 28 * dt;
    }
    floatingTexts.removeWhere((f) => f.isFinished);
  }
}
