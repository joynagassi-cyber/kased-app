import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kased_app/core/theme/app_theme.dart';

/// Page 1: Collecte en un geste
/// Illustration vectorielle statique style Google - piggy bank géométrique
class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    
    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: 40,
            left: 40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
          ),
          // Main illustration - Geometric Piggy Bank
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Piggy bank body (rounded rectangle)
                Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        const Color(0xFF1E40AF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Coin slot
                      Positioned(
                        top: 8,
                        left: 50,
                        child: Container(
                          width: 60,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Eye
                      Positioned(
                        top: 35,
                        right: 30,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Snout
                      Positioned(
                        bottom: 20,
                        right: 15,
                        child: Container(
                          width: 40,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryMid,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Legs
                      Positioned(
                        bottom: 0,
                        left: 25,
                        child: Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 25,
                        child: Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Floating coins
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Coin(size: 32, offset: const Offset(-60, -20)),
                    _Coin(size: 28, offset: const Offset(0, -30)),
                    _Coin(size: 32, offset: const Offset(60, -20)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  final double size;
  final Offset offset;
  
  const _Coin({required this.size, required this.offset});
  
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
          border: Border.all(
            color: const Color(0xFFD97706),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB45309).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '₣',
            style: GoogleFonts.syne(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
      ),
    );
  }
}
