import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page 1 du micro-onboarding — « Collectez en un geste ».
///
/// Action unique : taper la pile de pièces. Une pièce s'envole en arc de
/// cercle vers la cagnotte, qui se remplit avec un ressort, et le compteur
/// de cotisations s'incrémente (avec retour haptique).
class CollecteHero extends StatefulWidget {
  final bool active;

  const CollecteHero({super.key, this.active = true});

  @override
  State<CollecteHero> createState() => _CollecteHeroState();
}

class _CoinFlight {
  _CoinFlight(this.ctrl, this.control, this.arc);

  final AnimationController ctrl;

  /// Point de contrôle de la courbe quadratique (arc de la pièce).
  final Offset control;

  /// Rotation totale pendant le vol (tours × π).
  final double arc;
}

class _CollecteHeroState extends State<CollecteHero>
    with TickerProviderStateMixin {
  static const _maxCoins = 10;
  static const _pilePos = Offset(160, 254); // centre de la pile (stage 320×300)
  static const _jarMouth = Offset(160, 66); // entrée du pot

  final _rng = math.Random(7);
  final List<_CoinFlight> _flights = [];
  late final AnimationController _ambient;

  int _coins = 4;
  bool _goalShown = false;

  double get _fillTarget => 0.08 + 0.74 * (_coins / _maxCoins).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    if (!widget.active) _ambient.stop();
  }

  @override
  void didUpdateWidget(covariant CollecteHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active && !_ambient.isAnimating) _ambient.repeat();
    if (!widget.active && _ambient.isAnimating) _ambient.stop();
  }

  void _collect() {
    if (_coins >= _maxCoins) return;
    HapticFeedback.lightImpact();
    setState(() => _coins++);
    if (_coins == _maxCoins && !_goalShown) {
      _goalShown = true;
      HapticFeedback.mediumImpact();
    }

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    final flight = _CoinFlight(
      ctrl,
      Offset(
        _pilePos.dx + (_rng.nextDouble() - 0.5) * 60,
        _pilePos.dy - 160 - _rng.nextDouble() * 40,
      ),
      3 + _rng.nextDouble() * 3,
    );
    _flights.add(flight);
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _flights.remove(flight));
        ctrl.dispose();
      }
    });
    ctrl.forward();
  }

  @override
  void dispose() {
    for (final f in _flights) {
      f.ctrl.dispose();
    }
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildGlow(context),
          _buildJar(context),
          _buildPile(context),
          _buildCounterChip(context),
          if (_goalShown) _buildGoalChip(),
          ..._flights.map(_buildFlight),
        ],
      ),
    );
  }

  Widget _buildGlow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                scheme.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 75,
      top: 24,
      child: SizedBox(
        width: 170,
        height: 212,
        child: Stack(
          children: [
            // Corps du pot
            Positioned(
              top: 20,
              child: Container(
                width: 170,
                height: 192,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Remplissage or (anime vers la cible)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: _fillTarget, end: _fillTarget),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutBack,
                        builder: (context, f, _) => Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: f,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pièces visibles au fond du pot
                      const Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _JarCoin(28),
                            _JarCoin(30),
                            _JarCoin(26),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Goulot
            Positioned(
              top: 2,
              left: 55,
              child: Container(
                width: 60,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.8),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            // Reflet brillant
            Positioned(
              left: 26,
              top: 44,
              child: Container(
                width: 7,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          final bob = math.sin(_ambient.value * 2 * math.pi) * 4;
          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Tapez la pile de pièces',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Transform.translate(
                offset: Offset(0, bob),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.14,
                      child: _JarCoin(36, offset: const Offset(0, 8)),
                    ),
                    Transform.rotate(
                      angle: 0.08,
                      child: _JarCoin(38),
                    ),
                    Transform.rotate(
                      angle: -0.06,
                      child: _JarCoin(34, offset: const Offset(0, 6)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCounterChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey(_coins),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.savings_rounded,
                    size: 15, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  '$_coins cotisations',
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalChip() {
    return Positioned(
      top: 44,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: t, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration_rounded,
                    size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Objectif atteint !',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlight(_CoinFlight f) {
    return AnimatedBuilder(
      animation: f.ctrl,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(f.ctrl.value);
        final inv = 1 - t;
        final x = inv * inv * _pilePos.dx +
            2 * inv * t * f.control.dx +
            t * t * _jarMouth.dx;
        final y = inv * inv * _pilePos.dy +
            2 * inv * t * f.control.dy +
            t * t * _jarMouth.dy;
        final scale = 0.55 + 0.45 * math.sin(t * math.pi).clamp(0.0, 1.0);
        return Positioned(
          left: x - 17,
          top: y - 17,
          child: Transform.rotate(
            angle: f.arc * t * math.pi,
            child: Transform.scale(scale: scale, child: const _JarCoin(34)),
          ),
        );
      },
    );
  }
}

class _JarCoin extends StatelessWidget {
  final double size;
  final Offset offset;

  const _JarCoin(this.size, {this.offset = Offset.zero});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
          ),
          border: Border.all(color: const Color(0xFFD97706), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB45309).withValues(alpha: 0.35),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
