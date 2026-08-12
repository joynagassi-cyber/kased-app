import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/onboarding/collecte_hero.dart';
import '../widgets/onboarding/confetti_hero.dart';
import '../widgets/onboarding/suivi_hero.dart';
import '../widgets/spring_button.dart';
import '../core/preferences/app_prefs.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  late final AnimationController _celebrateCtrl;
  int _page = 0;
  bool _celebrating = false;

  static const _titles = [
    'Collectez en un geste',
    'Chaque cotisation est suivie',
    'Une transparence totale',
  ];

  static const _subtitles = [
    'Chaque piece que vous ajoutez remplit la cagnotte de votre communaute, en temps reel.',
    "Visualisez l evolution de vos cotisations mois par mois. Chaque barre raconte une histoire.",
    'Chaque virement est visible par tous. Celebrez et rejoignez la communaute Kased !',
  ];

  @override
  void initState() {
    super.initState();
    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _celebrateCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        AppPrefs.markOnboardingSeen();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go('/signup');
        });
      }
    });
  }

  @override
  void dispose() {
    _celebrateCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_celebrating || _page >= 2) return;
    HapticFeedback.lightImpact();
    _pageCtrl.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _celebrate() {
    if (_celebrating) return;
    HapticFeedback.mediumImpact();
    setState(() => _celebrating = true);
    _celebrateCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    isDark
                        ? colorScheme.primary.withValues(alpha: 0.18)
                        : colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120, right: -110,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colorScheme),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: _celebrating
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _KeepAlivePage(child: _PageTransition(child: _buildPage(0), index: 0, currentPage: _page)),
                      _KeepAlivePage(child: _PageTransition(child: _buildPage(1), index: 1, currentPage: _page)),
                      _KeepAlivePage(child: _PageTransition(child: _buildPage(2), index: 2, currentPage: _page)),
                    ],
                  ),
                ),
                _buildBottomBar(colorScheme),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _celebrateCtrl,
            builder: (context, _) {
              if (!_celebrating) return const SizedBox.shrink();
              final flash = (1 - _celebrateCtrl.value * 1.6).clamp(0.0, 0.9);
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.white.withValues(alpha: flash)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _celebrateCtrl,
            builder: (context, _) {
              if (!_celebrating) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(progress: _celebrateCtrl.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }  Widget _buildTopBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF2962FF), Color(0xFF7C4DFF)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text('K', style: GoogleFonts.syne(
                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white,
              )),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Passer', style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int i) {
    final Widget hero = switch (i) {
      0 => CollecteHero(active: _page == 0),
      1 => const SuiviHero(),
      _ => ConfettiHero(active: _page == 2, celebrating: _celebrating),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.contain, child: hero),
            ),
          ),
          Text(_titles[i], style: GoogleFonts.syne(
            fontSize: 22, fontWeight: FontWeight.w800,
            letterSpacing: -0.5, color: Theme.of(context).colorScheme.onSurface,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(_subtitles[i], style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    final isLast = _page == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final activeDot = i == _page;
              return GestureDetector(
                onTap: () {
                  if (_celebrating) return;
                  _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: activeDot ? 26 : 8, height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: activeDot ? const LinearGradient(colors: [Color(0xFF2962FF), Color(0xFF7C4DFF)]) : null,
                    color: activeDot ? null : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SpringButton(
            onTap: isLast ? _celebrate : _next,
            child: SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: Row(
                  mainAxisSize: MainAxisSize.min, children: [
                    Text(isLast ? 'Creer mon compte' : 'Continuer'),
                    const SizedBox(width: 8),
                    Icon(isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Jai deja un compte', style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary,
            )),
          ),
        ],
      ),
    );
  }
}
class _PageTransition extends StatelessWidget {
  final Widget child;
  final int index;
  final int currentPage;
  const _PageTransition({required this.child, required this.index, required this.currentPage});
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: index > currentPage ? const Offset(0.08, 0.0) : const Offset(-0.08, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(opacity: animation, child: SlideTransition(position: offsetAnimation, child: child));
      },
      child: child,
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}
class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) { super.build(context); return widget.child; }
}

class _ConfettiPiece {
  const _ConfettiPiece({required this.x, required this.delay, required this.speed,
    required this.size, required this.sway, required this.rotSpeed,
    required this.color, required this.isCircle});
  final double x, delay, speed, size, sway, rotSpeed;
  final Color color;
  final bool isCircle;
}
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;
  static const _colors = [Color(0xFF2962FF), Color(0xFF7C4DFF), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEC4899)];
  static final List<_ConfettiPiece> _pieces = _generate();
  static List<_ConfettiPiece> _generate() {
    final rng = math.Random(42);
    return List.generate(90, (i) => _ConfettiPiece(
      x: rng.nextDouble(), delay: rng.nextDouble() * 0.25,
      speed: 0.7 + rng.nextDouble() * 0.6, size: 5 + rng.nextDouble() * 6,
      sway: 18 + rng.nextDouble() * 26, rotSpeed: (rng.nextDouble() - 0.5) * 12,
      color: _colors[rng.nextInt(_colors.length)], isCircle: rng.nextDouble() > 0.55,
    ));
  }
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    for (final p in _pieces) {
      final e = ((progress - p.delay) * p.speed).clamp(0.0, 1.0);
      final t = Curves.easeOutCubic.transform(e);
      final y = -20 + (size.height + 60) * t;
      final x = p.x * size.width + math.sin(e * math.pi * 5) * p.sway;
      final opacity = (1 - e).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.95);
      canvas.save(); canvas.translate(x, y); canvas.rotate(p.rotSpeed * e * math.pi);
      if (p.isCircle) { canvas.drawCircle(Offset.zero, p.size / 2, paint); }
      else {
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(1.5)), paint);
      }
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}