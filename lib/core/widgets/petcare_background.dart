import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class PetCareBackground extends StatelessWidget {
  const PetCareBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: PetCareBackgroundPainter(),
      child: SizedBox.expand(),
    );
  }
}

class PetCareBackgroundPainter extends CustomPainter {
  const PetCareBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppTheme.secondary.withValues(alpha: 0.13);
    canvas.drawCircle(Offset(size.width - 12, 56), 72, paint);

    paint.color = AppTheme.secondary.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width - 62, 94), 42, paint);

    paint.color = AppTheme.primary.withValues(alpha: 0.055);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width + 10, size.height * 0.47),
        width: 180,
        height: 240,
      ),
      paint,
    );

    paint.color = AppTheme.secondary.withValues(alpha: 0.11);

    canvas.drawCircle(Offset(-18, size.height - 92), 92, paint);

    paint.color = AppTheme.primary.withValues(alpha: 0.045);

    canvas.drawCircle(Offset(46, size.height - 26), 54, paint);

    paint.color = AppTheme.deepBrown.withValues(alpha: 0.035);

    canvas.drawCircle(Offset(size.width - 34, size.height * 0.70), 20, paint);

    canvas.drawCircle(Offset(size.width - 78, size.height * 0.72), 11, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
