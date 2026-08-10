import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page 3 du micro-onboarding — « Une transparence totale ».
///
/// Bouclier lumineux animé (halo, anneau pointillé rotatif, étincelles
/// orbitales). Quand l'utilisateur appuie sur « Créer mon compte », la page
/// déclenche la célébration : un tampon ✓ s'appose sur le bouclier pendant
/// que les confettis plein écran (gérés par OnboardingScreen) explosent.
class ConfettiHero extends StatefulWidget {
  final bool active;
  final bool celebrating;

  const ConfettiHero({
    super.key,
    this.active = true,
    this.celebrating = false,
  });

  @override
  State<ConfettiHero> createState() => _ConfettiHeroState();
}

class _ConfettiHeroState extends State<ConfettiHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    if (!widget.active) _ambient.stop();
  }

  @override
  void didUpdateWidget(covariant ConfettiHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active && !_ambient.isAnimating) _ambient.repeat();
    if (!widget.active && _ambient.isAnimating) _ambient.stop();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildHalo(scheme),
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(280, 280),
                painter: _DashedRingPainter(
                  progress: _ambient.value,
                  color: scheme.primary,
                ),
              );
            },
          ),
          _buildSparkles(scheme),
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) {
              final breathe =
                  1 + 0.035 * math.sin(_ambient.value * 2 * math.pi);
              return Transform.scale(
                scale: breathe,
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2962FF), Color(0xFF7C4DFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.celebrating) _buildStamp(),
        ],
      ),
    );
  }

  Widget _buildHalo(ColorScheme scheme) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSparkles(ColorScheme scheme) {
    const colors = [Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF7C4DFF)];
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final t = _ambient.value * 2 * math.pi;
        return Stack(
          children: [
            for (var i = 0; i < 3; i++)
              Positioned(
                left: 160 - 6 + 118 * math.cos(t + i * 2 * math.pi / 3),
                top: 150 - 6 + 118 * math.sin(t + i * 2 * math.pi / 3),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i],
                    boxShadow: [
                      BoxShadow(
                        color: colors[i].withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStamp() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.scale(scale: clamped, child: child),
        );
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFF10B981), width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 56,
            color: Color(0xFF059669),
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DashedRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rect = Offset.zero & size;
    const segments = 16;
    const gap = 0.045;

    for (var i = 0; i < segments; i++) {
      final start = (i / segments + progress) * 2 * math.pi;
      canvas.drawArc(rect, start, 0.5 * math.pi / segments - gap, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.progress != progress || old.color != color;
}
