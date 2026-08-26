import 'package:flutter/material.dart';

class HeaderStatWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const HeaderStatWidget({
    super.key,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => child,
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isAlert
                  ? Colors.orangeAccent
                  : Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
