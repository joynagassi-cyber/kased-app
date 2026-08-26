import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class KasedStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;
  final double? fontSize;

  const KasedStatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.fontSize,
  });

  factory KasedStatusBadge.success(String text) {
    return KasedStatusBadge(
      text: text,
      color: const Color(0xFF00C853),
      backgroundColor: const Color(0xFFE8F5E9),
    );
  }

  factory KasedStatusBadge.danger(String text) {
    return KasedStatusBadge(
      text: text,
      color: const Color(0xFFFF1744),
      backgroundColor: const Color(0xFFFFEBEE),
    );
  }

  factory KasedStatusBadge.warning(String text) {
    return KasedStatusBadge(
      text: text,
      color: const Color(0xFFFF9100),
      backgroundColor: const Color(0xFFFFF3E0),
    );
  }

  factory KasedStatusBadge.info(String text) {
    return KasedStatusBadge(
      text: text,
      color: const Color(0xFF2962FF),
      backgroundColor: const Color(0xFFE3F2FD),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 2.ms,
      color: color.withValues(alpha: 0.1),
    );
  }
}
