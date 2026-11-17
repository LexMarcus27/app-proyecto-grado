import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Marca «Contigo» (equivalente a `ContigoLogo` del prototipo, propuesta M1):
/// trazo terracota en forma de hilo con un arco punteado y el nombre en serif.
class ContigoLogo extends StatelessWidget {
  const ContigoLogo({super.key, this.size = 46});

  /// Tamaño del texto; el trazo se escala en proporción.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Contigo',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size * 1.55,
            height: size * 1.25,
            child: const CustomPaint(painter: _MarkPainter()),
          ),
          SizedBox(width: size * 0.28),
          Text(
            'Contigo',
            style: TextStyle(
              fontFamily: ContigoTheme.displayFontFamily,
              fontFamilyFallback: ContigoTheme.displayFontFallback,
              fontSize: size,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: const Color(0xFF242126),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = ContigoColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hilo: sube en curva, hace un pequeño lazo y vuelve a subir.
    final thread = Path()
      ..moveTo(w * 0.06, h * 0.62)
      ..cubicTo(w * 0.04, h * 0.28, w * 0.3, h * 0.14, w * 0.36, h * 0.36)
      ..cubicTo(w * 0.4, h * 0.52, w * 0.28, h * 0.56, w * 0.3, h * 0.42)
      ..cubicTo(w * 0.34, h * 0.24, w * 0.46, h * 0.62, w * 0.56, h * 0.6)
      ..cubicTo(w * 0.7, h * 0.58, w * 0.78, h * 0.3, w * 0.92, h * 0.1);
    canvas.drawPath(thread, stroke);

    // Arco punteado bajo el trazo.
    final arc = Path()
      ..moveTo(w * 0.02, h * 0.82)
      ..quadraticBezierTo(w * 0.36, h * 1.02, w * 0.7, h * 0.82);
    final dots = Paint()
      ..color = const Color(0xFFE6B79A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    for (final metric in arc.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += w * 0.09) {
        canvas.drawPath(metric.extractPath(d, d + 0.1), dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => false;
}
