import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingHeroAnimation extends StatefulWidget {
  const OnboardingHeroAnimation({super.key});

  @override
  State<OnboardingHeroAnimation> createState() =>
      _OnboardingHeroAnimationState();
}

class _OnboardingHeroAnimationState extends State<OnboardingHeroAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Timeline sur 12 secondes (valeurs normalisées 0..1)
  static const _tr = 0.042; // 0.5s de transition

  static const _s1End = 0.225; // 2.70s – fin scène 1
  static const _s2End = 0.550; // 6.60s – fin scène 2
  static const _s3End = 0.767; // 9.20s – fin scène 3

  // Sous-événements scène 2 (normalisés /12s)
  static const _s2Card = 0.225;
  static const _s2Counter = 0.242;
  static const _s2CounterEnd = 0.342;
  static const _s2Particles = 0.242;
  static const _s2Valid1 = 0.292;
  static const _s2Valid2 = 0.350;
  static const _s2Valid3 = 0.408;
  static const _s2Toast = 0.433;

  // Sous-événements scène 3
  static const _s3Bars = 0.583;
  static const _s3AvgLine = 0.617;
  static const _s3Badge = 0.658;
  static const _s3Ring = 0.692;
  static const _s3Confetti = 0.575;

  // Sous-événements scène 4
  static const _s4Logo = 0.792;
  static const _s4Title = 0.817;
  static const _s4Sub = 0.833;
  static const _s4Dots = 0.850;
  static const _s4Social = 0.875;

  final _rng = math.Random(42);
  late final List<_Confetti> _confettis;
  late final List<_Particle> _particles;
  bool _haptic1 = false, _haptic2 = false, _haptic3 = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 12000),
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    );
    _ctrl.addListener(_onCtrlUpdate);
    _ctrl.forward();

    _particles = List.generate(
      35,
      (_) => _Particle(
        angle: _rng.nextDouble() * 2 * math.pi,
        distance: 40 + _rng.nextDouble() * 80,
        delay: _rng.nextDouble() * 0.15,
        size: 3 + _rng.nextDouble() * 3,
        colorIndex: _rng.nextInt(3),
      ),
    );
    _confettis = List.generate(
      45,
      (_) => _Confetti(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.6,
        speed: 0.6 + _rng.nextDouble() * 0.8,
        sizeW: 4 + _rng.nextDouble() * 6,
        sizeH: 3 + _rng.nextDouble() * 5,
        colorIndex: _rng.nextInt(5),
        isCircle: _rng.nextDouble() > 0.6,
      ),
    );
  }

  void _onCtrlUpdate() {
    if (!mounted) return;
    final v = _ctrl.value;
    if (!_haptic1 && v >= _s2Valid1 + 0.017) {
      _haptic1 = true;
      HapticFeedback.lightImpact();
    }
    if (!_haptic2 && v >= _s2Valid2 + 0.017) {
      _haptic2 = true;
      HapticFeedback.lightImpact();
    }
    if (!_haptic3 && v >= _s2Valid3 + 0.017) {
      _haptic3 = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  // Progress helpers -----------------------------------------------------------
  double _ep(double v, double start, double end) {
    if (v <= start) return 0.0;
    if (v >= end) return 1.0;
    return (v - start) / (end - start);
  }

  double _cp(double v, double start, double end, Curve curve) {
    return curve.transform(_ep(v, start, end)).clamp(0.0, 1.0);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const designW = 393.0;
        const designH = 530.0;
        final scale = (constraints.maxWidth / designW)
            .clamp(0.0, constraints.maxHeight / designH);

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final v = _ctrl.value;
            return FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: designW,
                height: designH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32 * scale),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      _buildScene1(v),
                      _buildScene2(v),
                      _buildScene3(v),
                      _buildScene4(v),
                      _buildPhaseBadge(v),
                      _buildTimeline(v),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── SCENE 1 – CHAOS ────────────────────────────────────────────────────────
  Widget _buildScene1(double v) {
    final fadeOut = _ep(v, _s1End, _s1End + _tr);
    final op = (1.0 - fadeOut).clamp(0.0, 1.0);
    if (op <= 0) return const SizedBox.shrink();

    final blur = fadeOut * 6.0;

    Widget content = Transform.scale(
      scale: 1.0 + 0.05 * fadeOut,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFe4e9f7), Color(0xFFd8dfee)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NoisePainter(seed: 42),
              ),
            ),
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: _buildDocStack(v),
            ),
            _buildHand(v),
            _buildStressIcons(v),
            Positioned.fill(
              child: CustomPaint(
                painter: _ScribblePainter(progress: _ep(v, 0.133, _s1End - 0.04)),
              ),
            ),
          ],
        ),
      ),
    );

    if (blur > 0.5) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return Opacity(opacity: op, child: content);
  }

  Widget _buildDocStack(double v) {
    final shakeP = _ep(v, 0.158, 0.192);
    final shakeX = shakeP > 0 ? math.sin(shakeP * math.pi * 12) * 4 * (1 - shakeP) : 0.0;
    final shakeY = shakeP > 0 ? math.cos(shakeP * math.pi * 10) * 3 * (1 - shakeP) : 0.0;
    final shakeR = shakeP > 0 ? math.sin(shakeP * math.pi * 8) * 2 * (1 - shakeP) : 0.0;

    return Center(
      child: Transform.translate(
        offset: Offset(shakeX, shakeY + 20),
        child: Transform.rotate(
          angle: shakeR * math.pi / 180,
          child: SizedBox(
            width: 270,
            height: 320,
            child: Stack(
              children: [
                _buildNotebookPage(v, 2, -6, 0.017, 12, false),
                _buildNotebookPage(v, 1, 4, 0.027, 18, true),
                _buildNotebookPage(v, 0, -2, 0.037, 14, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotebookPage(double v, int idx, double rot, double delay,
      int lineCount, bool hasScribbles) {
    final t = _cp(v, delay, delay + 0.058, Curves.easeOutBack);
    final yOff = -420 * (1 - t);
    final angle = rot * (1 - (1 - t) * 0.6);
    final offset = Offset(idx * 5.0, yOff);

    final scribbleP = hasScribbles
        ? _ep(v, delay + 0.015, delay + 0.045).clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      top: 10 + idx * 35.0,
      left: 5 + idx * 4.0,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Gestion manuelle',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    ...List.generate(lineCount, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    )),
                  ],
                ),
                if (scribbleP > 0.01)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PageScribblePainter(progress: scribbleP, seed: idx),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHand(double v) {
    final t = _ep(v, 0.083, 0.125);
    final tapP = _ep(v, 0.125, 0.133);
    final fadeP = _ep(v, 0.175, 0.192);
    if (t <= 0 && fadeP <= 0) return const SizedBox.shrink();

    final dx = 120 * (1 - Curves.easeOutBack.transform(t));
    final dy = 100 * (1 - Curves.easeOutBack.transform(t));
    final tapScale = tapP > 0 ? 1.0 - 0.15 * Curves.easeInOutBack.transform(tapP) : 1.0;
    final op = (1.0 - fadeP).clamp(0.0, 1.0);

    return Positioned(
      bottom: 30,
      right: 30,
      child: Opacity(
        opacity: op,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: tapScale,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:  Semantics(
                label: 'Doigt pointant',
                child: const Center(
                  child: Icon(
                    Icons.touch_app_outlined,
                    size: 28,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStressIcons(double v) {
    final icons = [
      Icons.warning_amber_rounded,
      Icons.help_outline_rounded,
      Icons.assignment_late_outlined,
    ];
    final iconColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFFDC2626),
    ];
    final bgColors = [
      const Color(0xFFFEE2E2),
      const Color(0xFFFEF3C7),
      const Color(0xFFFEE2E2),
    ];
    final positions = [
      const Offset(36, 70),
      const Offset(290, 50),
      const Offset(50, 220),
    ];

    return Stack(
      children: List.generate(3, (i) {
        final t = _cp(v, 0.133 + i * 0.008, 0.150 + i * 0.008, Curves.easeOutBack);
        final fadeP = _ep(v, 0.175, 0.192);
        if (t <= 0) return const SizedBox.shrink();
        final op = (1.0 - fadeP).clamp(0.0, 1.0);
        return Positioned(
          left: positions[i].dx,
          top: positions[i].dy,
          child: Opacity(
            opacity: op * t,
            child: Transform.scale(
              scale: t,
                child: Semantics(
                  label: ['Alerte', 'Aide', 'Retard'][i],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColors[i],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icons[i],
                      size: 24,
                      color: iconColors[i],
                    ),
                  ),
                ),
            ),
          ),
        );
      }),
    );
  }

  // ── SCENE 2 – DASHBOARD ────────────────────────────────────────────────────
  Widget _buildScene2(double v) {
    final fadeIn = _ep(v, _s1End - _tr, _s1End);
    final fadeOut = _ep(v, _s2End, _s2End + _tr);
    final op = (fadeIn - fadeOut).clamp(0.0, 1.0);
    if (op <= 0) return const SizedBox.shrink();

    final xOff = 60 * (1.0 - fadeIn);
    final blur = (1.0 - fadeIn) * 6.0 + fadeOut * 6.0;

    final cardT = _cp(v, _s2Card, _s2Card + 0.042, Curves.easeOutBack);
    final cardY = 30 * (1 - cardT);

    Widget content = Stack(
      children: [
        // Blobs de fond
        Positioned(
          top: -60, left: -60,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -60, right: -60,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF059669).withValues(alpha: 0.25),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Carte glassmorphique
        Center(
          child: Opacity(
            opacity: cardT,
            child: Transform.translate(
              offset: Offset(0, cardY),
              child: Transform.scale(
                scale: cardT,
                child: _buildGlassCard(v),
              ),
            ),
          ),
        ),
        // Particules
        ..._buildParticles(v),
        // Notification toast
        _buildToast(v),
      ],
    );

    if (blur > 0.5) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return Opacity(
      opacity: op,
      child: Transform.translate(
        offset: Offset(xOff, 0),
        child: content,
      ),
    );
  }

  Widget _buildGlassCard(double v) {
    const cardW = 270.0;
    const btnPulse = _s2Particles + 0.108;
    const btnPulseDur = 0.042;
    final pulseT = _ep(v, btnPulse, btnPulse + btnPulseDur);
    final ringScale = 0.9 + 0.4 * pulseT;
    final ringOp = 0.7 * (1 - pulseT);

    // Compteurs calculés localement à partir de v
    final _c1 = _cp(v, _s2Counter, _s2CounterEnd, const Cubic(0.15, 0, 0.2, 1));
    final _localFill = 0.80 * _c1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: cardW,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text('Suivi en temps réel',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: Color(0xFFCBD5E1))),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('+12%',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: Color(0xFF34D399))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Montant
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Cagnotte disponible',
                    style: TextStyle(
                        fontSize: 9, color: Color(0xFF94A3B8))),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${(100000 * _cp(v, _s2Counter, _s2CounterEnd, const Cubic(0.15, 0, 0.2, 1))).round()} FCFA',
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Barre de progression
              Row(
                children: [
                  const Text('Objectif du mois',
                      style: TextStyle(
                          fontSize: 9, color: Color(0xFF94A3B8))),
                  const Spacer(),
                  Text(
                    '${(_localFill * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: Colors.white.withValues(alpha: 0.1),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _localFill > 0 ? _localFill : 0.001,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Membres
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Membres (3)',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8))),
              ),
              const SizedBox(height: 6),
              _buildMemberRow(v, 'Thomas L.', 'Trésorier', 'TL',
                  const Color(0xFF3B82F6), _s2Valid1),
              const SizedBox(height: 4),
              _buildMemberRow(v, 'Marie C.', 'Membre', 'MC',
                  const Color(0xFF8B5CF6), _s2Valid2),
              const SizedBox(height: 4),
              _buildMemberRow(v, 'Pierre D.', 'Membre', 'PD',
                  const Color(0xFFF59E0B), _s2Valid3),
              const SizedBox(height: 12),
              // Bouton
              _buildCotiserBtn(v, ringScale, ringOp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(double v, String name, String role, String initials,
      Color avatarColor, double validStart) {
    final statusChange = _ep(v, validStart + 0.017, validStart + 0.033);
    final isPaid = statusChange > 0;
    final rowFlash = isPaid
        ? Color.lerp(const Color(0xFF10B981).withValues(alpha: 0.15),
            Colors.transparent, statusChange.clamp(0.0, 1.0))
        : Colors.transparent;

    // Checkmark animation
    final chkAppear = _cp(v, validStart, validStart + 0.029, Curves.easeOutBack);
    final chkFly = _ep(v, validStart + 0.042, validStart + 0.075);
    final chkOp = (chkAppear - chkFly).clamp(0.0, 1.0);
    final chkScale = chkAppear > chkFly
        ? chkAppear
        : (1.0 - chkFly).clamp(0.0, 1.0);
    final chkY = chkFly > 0 ? -50 * chkFly : 0.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: rowFlash,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(initials,
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: avatarColor.withValues(alpha: 0.9))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: Color(0xFFE2E8F0))),
                        Text(role,
                            style: const TextStyle(
                                fontSize: 7, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Payé',
                              style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.w700,
                                  color: Color(0xFF34D399))),
                          SizedBox(width: 2),
                          Icon(Icons.check, size: 10, color: Color(0xFF34D399)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                      ),
                      child: const Text('En attente',
                          style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: Color(0xFFFBBF24))),
                    ),
                ],
              ),
              if (chkOp > 0.01)
                Positioned(
                  right: 10,
                  top: 8 + chkY,
                  child: Opacity(
                    opacity: chkOp,
                    child: Transform.scale(
                      scale: chkScale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF065F46)),
                            SizedBox(width: 4),
                            Text('Validé !',
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCotiserBtn(double v, double ringScale, double ringOp) {
    final btnT = _cp(v, _s2Card + 0.050, _s2Card + 0.092, Curves.easeOutBack);
    if (btnT <= 0) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        if (ringOp > 0.01)
          Container(
            width: 240,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981), width: 2),
            ),
          ),
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF059669),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Cotiser maintenant',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  List<Widget> _buildParticles(double v) {
    final tp = _ep(v, _s2Particles, _s2Particles + 0.067);
    if (tp <= 0) return [];

    return _particles.map((p) {
      final elapsed = tp - p.delay;
      if (elapsed <= 0) return const SizedBox.shrink();
      final prog = Curves.decelerate.transform(elapsed.clamp(0.0, 1.0));
      final rad = p.angle;
      final x = math.cos(rad) * p.distance * prog;
      final y = math.sin(rad) * p.distance * prog - 20 * prog;
      final op = (1 - prog * 0.7).clamp(0.0, 1.0);
      final sc = prog < 0.08 ? prog / 0.08 : (1 - prog * 0.6);

      final colors = [const Color(0xFF1246C8), const Color(0xFF059669), const Color(0xFFD97706)];

      return Positioned(
        left: 170 + x - p.size / 2,
        top: 150 + y - p.size / 2,
        child: Opacity(
          opacity: op,
          child: Transform.scale(
            scale: sc.clamp(0.0, 1.0),
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[p.colorIndex],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildToast(double v) {
    final appear = _cp(v, _s2Toast, _s2Toast + 0.042, Curves.easeOutBack);
    final disappear = _ep(v, _s2Toast + 0.067, _s2Toast + 0.142);
    final op = (appear - disappear).clamp(0.0, 1.0);
    if (op <= 0) return const SizedBox.shrink();

    final xOff = 120 * (1 - appear);

    return Positioned(
      top: 55,
      right: 8,
      child: Opacity(
        opacity: op,
        child: Transform.translate(
          offset: Offset(xOff, 0),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Cotisation reçue !',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('Pierre a cotisé 25 000 FCFA',
                        style: TextStyle(
                            fontSize: 8, color: Color(0xFF475569))),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SCENE 3 – CHART ──────────────────────────────────────────────────────────
  Widget _buildScene3(double v) {
    final fadeIn = _ep(v, _s2End - _tr, _s2End);
    final fadeOut = _ep(v, _s3End, _s3End + _tr);
    final op = (fadeIn - fadeOut).clamp(0.0, 1.0);
    if (op <= 0) return const SizedBox.shrink();

    final xOff = 60 * (1.0 - fadeIn);
    final blur = (1.0 - fadeIn) * 6.0 + fadeOut * 6.0;

    final barHeights = [30, 45, 25, 80, 58, 96];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui'];
    final barValues = ['15K', '22K', '12K', '38K', '28K', '45K'];

    Widget content = Stack(
      children: [
        // Blob violet
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Carte glassmorphique
        Center(
          child: _buildChartCard(v, barHeights, months, barValues),
        ),
        // Confettis
        ..._buildConfettis(v),
      ],
    );

    if (blur > 0.5) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return Opacity(
      opacity: op,
      child: Transform.translate(
        offset: Offset(xOff, 0),
        child: content,
      ),
    );
  }

  Widget _buildChartCard(double v, List<int> heights, List<String> months,
      List<String> values) {
    final cardT = _cp(v, _s2End, _s2End + 0.042, Curves.easeOutBack);
    final cardY = 30 * (1 - cardT);
    final avgLineP = _cp(v, _s3AvgLine, _s3AvgLine + 0.050, Curves.decelerate);
    final ringP = _cp(v, _s3Ring, _s3Ring + 0.042, Curves.easeOutBack);

    return Opacity(
      opacity: cardT,
      child: Transform.translate(
        offset: Offset(0, cardY),
        child: Transform.scale(
          scale: cardT,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 270,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    const Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Suivi en ligne',
                                  style: TextStyle(
                                      fontSize: 9, color: Color(0xFF94A3B8))),
                              Text('Cotisations 2024',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Cumul total',
                                style: TextStyle(
                                    fontSize: 8, color: Color(0xFF94A3B8))),
                            Text('110 000 FCFA',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barres
                    SizedBox(
                      height: 130,
                      child: Stack(
                        children: [
                          // Ligne médiane (pointillés)
                          Positioned(
                            left: 0, right: 0,
                            bottom: 55,
                            child: Opacity(
                              opacity: avgLineP,
                              child: SizedBox(
                                height: 1,
                                child: CustomPaint(
                                  painter: _DashedLinePainter(
                                    progress: avgLineP,
                                    color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(6, (i) {
                              final barP = _cp(
                                  v,
                                  _s3Bars + i * 0.006,
                                  _s3Bars + 0.058 + i * 0.006,
                                  Curves.easeOutBack);
                              final labelP = _ep(v, _s3Bars + 0.042 + i * 0.006,
                                  _s3Bars + 0.067 + i * 0.006);
                              final isLast = i == 5;
                              final badgeP = _cp(
                                  v, _s3Badge, _s3Badge + 0.033, Curves.easeOutBack);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Badge Record
                                      if (isLast)
                                        Opacity(
                                          opacity: badgeP,
                                          child: Transform.scale(
                                            scale: badgeP,
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const FittedBox(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.trending_up, size: 9, color: Colors.white),
                                                    SizedBox(width: 2),
                                                    Text('Record',
                                                        style: TextStyle(
                                                            fontSize: 7,
                                                            fontWeight: FontWeight.w800,
                                                            color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Barre
                                      Container(
                                        height: (heights[i] / 100) * 90 * barP,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4)),
                                          gradient: isLast
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF059669), Color(0xFF2DD4BF)])
                                              : null,
                                          color: isLast ? null : const Color(0xFF2563EB).withValues(alpha: 0.8),
                                        ),
                                      ),
                                      // Libellé valeur
                                      Opacity(
                                        opacity: labelP,
                                        child: Text(values[i],
                                            style: TextStyle(
                                                fontSize: 7,
                                                color: isLast
                                                    ? const Color(0xFF6EE7B7)
                                                    : const Color(0xFFCBD5E1))),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(months[i],
                                          style: TextStyle(
                                              fontSize: 7,
                                              fontWeight:
                                                  isLast ? FontWeight.w700 : null,
                                              color: isLast
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Anneau de validation
                    Opacity(
                      opacity: ringP,
                      child: Transform.scale(
                        scale: ringP,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF10B981), width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.check_circle_outline,
                                      size: 16, color: Color(0xFF10B981)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Audit Transparent',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                    Text('Chaque virement est visible',
                                        style: TextStyle(
                                            fontSize: 8, color: Color(0xFF94A3B8))),
                                  ],
                                ),
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
        ),
      ),
    );
  }

  List<Widget> _buildConfettis(double v) {
    final tp = _ep(v, _s3Confetti, _s3Confetti + 0.125);
    if (tp <= 0) return [];

    final colors = [
      const Color(0xFF1246C8),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    return _confettis.map((c) {
      final elapsed = tp - c.delay;
      if (elapsed <= 0) return const SizedBox.shrink();
      final prog = (elapsed * c.speed).clamp(0.0, 1.0);
      final y = prog * 400;
      final xDrift = math.sin(prog * math.pi * 5) * 35 + (c.x - 0.5) * 80;
      final op = (1 - prog).clamp(0.0, 0.9);
      final rot = prog * 5 * math.pi;

      return Positioned(
        left: 135 + xDrift,
        top: y,
        child: Opacity(
          opacity: op,
          child: Transform.rotate(
            angle: rot,
            child: Container(
              width: c.sizeW,
              height: c.sizeH,
              decoration: BoxDecoration(
                color: colors[c.colorIndex],
                borderRadius: c.isCircle
                    ? BorderRadius.circular(10)
                    : BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── SCENE 4 – BRAND ──────────────────────────────────────────────────────────
  Widget _buildScene4(double v) {
    final fadeIn = _ep(v, _s3End - _tr, _s3End);
    final op = fadeIn.clamp(0.0, 1.0);
    if (op <= 0) return const SizedBox.shrink();

    final scaleIn = 0.85 + 0.15 * fadeIn;
    final blur = (1.0 - fadeIn) * 6.0;

    final logoS = _cp(v, _s4Logo, _s4Logo + 0.058, Curves.easeOutBack);
    final titleP = _cp(v, _s4Title, _s4Title + 0.042, Curves.easeOutBack);
    final subP = _cp(v, _s4Sub, _s4Sub + 0.042, Curves.decelerate);
    final dotsP = _cp(v, _s4Dots, _s4Dots + 0.033, Curves.decelerate);
    final socialP = _cp(v, _s4Social, _s4Social + 0.042, Curves.easeOutBack);

    // Compteur social (0 → 2847)
    final socialCount = (_cp(v, _s4Social, _s4Social + 0.100, Curves.decelerate) * 2847).round();

    Widget content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a1f5c), Color(0xFF1246C8)],
        ),
      ),
      child: Stack(
        children: [
          // Étoiles scintillantes
          Positioned.fill(
            child: CustomPaint(
              painter: _StarsPainter(v: v, rng: _rng),
            ),
          ),
          // Contenu centré
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo glassmorphe
                Opacity(
                  opacity: logoS,
                  child: Transform.scale(
                    scale: logoS,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Text('K',
                                    style: GoogleFonts.syne(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    )),
                              ),
                          // Effet shine
                          Positioned(
                            left: -120,
                            top: -20,
                            child: IgnorePointer(
                              child: Container(
                                width: 100,
                                height: 60,
                                transform: Matrix4.skewX(-0.25),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Titre
                Opacity(
                  opacity: titleP,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - titleP)),
                    child: Text('Kased',
                        style: GoogleFonts.syne(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(height: 8),
                // Sous-titre
                Opacity(
                  opacity: subP,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - subP)),
                    child: const Text('SIMPLIFIEZ VOS COTISATIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                            color: Color(0xFF93C5FD))),
                  ),
                ),
                const SizedBox(height: 28),
                // Points indicateurs
                Opacity(
                  opacity: dotsP,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - dotsP)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 14, height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Preuve sociale
                Opacity(
                  opacity: socialP,
                  child: Transform.scale(
                    scale: socialP,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _smallAvatar(const Color(0xFFF43F5E)),
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  child: _smallAvatar(const Color(0xFFF59E0B)),
                                ),
                                Positioned(
                                  left: 16,
                                  top: 0,
                                  child: _smallAvatar(const Color(0xFF10B981)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                          Text(
                            '$socialCount',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          const Text(' communautés utilisent Kased',
                              style: TextStyle(
                                  fontSize: 7, color: Color(0xFFBFDBFE))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blur > 0.5) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return Opacity(
      opacity: op,
      child: Transform.scale(
        scale: scaleIn,
        child: content,
      ),
    );
  }

  Widget _smallAvatar(Color c) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 0),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }

  // ── OVERLAYS ─────────────────────────────────────────────────────────────────
  Widget _buildPhaseBadge(double v) {
    const phases = ['Problème', 'Solution', 'Transparence', 'Rejoignez-nous'];
    const dotColors = [
      Color(0xFFF43F5E), Color(0xFF10B981),
      Color(0xFF3B82F6), Color(0xFF818CF8),
    ];
    const textColors = [
      Color(0xFFFECDD3), Color(0xFFA7F3D0),
      Color(0xFFBFDBFE), Color(0xFFC7D2FE),
    ];

    // Détermine la transition entre phases à chaque frame à partir des seuils
    double crossFade = 1.0;
    int from = 0, to = 0;

    if (v < _s1End - _tr) {
      from = 0; to = 0;
    } else if (v < _s1End) {
      from = 0; to = 1;
      crossFade = _ep(v, _s1End - _tr, _s1End);
    } else if (v < _s2End - _tr) {
      from = 1; to = 1;
    } else if (v < _s2End) {
      from = 1; to = 2;
      crossFade = _ep(v, _s2End - _tr, _s2End);
    } else if (v < _s3End - _tr) {
      from = 2; to = 2;
    } else if (v < _s3End) {
      from = 2; to = 3;
      crossFade = _ep(v, _s3End - _tr, _s3End);
    } else {
      from = 3; to = 3;
    }

    final dotColor = Color.lerp(dotColors[from], dotColors[to], crossFade)!;
    final txtColor = Color.lerp(textColors[from], textColors[to], crossFade)!;

    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: v > 0.02 ? 1.0 : 0.0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dotColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: (1.0 - crossFade).clamp(0.0, 1.0),
                        child: Text(
                          phases[from],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: txtColor,
                          ),
                        ),
                      ),
                      if (from != to)
                        Opacity(
                          opacity: crossFade,
                          child: Text(
                            phases[to],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: txtColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(double v) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.1),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFF10B981), Color(0xFF6366F1)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CUSTOM PAINTERS ───────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  _DashedLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashW = 5.0;
    const gapW = 3.0;
    final totalW = size.width * progress;
    double x = 0;
    while (x < totalW) {
      final end = (x + dashW).clamp(0.0, totalW);
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.progress != progress || old.color != color;
}

class _NoisePainter extends CustomPainter {
  final int seed;
  _NoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    final rng = math.Random(seed);
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (rng.nextDouble() > 0.5) {
          canvas.drawCircle(Offset(x + rng.nextDouble() * step, y + rng.nextDouble() * step), 1, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.seed != seed;
}

class _ScribblePainter extends CustomPainter {
  static const _scribbles = [
    _Scribble(color: Color(0xFFEF4444), points: [
      Offset(85, 150), Offset(110, 135), Offset(150, 165), Offset(170, 140),
      Offset(190, 125), Offset(150, 110), Offset(130, 135),
    ]),
    _Scribble(color: Color(0xFFF59E0B), points: [
      Offset(220, 240), Offset(245, 260), Offset(210, 290), Offset(190, 265),
      Offset(170, 240), Offset(230, 225), Offset(250, 245),
    ]),
    _Scribble(color: Color(0xFFDC2626), points: [
      Offset(110, 315), Offset(130, 300), Offset(150, 335), Offset(130, 345),
      Offset(110, 355), Offset(90, 325), Offset(120, 310),
    ]),
  ];

  final double progress;
  const _ScribblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final s in _scribbles) {
      final path = Path();
      path.moveTo(s.points[0].dx, s.points[0].dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }

      final metrics = path.computeMetrics();
      double totalLength = 0;
      for (final m in metrics) totalLength += m.length;

      final drawLength = totalLength * progress.clamp(0.0, 1.0);
      final drawPath = Path();
      double accumulated = 0;
      for (final m in metrics) {
        if (accumulated + m.length <= drawLength) {
          drawPath.addPath(m.extractPath(0, m.length), Offset.zero);
        } else {
          drawPath.addPath(m.extractPath(0, drawLength - accumulated), Offset.zero);
          break;
        }
        accumulated += m.length;
      }

      canvas.drawPath(
        drawPath,
        Paint()
          ..color = s.color.withValues(alpha: progress)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => old.progress != progress;
}

class _PageScribblePainter extends CustomPainter {
  final double progress;
  final int seed;

  _PageScribblePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rng = math.Random(seed);

    // Traits de rature rouge/orange traversant la page
    final paint = Paint()
      ..color = Color.lerp(const Color(0xFFEF4444), const Color(0xFFF59E0B), rng.nextDouble())!
          .withValues(alpha: 0.6 * progress)
      ..strokeWidth = 1.5 + rng.nextDouble() * 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < (2 + (progress * 3).round()); i++) {
      final path = Path();
      final x = rng.nextDouble() * (size.width - 30) + 10;
      final y = rng.nextDouble() * (size.height - 30) + 10;
      path.moveTo(x - 20 * progress, y - 10 * progress);
      path.quadraticBezierTo(
        x + 10 * progress,
        y + 15 * progress,
        x + (20 + rng.nextDouble() * 20) * progress,
        y + (rng.nextDouble() * 15) * progress,
      );
      canvas.drawPath(path, paint);
    }

    // Tâches d'encre / déchirures visuelles
    final inkPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.08 * progress)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < (1 + (progress * 2).round()); i++) {
      final x = rng.nextDouble() * (size.width - 20) + 10;
      final y = rng.nextDouble() * (size.height - 20) + 10;
      canvas.drawCircle(Offset(x, y), 8 + rng.nextDouble() * 12, inkPaint);
    }

    // Marge rouge déchirée sur le côté gauche (comme un cahier abîmé)
    if (progress > 0.3) {
      final marginPaint = Paint()
        ..color = const Color(0xFFDC2626).withValues(alpha: 0.2 * progress)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final marginPath = Path();
      marginPath.moveTo(6, 0);
      marginPath.lineTo(6, size.height);
      canvas.drawPath(marginPath, marginPaint);
    }
  }

  @override
  bool shouldRepaint(_PageScribblePainter old) =>
      old.progress != progress || old.seed != seed;
}

class _StarsPainter extends CustomPainter {
  final double v;
  final math.Random rng;
  _StarsPainter({required this.v, required math.Random rng}) : rng = math.Random(42);

  static final List<_StarData> _stars = List.generate(10, (i) {
    final r = math.Random(42 + i);
    return _StarData(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 1.0 + r.nextDouble() * 1.5,
      phase: r.nextDouble() * 6.28,
      speed: 1.5 + r.nextDouble() * 1.5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in _stars) {
      final twinkle = 0.2 + 0.8 * (0.5 + 0.5 * math.sin(v * 2 * math.pi * s.speed + s.phase));
      paint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }

    // Étoiles filantes (2 au total)
    final shootingP = (_ep(v, 0.083, 0.167) * 2).floorToDouble();
    if (shootingP >= 0 && shootingP < 1) {
      final progress = _ep(v, 0.083, 0.167);
      final sx = 0.1 * size.width + progress * 220;
      final sy = 0.2 * size.height + progress * 220;

      paint.color = Colors.white;
      canvas.drawCircle(Offset(sx, sy), 2, paint);

      // Trail
      final trailPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(sx, sy),
          Offset(sx - 60, sy - 60),
          [Colors.white, Colors.white.withValues(alpha: 0)],
        )
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx - 60 * progress, sy - 60 * progress),
        trailPaint,
      );
    }

    final shootingP2 = (_ep(v, 0.100, 0.200) * 2).floorToDouble();
    if (shootingP2 >= 0 && shootingP2 < 1) {
      final progress = _ep(v, 0.100, 0.200);
      final sx = 0.6 * size.width + progress * 220;
      final sy = 0.35 * size.height + progress * 220;

      paint.color = Colors.white;
      canvas.drawCircle(Offset(sx, sy), 2, paint);

      final trailPaint2 = Paint()
        ..shader = ui.Gradient.linear(
          Offset(sx, sy),
          Offset(sx - 60, sy - 60),
          [Colors.white, Colors.white.withValues(alpha: 0)],
        )
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx - 60 * progress, sy - 60 * progress),
        trailPaint2,
      );
    }
  }

  double _ep(double p, double start, double end) {
    if (p <= start) return 0.0;
    if (p >= end) return 1.0;
    return (p - start) / (end - start);
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.v != v;
}

// ── DATA CLASSES ──────────────────────────────────────────────────────────────
class _Particle {
  final double angle;
  final double distance;
  final double delay;
  final double size;
  final int colorIndex;
  _Particle({
    required this.angle,
    required this.distance,
    required this.delay,
    required this.size,
    required this.colorIndex,
  });
}

class _Confetti {
  final double x;
  final double delay;
  final double speed;
  final double sizeW;
  final double sizeH;
  final int colorIndex;
  final bool isCircle;
  _Confetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sizeW,
    required this.sizeH,
    required this.colorIndex,
    required this.isCircle,
  });
}

class _Scribble {
  final Color color;
  final List<Offset> points;
  const _Scribble({required this.color, required this.points});
}

class _StarData {
  final double x, y, size, phase, speed;
  const _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
}
