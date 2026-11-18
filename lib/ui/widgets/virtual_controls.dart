import 'dart:math';
import 'package:flutter/material.dart';
import '../../engine/moba_arena_engine.dart';

class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Vec2> onChanged;
  final double size;

  const VirtualJoystick({
    super.key,
    required this.onChanged,
    this.size = 128,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobOffset = Offset.zero;

  void _updateFromLocal(Offset localPos) {
    final radius = widget.size / 2;
    final delta = localPos - Offset(radius, radius);
    final maxDist = radius * 0.72;
    final dist = delta.distance;
    final clamped = dist > maxDist ? (delta / dist) * maxDist : delta;
    setState(() => _knobOffset = clamped);
    widget.onChanged(Vec2(clamped.dx / maxDist, clamped.dy / maxDist));
  }

  void _reset() {
    setState(() => _knobOffset = Offset.zero);
    widget.onChanged(Vec2(0, 0));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _updateFromLocal(d.localPosition),
      onPanUpdate: (d) => _updateFromLocal(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: _knobOffset,
            child: Container(
              width: widget.size * 0.42,
              height: widget.size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.75),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkillAimButton extends StatefulWidget {
  final String label;
  final double cooldownRemaining;
  final double maxCooldown;
  final bool hasEnoughMana;
  final Color color;
  final double size;
  final ValueChanged<Vec2?> onCast;
  final ValueChanged<Vec2?> onAimPreview;

  const SkillAimButton({
    super.key,
    required this.label,
    required this.cooldownRemaining,
    required this.maxCooldown,
    required this.hasEnoughMana,
    required this.color,
    this.size = 64,
    required this.onCast,
    required this.onAimPreview,
  });

  @override
  State<SkillAimButton> createState() => _SkillAimButtonState();
}

class _SkillAimButtonState extends State<SkillAimButton> {
  Vec2? _aim;

  bool get _ready => widget.cooldownRemaining <= 0 && widget.hasEnoughMana;

  void _updateAim(Offset localPos) {
    if (!_ready) return;
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPos - center;
    if (delta.distance > 12) {
      final dir = Vec2(delta.dx, delta.dy).normalized();
      _aim = dir;
      widget.onAimPreview(dir);
    } else {
      _aim = null;
      widget.onAimPreview(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cdRatio = widget.maxCooldown > 0
        ? (widget.cooldownRemaining / widget.maxCooldown).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        if (_ready) widget.onCast(null);
      },
      onPanStart: (d) => _updateAim(d.localPosition),
      onPanUpdate: (d) => _updateAim(d.localPosition),
      onPanEnd: (_) {
        if (_ready) {
          widget.onCast(_aim);
        }
        _aim = null;
        widget.onAimPreview(null);
      },
      onPanCancel: () {
        _aim = null;
        widget.onAimPreview(null);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ready ? widget.color.withValues(alpha: 0.85) : const Color(0xFF1E293B),
                border: Border.all(
                  color: _ready ? Colors.white : Colors.white24,
                  width: 2.2,
                ),
                boxShadow: _ready
                    ? [BoxShadow(color: widget.color.withValues(alpha: 0.45), blurRadius: 10)]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.hasEnoughMana ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (cdRatio > 0)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
                child: Center(
                  child: Text(
                    widget.cooldownRemaining.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            if (cdRatio > 0)
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _CooldownArcPainter(cdRatio),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CooldownArcPainter extends CustomPainter {
  final double ratio;
  _CooldownArcPainter(this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(2),
      -pi / 2,
      2 * pi * ratio,
      false,
      Paint()
        ..color = const Color(0xFFFACC15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _CooldownArcPainter oldDelegate) => oldDelegate.ratio != ratio;
}
