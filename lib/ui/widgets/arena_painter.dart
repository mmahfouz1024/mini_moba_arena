import 'dart:math';
import 'package:flutter/material.dart';
import '../../engine/moba_arena_engine.dart';
import '../../models/moba_models.dart';

class ArenaPainter extends CustomPainter {
  final MobaArenaEngine engine;
  final Vec2? activeAimDir;
  final int? activeAimSkillIndex;

  ArenaPainter({
    required this.engine,
    this.activeAimDir,
    this.activeAimSkillIndex,
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
    final bgPaint = Paint()..color = const Color(0xFF0E1726);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, MobaArenaEngine.worldWidth, MobaArenaEngine.worldHeight),
      bgPaint,
    );

    // Subtle tactical grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= MobaArenaEngine.worldWidth; x += 120) {
      canvas.drawLine(Offset(x, 0), Offset(x, MobaArenaEngine.worldHeight), gridPaint);
    }
    for (var y = 0.0; y <= MobaArenaEngine.worldHeight; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(MobaArenaEngine.worldWidth, y), gridPaint);
    }

    // River diagonally across center
    final riverPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.22)
      ..strokeWidth = 140
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(550, 120), const Offset(1850, 1280), riverPaint);

    // Main battle lane path
    final lanePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.9)
      ..strokeWidth = 190
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(190, 1210), const Offset(2210, 190), lanePaint);

    final laneBorder = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.35)
      ..strokeWidth = 198
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(190, 1210), const Offset(2210, 190), laneBorder);

    // Blue & Red Healing Fountains
    canvas.drawCircle(
      const Offset(190, 1210),
      175,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      const Offset(2210, 190),
      175,
      Paint()..color = const Color(0xFFE11D48).withValues(alpha: 0.16),
    );
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in engine.obstacles) {
      canvas.drawCircle(
        Offset(obs.pos.x, obs.pos.y),
        obs.radius,
        Paint()..color = const Color(0xFF1E293B),
      );
      canvas.drawCircle(
        Offset(obs.pos.x, obs.pos.y),
        obs.radius,
        Paint()
          ..color = const Color(0xFF475569)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(
        Offset(obs.pos.x - 8, obs.pos.y - 8),
        obs.radius * 0.55,
        Paint()..color = const Color(0xFF334155).withValues(alpha: 0.5),
      );
    }
  }

  void _drawTurrets(Canvas canvas) {
    for (final t in engine.turrets) {
      if (!t.isAlive) continue;
      final isBlue = t.team == Team.blue;
      final baseColor = isBlue ? const Color(0xFF3B82F6) : const Color(0xFFF43F5E);
      final targetingPlayer = t.currentTargetUid == engine.player.uid;

      // Range ring when enemy turret is nearby or targeting player
      if (!isBlue) {
        canvas.drawCircle(
          Offset(t.pos.x, t.pos.y),
          t.range,
          Paint()
            ..color = targetingPlayer
                ? const Color(0xFFF43F5E).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = targetingPlayer ? 3.0 : 1.5,
        );
      }

      if (t.currentTargetPos != null) {
        canvas.drawLine(
          Offset(t.pos.x, t.pos.y),
          Offset(t.currentTargetPos!.x, t.currentTargetPos!.y),
          Paint()
            ..color = baseColor.withValues(alpha: 0.45)
            ..strokeWidth = 2.5,
        );
      }

      final size = t.isNexus ? 46.0 : 32.0;
      canvas.drawCircle(
        Offset(t.pos.x, t.pos.y),
        size,
        Paint()..color = const Color(0xFF0F172A),
      );
      canvas.drawCircle(
        Offset(t.pos.x, t.pos.y),
        size,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      canvas.drawCircle(
        Offset(t.pos.x, t.pos.y),
        size * 0.48,
        Paint()..color = t.isNexus ? const Color(0xFFFACC15) : baseColor,
      );

      _drawHpBar(
        canvas,
        centerX: t.pos.x,
        topY: t.pos.y - size - 16,
        width: t.isNexus ? 94 : 68,
        ratio: (t.hp / t.maxHp).clamp(0.0, 1.0),
        color: baseColor,
      );
    }
  }

  void _drawBosses(Canvas canvas) {
    for (final b in engine.bosses) {
      if (!b.isAlive) {
        canvas.drawCircle(
          Offset(b.homePos.x, b.homePos.y),
          28,
          Paint()
            ..color = b.color.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        continue;
      }

      canvas.drawCircle(
        Offset(b.pos.x, b.pos.y),
        38,
        Paint()..color = b.color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        Offset(b.pos.x, b.pos.y),
        28,
        Paint()..color = b.color,
      );
      canvas.drawCircle(
        Offset(b.pos.x, b.pos.y),
        28,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      _drawHpBar(
        canvas,
        centerX: b.pos.x,
        topY: b.pos.y - 42,
        width: 72,
        ratio: (b.hp / b.maxHp).clamp(0.0, 1.0),
        color: b.color,
      );
    }
  }

  void _drawMinions(Canvas canvas) {
    for (final m in engine.minions) {
      if (!m.isAlive) continue;
      final c = m.team == Team.blue ? const Color(0xFF60A5FA) : const Color(0xFFFB7185);
      final r = m.isRanged ? 11.0 : 14.0;
      canvas.drawCircle(Offset(m.pos.x, m.pos.y), r, Paint()..color = c);
      canvas.drawCircle(
        Offset(m.pos.x, m.pos.y),
        r,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _drawHpBar(
        canvas,
        centerX: m.pos.x,
        topY: m.pos.y - r - 8,
        width: 28,
        ratio: (m.hp / m.maxHp).clamp(0.0, 1.0),
        color: c,
        height: 4,
      );
    }
  }

  void _drawHeroes(Canvas canvas) {
    for (final h in engine.heroes) {
      if (!h.isAlive) continue;
      final isBlue = h.team == Team.blue;
      final teamColor = isBlue ? const Color(0xFF38BDF8) : const Color(0xFFF43F5E);

      // Player highlight ring
      if (h.isPlayer) {
        canvas.drawCircle(
          Offset(h.pos.x, h.pos.y),
          32,
          Paint()
            ..color = const Color(0xFFFACC15).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      // Shield ring
      if (h.shieldAmount > 0) {
        canvas.drawCircle(
          Offset(h.pos.x, h.pos.y),
          29,
          Paint()
            ..color = const Color(0xFF34D399).withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      // Facing weapon cone
      final tipX = h.pos.x + cos(h.facingAngle) * 32;
      final tipY = h.pos.y + sin(h.facingAngle) * 32;
      canvas.drawLine(
        Offset(h.pos.x, h.pos.y),
        Offset(tipX, tipY),
        Paint()
          ..color = h.def.secondaryColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // Hero body
      canvas.drawCircle(Offset(h.pos.x, h.pos.y), 23, Paint()..color = h.def.primaryColor);
      canvas.drawCircle(
        Offset(h.pos.x, h.pos.y),
        23,
        Paint()
          ..color = teamColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );

      // Stun indicator
      if (h.stunTimer > 0) {
        canvas.drawCircle(
          Offset(h.pos.x, h.pos.y - 30),
          6,
          Paint()..color = const Color(0xFFFACC15),
        );
      }

      // Level & HP/Mana bars
      _drawHpBar(
        canvas,
        centerX: h.pos.x,
        topY: h.pos.y - 38,
        width: 58,
        ratio: (h.hp / h.maxHp).clamp(0.0, 1.0),
        color: isBlue ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
      );
      _drawHpBar(
        canvas,
        centerX: h.pos.x,
        topY: h.pos.y - 31,
        width: 58,
        ratio: (h.mana / h.maxMana).clamp(0.0, 1.0),
        color: const Color(0xFF38BDF8),
        height: 3.5,
      );

      // Level pill
      final tp = TextPainter(
        text: TextSpan(
          text: '${h.level}',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.drawCircle(Offset(h.pos.x - 34, h.pos.y - 34), 8, Paint()..color = const Color(0xFF0F172A));
      tp.paint(canvas, Offset(h.pos.x - 34 - tp.width / 2, h.pos.y - 34 - tp.height / 2));
    }
  }

  void _drawAimIndicator(Canvas canvas) {
    if (activeAimDir == null || activeAimSkillIndex == null || !engine.player.isAlive) return;
    final skill = engine.player.def.skills[activeAimSkillIndex!];
    final p = engine.player.pos;
    final range = skill.range > 0 ? skill.range : skill.radius;
    final dir = activeAimDir!.normalized();

    if (skill.range == 0) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        skill.radius,
        Paint()
          ..color = skill.color.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill,
      );
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
          ..color = skill.color.withValues(alpha: 0.7)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        end,
        skill.radius * 0.65,
        Paint()
          ..color = skill.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawProjectiles(Canvas canvas) {
    for (final p in engine.projectiles) {
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        p.radius * 0.6,
        Paint()..color = p.color,
      );
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        p.radius * 0.9,
        Paint()..color = p.color.withValues(alpha: 0.3),
      );
    }
  }

  void _drawVfx(Canvas canvas) {
    for (final v in engine.vfxPulses) {
      final alpha = (1.0 - v.progress).clamp(0.0, 1.0);
      final r = v.maxRadius * (0.35 + 0.65 * v.progress);
      canvas.drawCircle(
        Offset(v.pos.x, v.pos.y),
        r,
        Paint()
          ..color = v.color.withValues(alpha: alpha * 0.32)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(v.pos.x, v.pos.y),
        r,
        Paint()
          ..color = v.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
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
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final sx = size.width / MobaArenaEngine.worldWidth;
    final sy = size.height / MobaArenaEngine.worldHeight;

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
        h.isPlayer ? 4.5 : 3.2,
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
