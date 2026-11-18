import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../engine/moba_arena_engine.dart';
import '../../models/moba_models.dart';

class ArenaPainter extends CustomPainter {
  final MobaArenaEngine engine;
  final Vec2? activeAimDir;
  final int? activeAimSkillIndex;
  final Map<String, ui.Image> heroPortraits;

  ArenaPainter({
    required this.engine,
    this.activeAimDir,
    this.activeAimSkillIndex,
    this.heroPortraits = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final camX = (engine.player.pos.x - size.width / 2)
        .clamp(0.0, max(0.0, MobaArenaEngine.worldWidth - size.width))
        .toDouble();
    final camY = (engine.player.pos.y - size.height / 2)
        .clamp(0.0, max(0.0, MobaArenaEngine.worldHeight - size.height))
        .toDouble();

    canvas.save();
    canvas.translate(-camX, -camY);

    _drawMapFloor(canvas);
    _drawJungleBushes(canvas);
    _drawObstacles(canvas);
    _drawTurrets(canvas);
    _drawBosses(canvas);
    _drawMinions(canvas);
    _drawHeroes(canvas);
    _drawAimIndicator(canvas);
    _drawProjectiles(canvas);
    _drawVfx(canvas);
    _drawFloatingTexts(canvas);

    canvas.restore();
  }

  void _drawMapFloor(Canvas canvas) {
    // Rich forest turf base
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, MobaArenaEngine.worldWidth, MobaArenaEngine.worldHeight),
      Paint()..color = const Color(0xFF102A22),
    );

    // Subtle organic meadow patches
    final grassPatchPaint = Paint()..color = const Color(0xFF15362B);
    final grassHighlightPaint = Paint()..color = const Color(0xFF1A4335);
    for (var x = 100.0; x < MobaArenaEngine.worldWidth; x += 280) {
      for (var y = 100.0; y < MobaArenaEngine.worldHeight; y += 260) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 190, height: 120), grassPatchPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 90, y + 70), width: 110, height: 70), grassHighlightPaint);
      }
    }

    // River shoreline sand/stone bank
    canvas.drawLine(
      const Offset(550, 120),
      const Offset(1850, 1280),
      Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 174
        ..strokeCap = StrokeCap.round,
    );

    // River deep water
    canvas.drawLine(
      const Offset(550, 120),
      const Offset(1850, 1280),
      Paint()
        ..color = const Color(0xFF075985)
        ..strokeWidth = 144
        ..strokeCap = StrokeCap.round,
    );

    // River bright current & animated wave highlights
    canvas.drawLine(
      const Offset(550, 120),
      const Offset(1850, 1280),
      Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.35)
        ..strokeWidth = 86
        ..strokeCap = StrokeCap.round,
    );

    final waveShift = (engine.matchTime * 28) % 120;
    final wavePaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final t = (i / 12.0 + waveShift / 1400.0) % 1.0;
      final wx = 580 + (1820 - 580) * t;
      final wy = 150 + (1250 - 150) * t;
      canvas.drawLine(Offset(wx - 16, wy - 14), Offset(wx + 16, wy + 14), wavePaint);
    }

    // Main stone battle road outer curb
    canvas.drawLine(
      const Offset(190, 1210),
      const Offset(2210, 190),
      Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 212
        ..strokeCap = StrokeCap.round,
    );

    // Paved stone road inner surface
    canvas.drawLine(
      const Offset(190, 1210),
      const Offset(2210, 190),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 188
        ..strokeCap = StrokeCap.round,
    );

    // Road flagstones & center lane runes
    final stonePaint = Paint()..color = const Color(0xFF283548);
    final runePaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.14);
    for (var i = 1; i < 20; i++) {
      final t = i / 20.0;
      final rx = 190 + (2210 - 190) * t;
      final ry = 1210 + (190 - 1210) * t;
      canvas.save();
      canvas.translate(rx, ry);
      canvas.rotate(-0.46);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-34, -56, 68, 112), const Radius.circular(10)),
        stonePaint,
      );
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 12, runePaint);
      }
      canvas.restore();
    }

    // Center River Timber/Stone Bridge
    canvas.save();
    canvas.translate(1200, 700);
    canvas.rotate(-0.46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-96, -104, 192, 208), const Radius.circular(14)),
      Paint()..color = const Color(0xFF451A03),
    );
    for (var px = -80.0; px <= 68.0; px += 22.0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(px, -94, 16, 188), const Radius.circular(4)),
        Paint()..color = const Color(0xFF78350F),
      );
    }
    canvas.drawRect(const Rect.fromLTWH(-98, -106, 196, 12), Paint()..color = const Color(0xFF94A3B8));
    canvas.drawRect(const Rect.fromLTWH(-98, 94, 196, 12), Paint()..color = const Color(0xFF94A3B8));
    canvas.restore();

    // Blue & Red Base Sanctuary Citadels
    _drawBaseSanctuary(canvas, const Offset(190, 1210), const Color(0xFF3B82F6));
    _drawBaseSanctuary(canvas, const Offset(2210, 190), const Color(0xFFF43F5E));
  }

  void _drawBaseSanctuary(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 185, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawCircle(
      center,
      165,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(center, 110, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(
      center,
      110,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawJungleBushes(Canvas canvas) {
    final bushPositions = const [
      Offset(700, 680),
      Offset(980, 620),
      Offset(1420, 780),
      Offset(1700, 720),
      Offset(1120, 480),
      Offset(1280, 920),
    ];
    for (final b in bushPositions) {
      canvas.drawCircle(b + const Offset(4, 6), 36, Paint()..color = Colors.black38);
      canvas.drawCircle(b, 34, Paint()..color = const Color(0xFF065F46));
      canvas.drawCircle(b + const Offset(-14, -8), 20, Paint()..color = const Color(0xFF047857));
      canvas.drawCircle(b + const Offset(14, -6), 22, Paint()..color = const Color(0xFF059669));
      canvas.drawCircle(b + const Offset(0, 12), 20, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.7));
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in engine.obstacles) {
      final c = Offset(obs.pos.x, obs.pos.y);
      final r = obs.radius;
      // Drop shadow
      canvas.drawCircle(c + const Offset(6, 10), r, Paint()..color = Colors.black45);

      // Rocky polygon cliff
      final cliffPath = Path();
      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final rad = r * (i.isEven ? 1.0 : 0.88);
        final pt = Offset(c.dx + cos(angle) * rad, c.dy + sin(angle) * rad);
        if (i == 0) {
          cliffPath.moveTo(pt.dx, pt.dy);
        } else {
          cliffPath.lineTo(pt.dx, pt.dy);
        }
      }
      cliffPath.close();
      canvas.drawPath(cliffPath, Paint()..color = const Color(0xFF334155));
      canvas.drawPath(
        cliffPath,
        Paint()
          ..color = const Color(0xFF64748B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );

      // Mossy rock cap
      canvas.drawCircle(c + const Offset(-4, -5), r * 0.62, Paint()..color = const Color(0xFF1E3A2F));
      canvas.drawCircle(c + const Offset(-7, -8), r * 0.38, Paint()..color = const Color(0xFF2D5A47));
    }
  }

  void _drawTurrets(Canvas canvas) {
    for (final t in engine.turrets) {
      if (!t.isAlive) continue;
      final isBlue = t.team == Team.blue;
      final baseColor = isBlue ? const Color(0xFF3B82F6) : const Color(0xFFF43F5E);
      final glowColor = isBlue ? const Color(0xFF60A5FA) : const Color(0xFFFB7185);
      final targetingPlayer = t.currentTargetUid == engine.player.uid;

      if (!isBlue) {
        canvas.drawCircle(
          Offset(t.pos.x, t.pos.y),
          t.range,
          Paint()
            ..color = targetingPlayer
                ? const Color(0xFFF43F5E).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = targetingPlayer ? 3.2 : 1.5,
        );
      }

      if (t.currentTargetPos != null) {
        canvas.drawLine(
          Offset(t.pos.x, t.pos.y),
          Offset(t.currentTargetPos!.x, t.currentTargetPos!.y),
          Paint()
            ..color = glowColor.withValues(alpha: 0.55)
            ..strokeWidth = 3,
        );
      }

      final c = Offset(t.pos.x, t.pos.y);
      final size = t.isNexus ? 52.0 : 35.0;
      // Tower shadow
      canvas.drawCircle(c + const Offset(6, 10), size, Paint()..color = Colors.black54);

      // Stone octagon tower base
      final towerPath = Path();
      final sides = t.isNexus ? 8 : 6;
      for (var i = 0; i < sides; i++) {
        final a = i * (2 * pi / sides) + engine.matchTime * (t.isNexus ? 0.2 : 0.0);
        final pt = Offset(c.dx + cos(a) * size, c.dy + sin(a) * size);
        if (i == 0) {
          towerPath.moveTo(pt.dx, pt.dy);
        } else {
          towerPath.lineTo(pt.dx, pt.dy);
        }
      }
      towerPath.close();
      canvas.drawPath(towerPath, Paint()..color = const Color(0xFF1E293B));
      canvas.drawPath(
        towerPath,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );

      // Corner buttresses / battlements
      for (var i = 0; i < 4; i++) {
        final a = i * pi / 2 + pi / 4;
        final bx = c.dx + cos(a) * (size * 0.72);
        final by = c.dy + sin(a) * (size * 0.72);
        canvas.drawCircle(Offset(bx, by), size * 0.2, Paint()..color = const Color(0xFF475569));
      }

      // Floating Crystal Core Diamond
      final crystalR = size * 0.52;
      final crystal = Path()
        ..moveTo(c.dx, c.dy - crystalR)
        ..lineTo(c.dx + crystalR * 0.8, c.dy)
        ..lineTo(c.dx, c.dy + crystalR)
        ..lineTo(c.dx - crystalR * 0.8, c.dy)
        ..close();
      canvas.drawPath(crystal, Paint()..color = t.isNexus ? const Color(0xFFFACC15) : glowColor);
      canvas.drawPath(
        crystal,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      _drawHpBar(
        canvas,
        centerX: t.pos.x,
        topY: t.pos.y - size - 18,
        width: t.isNexus ? 104 : 72,
        ratio: (t.hp / t.maxHp).clamp(0.0, 1.0),
        color: baseColor,
      );
    }
  }

  void _drawBosses(Canvas canvas) {
    for (final b in engine.bosses) {
      final c = Offset(b.pos.x, b.pos.y);
      if (!b.isAlive) {
        canvas.drawCircle(
          Offset(b.homePos.x, b.homePos.y),
          32,
          Paint()
            ..color = b.color.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        continue;
      }

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.drawCircle(const Offset(4, 8), 36, Paint()..color = Colors.black45);

      if (b.uid == 'river_lord') {
        // Winged Horned River Drake Boss
        final wingSpan = sin(engine.matchTime * 4) * 5;
        final leftWing = Path()
          ..moveTo(-12, -4)
          ..lineTo(-46, -26 + wingSpan)
          ..lineTo(-34, 14)
          ..close();
        final rightWing = Path()
          ..moveTo(12, -4)
          ..lineTo(46, -26 + wingSpan)
          ..lineTo(34, 14)
          ..close();
        canvas.drawPath(leftWing, Paint()..color = const Color(0xFFB45309));
        canvas.drawPath(rightWing, Paint()..color = const Color(0xFFB45309));

        // Armored body & tail
        canvas.drawOval(const Rect.fromLTWH(-22, -24, 44, 48), Paint()..color = const Color(0xFFD97706));
        canvas.drawOval(
          const Rect.fromLTWH(-22, -24, 44, 48),
          Paint()
            ..color = const Color(0xFFFDE047)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Horns & glowing magma eyes
        canvas.drawLine(const Offset(-10, -20), const Offset(-22, -36), Paint()..color = const Color(0xFFFEF08A)..strokeWidth = 5..strokeCap = StrokeCap.round);
        canvas.drawLine(const Offset(10, -20), const Offset(22, -36), Paint()..color = const Color(0xFFFEF08A)..strokeWidth = 5..strokeCap = StrokeCap.round);
        canvas.drawCircle(const Offset(-7, -10), 4, Paint()..color = const Color(0xFFF43F5E));
        canvas.drawCircle(const Offset(7, -10), 4, Paint()..color = const Color(0xFFF43F5E));
      } else {
        // Hexagonal Crystal Guardian Turtle
        for (final fp in const [Offset(-24, -18), Offset(24, -18), Offset(-24, 18), Offset(24, 18)]) {
          canvas.drawOval(Rect.fromCenter(center: fp, width: 18, height: 12), Paint()..color = const Color(0xFF0E7490));
        }
        canvas.drawCircle(const Offset(0, -28), 11, Paint()..color = const Color(0xFF0891B2));
        final shell = Path();
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          final pt = Offset(cos(a) * 28, sin(a) * 28);
          if (i == 0) {
            shell.moveTo(pt.dx, pt.dy);
          } else {
            shell.lineTo(pt.dx, pt.dy);
          }
        }
        shell.close();
        canvas.drawPath(shell, Paint()..color = const Color(0xFF06B6D4));
        canvas.drawPath(
          shell,
          Paint()
            ..color = const Color(0xFFA5F3FC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(Offset.zero, 11, Paint()..color = const Color(0xFFFEF08A));
      }

      canvas.restore();

      _drawHpBar(
        canvas,
        centerX: b.pos.x,
        topY: b.pos.y - 48,
        width: 78,
        ratio: (b.hp / b.maxHp).clamp(0.0, 1.0),
        color: b.color,
      );
    }
  }

  void _drawMinions(Canvas canvas) {
    for (final m in engine.minions) {
      if (!m.isAlive) continue;
      final isBlue = m.team == Team.blue;
      final primary = isBlue ? const Color(0xFF2563EB) : const Color(0xFFE11D48);
      final trim = isBlue ? const Color(0xFF93C5FD) : const Color(0xFFFDA4AF);
      final dirAngle = isBlue ? -0.46 : 2.68;

      canvas.save();
      canvas.translate(m.pos.x, m.pos.y);
      canvas.drawCircle(const Offset(2, 4), 14, Paint()..color = Colors.black38);
      canvas.rotate(dirAngle);

      if (m.isRanged) {
        // Hooded Mage Minion with glowing staff
        canvas.drawLine(const Offset(2, 10), const Offset(18, 12), Paint()..color = const Color(0xFFD97706)..strokeWidth = 3);
        canvas.drawCircle(const Offset(19, 12), 4.5, Paint()..color = trim);
        final cloak = Path()
          ..moveTo(-14, -10)
          ..lineTo(10, 0)
          ..lineTo(-14, 10)
          ..close();
        canvas.drawPath(cloak, Paint()..color = primary);
        canvas.drawCircle(Offset.zero, 8, Paint()..color = trim);
      } else {
        // Armored Footman Minion with Shield & Spear
        canvas.drawLine(const Offset(0, 8), const Offset(20, 8), Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 3..strokeCap = StrokeCap.round);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -14, 14, 7), const Radius.circular(3)),
          Paint()..color = trim,
        );
        canvas.drawCircle(Offset.zero, 11, Paint()..color = primary);
        canvas.drawCircle(const Offset(2, 0), 6, Paint()..color = const Color(0xFFCBD5E1));
      }

      canvas.restore();

      _drawHpBar(
        canvas,
        centerX: m.pos.x,
        topY: m.pos.y - 22,
        width: 30,
        ratio: (m.hp / m.maxHp).clamp(0.0, 1.0),
        color: primary,
        height: 4,
      );
    }
  }

  void _drawHeroes(Canvas canvas) {
    for (final h in engine.heroes) {
      if (!h.isAlive) continue;
      final isBlue = h.team == Team.blue;
      final teamColor = isBlue ? const Color(0xFF38BDF8) : const Color(0xFFF43F5E);
      final atkSwing = h.basicCooldown > 0
          ? sin((h.basicCooldown / h.def.attackCooldown) * pi) * 0.75
          : 0.0;

      canvas.save();
      canvas.translate(h.pos.x, h.pos.y);

      // Ground shadow & Player aura ring
      canvas.drawOval(const Rect.fromLTWH(-24, 14, 48, 18), Paint()..color = Colors.black54);
      if (h.isPlayer) {
        canvas.drawCircle(
          Offset.zero,
          36,
          Paint()
            ..color = const Color(0xFFFACC15).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      if (h.shieldAmount > 0) {
        canvas.drawCircle(
          Offset.zero,
          34,
          Paint()
            ..color = const Color(0xFF34D399).withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
      }

      // Rotated hero body, cape, boots, pauldrons & weapon
      canvas.save();
      canvas.rotate(h.facingAngle);

      final stride = sin(h.walkPhase) * 6.0;
      // Walking armored boots
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(stride - 5, -14, 12, 8), const Radius.circular(4)),
        Paint()..color = const Color(0xFF1E293B),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-stride - 5, 6, 12, 8), const Radius.circular(4)),
        Paint()..color = const Color(0xFF1E293B),
      );

      // Flowing Hero Cape behind character
      final capeFlutter = sin(engine.matchTime * 5 + h.walkPhase) * 3.5;
      final cape = Path()
        ..moveTo(-6, -16)
        ..lineTo(-34, -12 + capeFlutter)
        ..lineTo(-30, 12 + capeFlutter)
        ..lineTo(-6, 16)
        ..close();
      canvas.drawPath(cape, Paint()..color = h.def.primaryColor.withValues(alpha: 0.85));

      // Weapon by Hero Role (with swing animation!)
      canvas.save();
      canvas.rotate(atkSwing);
      _drawHeroWeapon(canvas, h);
      canvas.restore();

      // Broad armored shoulder pauldrons
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -28, 22, 13), const Radius.circular(6)),
        Paint()..color = h.def.primaryColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, 15, 22, 13), const Radius.circular(6)),
        Paint()..color = h.def.primaryColor,
      );
      canvas.restore(); // unrotate for upright portrait emblem

      // Portrait Medallion in center (uses AI-generated hero portrait if loaded!)
      final portrait = heroPortraits[h.def.id];
      const avatarR = 23.0;
      canvas.drawCircle(Offset.zero, avatarR + 3, Paint()..color = const Color(0xFF0F172A));

      if (portrait != null) {
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: avatarR)));
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: Offset.zero, radius: avatarR),
          image: portrait,
          fit: BoxFit.cover,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset.zero, avatarR, Paint()..color = h.def.primaryColor);
        canvas.drawCircle(const Offset(0, -3), 9, Paint()..color = h.def.secondaryColor);
      }

      // Team Border Ring + Gold Trim
      canvas.drawCircle(
        Offset.zero,
        avatarR,
        Paint()
          ..color = teamColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      if (h.isPlayer) {
        canvas.drawCircle(
          Offset.zero,
          avatarR + 3,
          Paint()
            ..color = const Color(0xFFFACC15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      // Stun stars
      if (h.stunTimer > 0) {
        for (var i = 0; i < 3; i++) {
          final a = engine.matchTime * 6 + i * (2 * pi / 3);
          canvas.drawCircle(Offset(cos(a) * 18, -32 + sin(a) * 5), 4, Paint()..color = const Color(0xFFFACC15));
        }
      }

      canvas.restore();

      // Hero Name + Level + HP/Mana bars
      final namePainter = TextPainter(
        text: TextSpan(
          text: h.def.nameEn,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      namePainter.paint(canvas, Offset(h.pos.x - namePainter.width / 2, h.pos.y - 56));

      _drawHpBar(
        canvas,
        centerX: h.pos.x,
        topY: h.pos.y - 42,
        width: 62,
        ratio: (h.hp / h.maxHp).clamp(0.0, 1.0),
        color: isBlue ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
      );
      _drawHpBar(
        canvas,
        centerX: h.pos.x,
        topY: h.pos.y - 35,
        width: 62,
        ratio: (h.mana / h.maxMana).clamp(0.0, 1.0),
        color: const Color(0xFF38BDF8),
        height: 3.5,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${h.level}',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.drawCircle(Offset(h.pos.x - 37, h.pos.y - 38), 9, Paint()..color = const Color(0xFF0F172A));
      canvas.drawCircle(
        Offset(h.pos.x - 37, h.pos.y - 38),
        9,
        Paint()
          ..color = const Color(0xFFFACC15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      tp.paint(canvas, Offset(h.pos.x - 37 - tp.width / 2, h.pos.y - 38 - tp.height / 2));
    }
  }

  void _drawHeroWeapon(Canvas canvas, HeroEntity h) {
    switch (h.def.role) {
      case HeroRole.fighter:
        // Twin-edged glowing Azure Greatsword
        final blade = Path()
          ..moveTo(14, 14)
          ..lineTo(44, 18)
          ..lineTo(54, 14)
          ..lineTo(44, 10)
          ..close();
        canvas.drawPath(blade, Paint()..color = const Color(0xFF7DD3FC));
        canvas.drawLine(const Offset(16, 14), const Offset(50, 14), Paint()..color = Colors.white..strokeWidth = 2);
        canvas.drawLine(const Offset(14, 7), const Offset(14, 21), Paint()..color = const Color(0xFFFACC15)..strokeWidth = 4);
        break;
      case HeroRole.mage:
        // Arcane Starfire Staff
        canvas.drawLine(const Offset(10, 18), const Offset(42, 18), Paint()..color = const Color(0xFFD97706)..strokeWidth = 4.5..strokeCap = StrokeCap.round);
        canvas.drawCircle(const Offset(45, 18), 9, Paint()..color = const Color(0xFFC084FC).withValues(alpha: 0.45));
        canvas.drawCircle(const Offset(45, 18), 5.5, Paint()..color = const Color(0xFFF472B6));
        break;
      case HeroRole.tank:
        // Heavy Runic Tower Shield + Warhammer
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(16, -24, 12, 30), const Radius.circular(5)),
          Paint()..color = const Color(0xFF065F46),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(16, -24, 12, 30), const Radius.circular(5)),
          Paint()
            ..color = const Color(0xFFFACC15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawLine(const Offset(12, 16), const Offset(36, 16), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(32, 8, 10, 16), const Radius.circular(3)),
          Paint()..color = const Color(0xFF34D399),
        );
        break;
      case HeroRole.marksman:
        // Golden Energy Recurve Bow
        canvas.drawArc(
          const Rect.fromLTWH(8, -22, 28, 44),
          -pi / 2.2,
          pi / 1.1,
          false,
          Paint()
            ..color = const Color(0xFFFBBF24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5,
        );
        canvas.drawLine(const Offset(20, -20), const Offset(20, 20), Paint()..color = const Color(0xFFFEF08A)..strokeWidth = 1.5);
        canvas.drawLine(const Offset(16, 0), const Offset(42, 0), Paint()..color = Colors.white..strokeWidth = 2.2);
        break;
    }
  }

  void _drawAimIndicator(Canvas canvas) {
    if (activeAimDir == null || activeAimSkillIndex == null || !engine.player.isAlive) return;
    final skill = engine.player.def.skills[activeAimSkillIndex!];
    final p = engine.player.pos;
    final range = skill.range > 0 ? skill.range : skill.radius;
    final dir = activeAimDir!.normalized();

    if (skill.range == 0) {
      canvas.drawCircle(Offset(p.x, p.y), skill.radius, Paint()..color = skill.color.withValues(alpha: 0.28));
      canvas.drawCircle(
        Offset(p.x, p.y),
        skill.radius,
        Paint()
          ..color = skill.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    } else {
      final end = Offset(p.x + dir.x * range, p.y + dir.y * range);
      canvas.drawLine(
        Offset(p.x, p.y),
        end,
        Paint()
          ..color = skill.color.withValues(alpha: 0.65)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(end, skill.radius * 0.65, Paint()..color = skill.color.withValues(alpha: 0.35));
    }
  }

  void _drawProjectiles(Canvas canvas) {
    for (final p in engine.projectiles) {
      final angle = atan2(p.dir.y, p.dir.x);
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      canvas.rotate(angle);
      // Glowing trail + tapered energy bolt
      final bolt = Path()
        ..moveTo(14, 0)
        ..lineTo(-8, -7)
        ..lineTo(-18, 0)
        ..lineTo(-8, 7)
        ..close();
      canvas.drawPath(bolt, Paint()..color = p.color);
      canvas.drawCircle(const Offset(4, 0), 5, Paint()..color = Colors.white);
      canvas.restore();
    }
  }

  void _drawVfx(Canvas canvas) {
    for (final v in engine.vfxPulses) {
      final alpha = (1.0 - v.progress).clamp(0.0, 1.0);
      final r = v.maxRadius * (0.35 + 0.65 * v.progress);
      canvas.drawCircle(Offset(v.pos.x, v.pos.y), r, Paint()..color = v.color.withValues(alpha: alpha * 0.3));
      canvas.drawCircle(
        Offset(v.pos.x, v.pos.y),
        r,
        Paint()
          ..color = v.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }
  }

  void _drawFloatingTexts(Canvas canvas) {
    for (final f in engine.floatingTexts) {
      final alpha = (1.0 - (f.age / f.duration)).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: f.color.withValues(alpha: alpha),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.pos.x - tp.width / 2, f.pos.y));
    }
  }

  void _drawHpBar(
    Canvas canvas, {
    required double centerX,
    required double topY,
    required double width,
    required double ratio,
    required Color color,
    double height = 6,
  }) {
    final left = centerX - width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, topY, width, height), const Radius.circular(3)),
      Paint()..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, topY, width * ratio, height), const Radius.circular(3)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}

class MinimapPainter extends CustomPainter {
  final MobaArenaEngine engine;
  const MinimapPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = const Color(0xFF0E241C).withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()
        ..color = Colors.amber.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final sx = size.width / MobaArenaEngine.worldWidth;
    final sy = size.height / MobaArenaEngine.worldHeight;

    // River & Lane lines
    canvas.drawLine(
      Offset(550 * sx, 120 * sy),
      Offset(1850 * sx, 1280 * sy),
      Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.45)
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(190 * sx, 1210 * sy),
      Offset(2210 * sx, 190 * sy),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 6,
    );

    for (final t in engine.turrets) {
      if (!t.isAlive) continue;
      canvas.drawCircle(
        Offset(t.pos.x * sx, t.pos.y * sy),
        t.isNexus ? 5 : 3.2,
        Paint()..color = t.team == Team.blue ? const Color(0xFF3B82F6) : const Color(0xFFF43F5E),
      );
    }

    for (final b in engine.bosses) {
      if (!b.isAlive) continue;
      canvas.drawCircle(Offset(b.pos.x * sx, b.pos.y * sy), 3.5, Paint()..color = b.color);
    }

    for (final h in engine.heroes) {
      if (!h.isAlive) continue;
      canvas.drawCircle(
        Offset(h.pos.x * sx, h.pos.y * sy),
        h.isPlayer ? 4.8 : 3.4,
        Paint()
          ..color = h.isPlayer
              ? const Color(0xFFFACC15)
              : (h.team == Team.blue ? const Color(0xFF38BDF8) : const Color(0xFFFB7185)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) => true;
}
