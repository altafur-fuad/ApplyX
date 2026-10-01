
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Organic wave background painter
/// Matches design.md "10. Organic shape system"
class OrganicBackground extends StatelessWidget {
  const OrganicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OrganicPainter(
              colors: [
                AppColors.surfaceElevated,
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.aiAccent.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _OrganicPainter extends CustomPainter {
  final List<Color> colors;

  _OrganicPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top right wave
    final path1 = Path();
    path1.moveTo(size.width * 0.3, 0);
    path1.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.1,
      size.width,
      size.height * 0.4,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors[1], colors[2]],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path1, paint);

    // Bottom left wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.8,
      size.height,
    );
    path2.lineTo(0, size.height);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      colors: [colors[1], colors[0]],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
