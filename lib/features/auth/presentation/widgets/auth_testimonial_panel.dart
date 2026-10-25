import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';

class AuthTestimonialPanel extends StatelessWidget {
  const AuthTestimonialPanel({
    super.key,
    this.quote =
        '“TaleX transformed our selection process and helped our team make better decisions.”',
  });
  final String quote;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF071526),
    child: Stack(
      children: [
        const Positioned.fill(child: _BackgroundLines()),
        Padding(
          padding: const EdgeInsets.all(42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TalexLogo(width: 150, height: 70, forDarkBackground: true),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  quote,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BackgroundLines extends StatelessWidget {
  const _BackgroundLines();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _LinesPainter());
}

class _LinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x161D86C9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.25 + i * .13);
      canvas.drawPath(
        Path()
          ..moveTo(-40, y - 120)
          ..lineTo(size.width * .48, y)
          ..lineTo(size.width + 50, y - 170),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
