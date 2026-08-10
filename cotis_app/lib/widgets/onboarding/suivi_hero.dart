import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page 2 du micro-onboarding — « Chaque cotisation est suivie ».
///
/// Action unique : taper chaque barre du graphique pour la « valider ».
/// La barre pousse jusqu'à sa valeur avec un ressort, une bulle affiche le
/// montant, un check apparaît, et quand les 6 mois sont validés une bannière
/// de succès apparaît.
class SuiviHero extends StatefulWidget {
  const SuiviHero({super.key});

  @override
  State<SuiviHero> createState() => _SuiviHeroState();
}

class _SuiviHeroState extends State<SuiviHero> {
  static const _months = <(String, double)>[
    ('Jan', 15),
    ('Fév', 22),
    ('Mar', 12),
    ('Avr', 38),
    ('Mai', 28),
    ('Juin', 45),
  ];
  static const _maxVal = 45.0;

  final Set<int> _validated = {};

  void _tapBar(int i) {
    if (_validated.contains(i)) return;
    HapticFeedback.lightImpact();
    setState(() => _validated.add(i));
    if (_validated.length == _months.length) {
      HapticFeedback.mediumImpact();
    }
  }

  double _barHeight(int i) => (_months[i].$2 / _maxVal) * 96;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allValidated = _validated.length == _months.length;

    return SizedBox(
      width: 316,
      height: 296,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(scheme, allValidated),
              const SizedBox(height: 10),
              _buildProgress(scheme, allValidated),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    // Ligne médiane pointillée
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 62,
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashedLinePainter(
                          color: scheme.outlineVariant,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < _months.length; i++)
                          Expanded(child: _buildBar(i, scheme)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: allValidated
                        ? Container(
                            key: const ValueKey('done'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF059669),
                                  Color(0xFF10B981),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 15, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Toutes les cotisations sont suivies !',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('pending')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, bool allValidated) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cotisations 2025',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              allValidated ? 'Tout est validé ✓' : 'Tapez chaque barre',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                '+12%',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(ColorScheme scheme, bool allValidated) {
    final fraction = _validated.length / _months.length;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded,
            size: 15,
            color: allValidated
                ? const Color(0xFF10B981)
                : scheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(
          '${_validated.length}/${_months.length} mois validés',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, f, _) => FractionallySizedBox(
                  widthFactor: f.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF10B981)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(int i, ColorScheme scheme) {
    final validated = _validated.contains(i);
    final month = _months[i];
    final height = _barHeight(i);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapBar(i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bulle de valeur
          SizedBox(
            height: 24,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: validated
                    ? Container(
                        key: ValueKey('v$i'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.onSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${month.$2.toInt()}K F',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: scheme.surface,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          // Barre
          SizedBox(
            height: 100,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('bar$i'),
                tween: Tween(begin: 0, end: validated ? height : 14),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, h, _) {
                  return Container(
                    width: 26,
                    height: h.clamp(0.0, 100.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                      gradient: validated
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2962FF), Color(0xFF7C4DFF)],
                            )
                          : null,
                      color: validated
                          ? null
                          : scheme.outlineVariant.withValues(alpha: 0.45),
                      boxShadow: validated
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2962FF)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: validated
                        ? const Center(
                            child: Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            month.$1,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: validated ? FontWeight.w800 : FontWeight.w600,
              color: validated ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    const dashW = 5.0;
    const gapW = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
