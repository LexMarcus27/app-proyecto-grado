import 'package:flutter/material.dart';

import 'svg_path.dart';

/// Ilustraciones vectoriales de los inicios, portadas de `HomePlant`,
/// `HomeAvatar` (`src/screens/home.tsx`) y `Plant`
/// (`src/screens/caregiver-home.tsx`). Son decorativas (excluidas de la
/// semántica, como los `aria-hidden` del prototipo).

/// Un elemento de la ilustración: trazado SVG con relleno o trazo.
class _Shape {
  const _Shape.fill(this.d, this.color)
      : stroke = false,
        width = 0;
  const _Shape.stroke(this.d, this.color, this.width) : stroke = true;

  final String d;
  final Color color;
  final bool stroke;
  final double width;
}

class _Ellipse {
  const _Ellipse(this.cx, this.cy, this.rx, this.ry, this.color);
  final double cx, cy, rx, ry;
  final Color color;
}

class _ArtPainter extends CustomPainter {
  _ArtPainter({
    required this.viewBox,
    required this.ellipses,
    required this.shapes,
  });

  final Size viewBox;
  final List<_Ellipse> ellipses;
  final List<_Shape> shapes;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / viewBox.width) < (size.height / viewBox.height)
        ? size.width / viewBox.width
        : size.height / viewBox.height;
    canvas.save();
    canvas.translate(
      (size.width - viewBox.width * scale) / 2,
      (size.height - viewBox.height * scale) / 2,
    );
    canvas.scale(scale);
    for (final e in ellipses) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(e.cx, e.cy),
          width: e.rx * 2,
          height: e.ry * 2,
        ),
        Paint()..color = e.color,
      );
    }
    for (final s in shapes) {
      final path = _cache.putIfAbsent(s.d, () => parseSvgPath(s.d));
      final paint = Paint()..color = s.color;
      if (s.stroke) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width
          ..strokeCap = StrokeCap.round;
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) => false;
}

/// Planta decorativa del inicio del PCS (`.home-plant`, 146×137 aprox.).
class HomePlant extends StatelessWidget {
  const HomePlant({super.key, this.width = 146, this.height = 137});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _ArtPainter(
            viewBox: const Size(158, 148),
            ellipses: const [
              _Ellipse(48, 136, 41, 12, Color(0xFFEEE8DF)),
              _Ellipse(112, 137, 35, 14, Color(0xFFF1CDB5)),
              _Ellipse(91, 44, 28, 28, Color(0xFFF0B896)),
            ],
            shapes: const [
              _Shape.stroke('M110 139C107 103 107 72 92 47', Color(0xFF6D936D), 2.6),
              _Shape.stroke('M109 101C98 80 78 70 54 72', Color(0xFF6D936D), 2.4),
              _Shape.stroke('M109 82C113 52 126 36 136 20', Color(0xFF6D936D), 2.4),
              _Shape.fill('M55 72C42 57 31 55 14 57C24 69 39 73 55 72Z', Color(0xFF779A70)),
              _Shape.fill('M135 22C136 12 141 5 150 1C149 20 144 36 127 49C126 39 129 29 135 22Z', Color(0xFF72966D)),
              _Shape.fill('M94 49C86 38 82 35 75 31C78 47 86 60 101 67', Color(0xFFA9BC95)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Planta decorativa del inicio del cuidador (`.caregiver-plant`).
class CaregiverPlant extends StatelessWidget {
  const CaregiverPlant({super.key, this.width = 104, this.height = 112});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF7C9473);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _ArtPainter(
            viewBox: const Size(140, 135),
            ellipses: const [
              _Ellipse(57, 124, 42, 10, Color(0xFFEEE8DF)),
              _Ellipse(102, 125, 30, 11, Color(0xFFF1CDB5)),
              _Ellipse(78, 41, 26, 26, Color(0xFFF0B896)),
            ],
            shapes: const [
              _Shape.stroke(
                'M97 126C96 94 98 66 77 38M96 94C80 74 59 73 32 73M95 78C102 54 115 33 125 17',
                green,
                2.5,
              ),
              _Shape.fill(
                'M34 73C21 60 12 59 3 61C9 72 21 75 34 73ZM125 17C127 8 133 3 139 1C138 20 132 34 119 46C116 35 119 26 125 17ZM77 38C65 29 65 31 66 38C70 51 79 62 90 67',
                green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colores de los avatares del inicio (`avatarColors` del prototipo).
const List<(Color, Color)> homeAvatarColors = [
  (Color(0xFFF2DDD1), Color(0xFFD49A78)),
  (Color(0xFFE8E2F7), Color(0xFF9C8AD3)),
  (Color(0xFFE0EEE1), Color(0xFF8DAD83)),
  (Color(0xFFDFECF5), Color(0xFF80ACCB)),
];

/// Avatar ilustrado de una persona de la red (`HomeAvatar`).
class HomeAvatar extends StatelessWidget {
  const HomeAvatar({super.key, required this.index, this.size = 52});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = homeAvatarColors[index % homeAvatarColors.length];
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _AvatarPainter(colors.$1, colors.$2)),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.background, this.figure);

  final Color background;
  final Color figure;

  static final Path _body = parseSvgPath('M17 67C19 55 27 51 37 51S55 55 57 67');

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 74;
    canvas.save();
    canvas.scale(scale);
    canvas.drawCircle(const Offset(37, 37), 35, Paint()..color = background);
    canvas.drawCircle(
      const Offset(37, 37),
      35,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(const Offset(37, 39), 9, Paint()..color = figure);
    canvas.drawPath(_body, Paint()..color = figure);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.background != background || old.figure != figure;
}
