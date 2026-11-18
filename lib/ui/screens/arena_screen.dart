import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../engine/moba_arena_engine.dart';
import '../../models/moba_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';
import '../widgets/arena_painter.dart';
import '../widgets/virtual_controls.dart';

class ArenaScreen extends StatefulWidget {
  final PlayerMetaProfile profile;
  final ArenaMode mode;
  final Future<void> Function() onSaveProfile;

  const ArenaScreen({
    super.key,
    required this.profile,
    required this.mode,
    required this.onSaveProfile,
  });

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> with SingleTickerProviderStateMixin {
  late MobaArenaEngine _engine;
  late Ticker _ticker;
  Duration? _lastTick;

  Vec2? _aimDir;
  int? _aimSkillIndex;
  bool _shopOpen = false;
  bool _matchEndedHandled = false;
  final Map<String, ui.Image> _heroPortraits = {};

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _engine = MobaArenaEngine(
      mode: widget.mode,
      playerHeroDef: HeroCatalog.byId(widget.profile.selectedHeroId),
    );
    _loadHeroPortraits();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadHeroPortraits() async {
    for (final hero in HeroCatalog.heroes) {
      try {
        final data = await rootBundle.load(hero.portraitAsset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (mounted) {
          _heroPortraits[hero.id] = frame.image;
        }
      } catch (_) {
        // Fallback vector portrait renders cleanly if asset load fails in tests.
      }
    }
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick!).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    _syncKeyboardMove();
    _engine.update(dt);

    if (_engine.pendingSounds.isNotEmpty) {
      for (final s in _engine.pendingSounds) {
        SoundService.instance.playEffect(s.asset);
      }
      _engine.pendingSounds.clear();
    }

    if (_engine.winner != null && !_matchEndedHandled) {
      _matchEndedHandled = true;
      _handleMatchEnd();
    }

    if (mounted) setState(() {});
  }

  void _syncKeyboardMove() {
    if (_pressedKeys.isEmpty) return;
    var dx = 0.0;
    var dy = 0.0;
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    _engine.playerMoveInput = Vec2(dx, dy);
  }

  Future<void> _handleMatchEnd() async {
    final won = _engine.winner == Team.blue;
    widget.profile.totalKills += _engine.player.kills;
    if (won) {
      widget.profile.wins++;
      widget.profile.accountGold += widget.mode == ArenaMode.arena3v3 ? 95 : 55;
      widget.profile.rankPoints += 24;
    } else {
      widget.profile.losses++;
      widget.profile.accountGold += 25;
      widget.profile.rankPoints = (widget.profile.rankPoints - 10).clamp(0, 9999);
    }
    await widget.onSaveProfile();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String _formatTime(double seconds) {
    final s = seconds.floor();
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.profile.isArabic;
    final blueKills = _engine.heroes.where((h) => h.team == Team.blue).fold(0, (a, b) => a + b.kills);
    final redKills = _engine.heroes.where((h) => h.team == Team.red).fold(0, (a, b) => a + b.kills);
    final p = _engine.player;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _pressedKeys.add(event.logicalKey);
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _engine.performBasicAttack(p);
          } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
            _engine.castSkill(p, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
            _engine.castSkill(p, 1);
          } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
            _engine.castSkill(p, 2);
          } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
            _engine.triggerHealSpell(p);
          } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
            _engine.triggerRecall(p);
          }
        } else if (event is KeyUpEvent) {
          _pressedKeys.remove(event.logicalKey);
          if (_pressedKeys.isEmpty) {
            _engine.playerMoveInput = Vec2(0, 0);
          }
        }
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: SafeArea(
            child: Stack(
              children: [
                // World Viewport
                Positioned.fill(
                  child: CustomPaint(
                    painter: ArenaPainter(
                      engine: _engine,
                      activeAimDir: _aimDir,
                      activeAimSkillIndex: _aimSkillIndex,
                      heroPortraits: _heroPortraits,
                    ),
                  ),
                ),

                // Unified Non-Overlapping Top HUD Row
                Positioned(
                  top: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 116,
                        height: 68,
                        child: CustomPaint(painter: MinimapPainter(engine: _engine)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                p.def.portraitAsset,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 32,
                                  height: 32,
                                  color: p.def.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 64,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lv.${p.level}',
                                    style: const TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (p.hp / p.maxHp).clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor: Colors.black54,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (p.mana / p.maxMana).clamp(0.0, 1.0),
                                      minHeight: 4,
                                      backgroundColor: Colors.black54,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$blueKills',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('VS', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ),
                                Text(
                                  '$redKills',
                                  style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatTime(_engine.matchTime),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'K:${p.kills} D:${p.deaths}',
                                  style: const TextStyle(color: Color(0xFFFACC15), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _shopOpen = !_shopOpen),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.92),
                          foregroundColor: const Color(0xFFFACC15),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.shopping_bag, size: 16),
                        label: Text('${p.gold}g', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

              // Center Announcement Banner
              if (_engine.announcementEn != null)
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isAr ? (_engine.announcementAr ?? '') : (_engine.announcementEn ?? ''),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),

              // Respawn Countdown
              if (!p.isAlive && _engine.winner == null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF43F5E)),
                    ),
                    child: Text(
                      '${L10n.tr('respawn_in', isAr)} ${p.respawnTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // Bottom-Left Virtual Joystick + Recall/Heal quick buttons
              Positioned(
                left: 18,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    VirtualJoystick(
                      size: 118,
                      onChanged: (vec) {
                        _engine.playerMoveInput = vec;
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkillAimButton(
                          label: L10n.tr('heal_spell', isAr),
                          icon: Icons.favorite,
                          cooldownRemaining: p.healSpellCooldown,
                          maxCooldown: 18.0,
                          hasEnoughMana: true,
                          color: const Color(0xFF10B981),
                          size: 48,
                          onCast: (_) => _engine.triggerHealSpell(p),
                          onAimPreview: (_) {},
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _engine.triggerRecall(p),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.recallTimer > 0
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFF1E293B).withValues(alpha: 0.9),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
                            ),
                            child: const Icon(Icons.home, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom-Right MOBA Ability Arc
              Positioned(
                right: 18,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkillAimButton(
                      label: 'S1',
                      icon: p.def.skills[0].icon,
                      cooldownRemaining: p.skillCooldowns[0],
                      maxCooldown: p.def.skills[0].cooldown,
                      hasEnoughMana: p.mana >= p.def.skills[0].manaCost,
                      color: p.def.skills[0].color,
                      size: 58,
                      onAimPreview: (dir) => setState(() {
                        _aimDir = dir;
                        _aimSkillIndex = dir == null ? null : 0;
                      }),
                      onCast: (dir) => _engine.castSkill(p, 0, aimDir: dir),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkillAimButton(
                          label: 'ULT',
                          icon: p.def.skills[2].icon,
                          cooldownRemaining: p.skillCooldowns[2],
                          maxCooldown: p.def.skills[2].cooldown,
                          hasEnoughMana: p.mana >= p.def.skills[2].manaCost,
                          color: p.def.skills[2].color,
                          size: 64,
                          onAimPreview: (dir) => setState(() {
                            _aimDir = dir;
                            _aimSkillIndex = dir == null ? null : 2;
                          }),
                          onCast: (dir) => _engine.castSkill(p, 2, aimDir: dir),
                        ),
                        const SizedBox(height: 10),
                        SkillAimButton(
                          label: 'S2',
                          icon: p.def.skills[1].icon,
                          cooldownRemaining: p.skillCooldowns[1],
                          maxCooldown: p.def.skills[1].cooldown,
                          hasEnoughMana: p.mana >= p.def.skills[1].manaCost,
                          color: p.def.skills[1].color,
                          size: 58,
                          onAimPreview: (dir) => setState(() {
                            _aimDir = dir;
                            _aimSkillIndex = dir == null ? null : 1;
                          }),
                          onCast: (dir) => _engine.castSkill(p, 1, aimDir: dir),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _engine.performBasicAttack(p),
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
                          ),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on, color: Colors.white, size: 26),
                            Text(
                              L10n.tr('attack', isAr),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick-Buy Item Shop Panel
              if (_shopOpen)
                Positioned(
                  right: 14,
                  top: 56,
                  width: 290,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${L10n.tr('shop', isAr)} (${p.gold}g)',
                              style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _shopOpen = false),
                              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                            ),
                          ],
                        ),
                        ...ShopCatalog.items.map((item) {
                          final owned = p.boughtItemIds.contains(item.id);
                          final canBuy = !owned && p.gold >= item.cost;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.shield, color: item.color),
                            title: Text(
                              isAr ? item.nameAr : item.nameEn,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isAr ? item.statLabelAr : item.statLabelEn,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            trailing: ElevatedButton(
                              onPressed: canBuy
                                  ? () {
                                      SoundService.instance.playEffect('click.wav');
                                      setState(() {
                                        _engine.buyShopItem(p, item.id);
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: owned ? Colors.white12 : item.color,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: Text(owned ? '✓' : '${item.cost}g', style: const TextStyle(fontSize: 11)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Victory / Defeat Overlay
              if (_engine.winner != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.78),
                  child: Center(
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _engine.winner == Team.blue
                              ? const Color(0xFFFACC15)
                              : const Color(0xFFF43F5E),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _engine.winner == Team.blue ? Icons.emoji_events : Icons.shield,
                            color: _engine.winner == Team.blue
                                ? const Color(0xFFFACC15)
                                : const Color(0xFFF43F5E),
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _engine.winner == Team.blue
                                ? L10n.tr('victory', isAr)
                                : L10n.tr('defeat', isAr),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'K: ${p.kills}   D: ${p.deaths}   Lv.${p.level}',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _engine.winner == Team.blue
                                ? '+${widget.mode == ArenaMode.arena3v3 ? 95 : 55} Gold • +24 Rank'
                                : '+25 Gold',
                            style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _matchEndedHandled = false;
                                      _engine = MobaArenaEngine(
                                        mode: widget.mode,
                                        playerHeroDef: HeroCatalog.byId(widget.profile.selectedHeroId),
                                      );
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                  child: Text(L10n.tr('play_again', isAr)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(L10n.tr('back_lobby', isAr)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
