import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/journey/journey.dart';
import '../../domain/metrics/metrics.dart';

/// Gráficos del mapa de red (tarea 3.12) en `CustomPainter`, portados verbatim
/// de los SVG del prototipo (`ClosenessMap`, `QualityGrid`, `SvgNode`,
/// `Legend` en `src/screens/network.tsx`). Alimentados por
/// [NetworkMetricsCalculator.metricsFor]; conservan coordenadas, anillos,
/// sectores, formas y colores. Los cortes/colores son
/// Contenido_Validacion_Pendiente (ya registrados en el dominio de métricas).

// Colores locales del gráfico, verbatim del prototipo (objeto `C`). Son de uso
// exclusivo de estos lienzos (no forman parte de la paleta de marca del tema).
const Color _chartBorder = Color(0xFFDFD4C9);
const Color _chartSage = Color(0xFF7C9473);
const Color _chartMuted = Color(0xFF62575E);
const Color _chartHeading = Color(0xFF3A3238);
const Color _chartBlueSoft = Color(0xFFE9EEF5);
const Color _chartSuccessSoft = Color(0xFFE5EDE2);
const Color _chartNegQuadrant = Color(0xFFF6E8E5);
const Color _chartAmbivQuadrant = Color(0xFFF0EAF3);

double _clamp(double v, double min, double max) =>
    math.min(max, math.max(min, v));

/// Dibuja el marcador de un vínculo según su [NetworkShape] y color, verbatim de
/// `SvgNode`: círculo/diamante/triángulo/cuadrado con borde blanco de 2.5.
void _paintNode(
  Canvas canvas,
  double x,
  double y,
  double size,
  NetworkMetrics metrics,
) {
  final fill = Paint()
    ..color = Color(metrics.colorValue)
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  switch (metrics.shape) {
    case NetworkShape.diamond:
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(45 * math.pi / 180);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: size * 2,
        height: size * 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
      canvas.restore();
    case NetworkShape.triangle:
      final path = Path()
        ..moveTo(x, y - size - 2)
        ..lineTo(x + size + 2, y + size)
        ..lineTo(x - size - 2, y + size)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    case NetworkShape.square:
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: size * 2,
        height: size * 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
    case NetworkShape.circle:
      canvas.drawCircle(Offset(x, y), size, fill);
      canvas.drawCircle(Offset(x, y), size, stroke);
  }
}

TextPainter _label(String text, {double fontSize = 12, FontWeight weight = FontWeight.w700, Color color = _chartMuted}) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

void _paintText(
  Canvas canvas,
  String text,
  double x,
  double y, {
  double fontSize = 12,
  FontWeight weight = FontWeight.w700,
  Color color = _chartMuted,
  TextAlign anchor = TextAlign.start,
  bool haloed = false,
}) {
  final tp = _label(text, fontSize: fontSize, weight: weight, color: color);
  double dx = x;
  if (anchor == TextAlign.center) dx = x - tp.width / 2;
  if (anchor == TextAlign.end) dx = x - tp.width;
  // El baseline del SVG es `y`; el TextPainter dibuja desde arriba.
  final dy = y - tp.height;
  if (haloed) {
    final halo = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    halo.paint(canvas, Offset(dx, dy));
  }
  tp.paint(canvas, Offset(dx, dy));
}

/// Base de los lienzos del mapa con **posiciones de nodo** expuestas para el
/// hit-testing accesible: la capa de presentación traduce un toque a la persona
/// más cercana usando exactamente las mismas coordenadas que se dibujan.
abstract class NetworkChartPainter extends CustomPainter {
  NetworkChartPainter({required this.entries});

  /// Pares persona→métricas (solo personas evaluadas), en orden de entrada.
  final List<MapEntry<NetworkPerson, NetworkMetrics>> entries;

  /// Ancho del viewBox del prototipo (320 en ambos gráficos).
  static const double viewBox = 320;

  /// Posiciones de los nodos en coordenadas del viewBox (antes de escalar),
  /// en el mismo orden que [entries]. Deben coincidir con lo que pinta `paint`.
  List<Offset> nodePositions();
}
/// Mapa de cercanía: sectores por tipo de relación, anillos concéntricos y el
/// nodo "Yo" al centro. Portado verbatim de `ClosenessMap` (viewBox 320×330).
class ClosenessMapPainter extends NetworkChartPainter {
  ClosenessMapPainter({required super.entries});

  static const double _center = 160;

  static const Map<RelationshipType, double> _sectorAngles = {
    RelationshipType.familia: -135,
    RelationshipType.amistades: -45,
    RelationshipType.pareja: -90,
    RelationshipType.trabajoOEstudio: 45,
    RelationshipType.comunidadServicioOCredo: 135,
    RelationshipType.otro: 180,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 320;
    canvas.scale(scale);

    final borderPaint = Paint()
      ..color = _chartBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Marco redondeado.
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 7, 306, 306),
      const Radius.circular(20),
    );
    canvas.drawRRect(frame, Paint()..color = Colors.white);
    canvas.drawRRect(frame, borderPaint);

    // Ejes punteados.
    _dashedLine(canvas, const Offset(160, 24), const Offset(160, 296), borderPaint);
    _dashedLine(canvas, const Offset(24, 160), const Offset(296, 160), borderPaint);

    // Anillos concéntricos (42, 77, 112); el exterior en salvia.
    const radii = [42.0, 77.0, 112.0];
    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(
        const Offset(_center, _center),
        radii[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = i == 2 ? _chartSage : _chartBorder,
      );
    }

    // Etiquetas de sector.
    _paintText(canvas, 'Familia', 52, 35, color: _chartMuted);
    _paintText(canvas, 'Amistades', 268, 35, color: _chartMuted, anchor: TextAlign.end);
    _paintText(canvas, 'Pareja', 160, 35, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'Trabajo / estudio', 283, 293, color: _chartMuted, anchor: TextAlign.end);
    _paintText(canvas, 'Comunidad', 37, 293, color: _chartMuted);

    // Nodo central "Yo".
    canvas.drawCircle(const Offset(_center, _center), 22, Paint()..color = _chartHeading);
    _paintText(canvas, 'Yo', _center, _center + 4 + 9,
        color: Colors.white, anchor: TextAlign.center, fontSize: 12, weight: FontWeight.w800);

    for (var index = 0; index < entries.length; index++) {
      final person = entries[index].key;
      final metrics = entries[index].value;
      final base = _sectorAngles[person.relationshipType ?? RelationshipType.otro]!;
      final angle = (base + ((index % 3) - 1) * 11) * math.pi / 180;
      final radius = 34 + (1 - metrics.finalCloseness) * 78;
      final x = _clamp(_center + math.cos(angle) * radius, 34, 286);
      final yMin = person.relationshipType == RelationshipType.pareja ? 72.0 : 39.0;
      final y = _clamp(_center + math.sin(angle) * radius, yMin, 281);
      final nodeSize = 8 + metrics.importance * 5;
      final labelY = person.relationshipType == RelationshipType.pareja && y < 85
          ? y + nodeSize + 16
          : y < 54
              ? y + 24
              : y > 268
                  ? y - 18
                  : y - nodeSize - 7;
      final labelX = _clamp(x, 40, 280);
      final anchor = x < 65 ? TextAlign.start : x > 255 ? TextAlign.end : TextAlign.center;

      _paintNode(canvas, x, y, nodeSize, metrics);
      final name = person.name.length > 10 ? '${person.name.substring(0, 9)}…' : person.name;
      _paintText(canvas, name, labelX, _clamp(labelY, 28, 294) + 12,
          color: _chartHeading, anchor: anchor, haloed: true);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final start = a + dir * d;
      final end = a + dir * math.min(d + dash, total);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  @override
  List<Offset> nodePositions() {
    final result = <Offset>[];
    for (var index = 0; index < entries.length; index++) {
      final person = entries[index].key;
      final metrics = entries[index].value;
      final base = _sectorAngles[person.relationshipType ?? RelationshipType.otro]!;
      final angle = (base + ((index % 3) - 1) * 11) * math.pi / 180;
      final radius = 34 + (1 - metrics.finalCloseness) * 78;
      final x = _clamp(_center + math.cos(angle) * radius, 34, 286);
      final yMin = person.relationshipType == RelationshipType.pareja ? 72.0 : 39.0;
      final y = _clamp(_center + math.sin(angle) * radius, yMin, 281);
      result.add(Offset(x, y));
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant ClosenessMapPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

/// Cuadrícula de positividad/negatividad. Portado verbatim de `QualityGrid`
/// (viewBox 320×360) con la misma separación de marcadores solapados.
class QualityGridPainter extends NetworkChartPainter {
  QualityGridPainter({required super.entries});

  static const double _plotX = 50;
  static const double _plotY = 72;
  static const double _plotW = 238;
  static const double _plotH = 184;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 320;
    canvas.scale(scale);

    final borderPaint = Paint()
      ..color = _chartBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 7, 306, 346),
      const Radius.circular(20),
    );
    canvas.drawRRect(frame, Paint()..color = Colors.white);
    canvas.drawRRect(frame, borderPaint);

    // Cuadrantes (negativa / ambivalente / baja intensidad / positiva).
    canvas.drawRect(
        Rect.fromLTWH(_plotX, _plotY, _plotW / 2, _plotH / 2),
        Paint()..color = _chartNegQuadrant);
    canvas.drawRect(
        Rect.fromLTWH(_plotX + _plotW / 2, _plotY, _plotW / 2, _plotH / 2),
        Paint()..color = _chartAmbivQuadrant);
    canvas.drawRect(
        Rect.fromLTWH(_plotX, _plotY + _plotH / 2, _plotW / 2, _plotH / 2),
        Paint()..color = _chartBlueSoft);
    canvas.drawRect(
        Rect.fromLTWH(_plotX + _plotW / 2, _plotY + _plotH / 2, _plotW / 2, _plotH / 2),
        Paint()..color = _chartSuccessSoft);

    // Borde del área en salvia y ejes punteados centrales.
    canvas.drawRect(
        const Rect.fromLTWH(_plotX, _plotY, _plotW, _plotH),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _chartSage);
    _dashed(canvas, Offset(_plotX + _plotW / 2, _plotY),
        Offset(_plotX + _plotW / 2, _plotY + _plotH), borderPaint);
    _dashed(canvas, Offset(_plotX, _plotY + _plotH / 2),
        Offset(_plotX + _plotW, _plotY + _plotH / 2), borderPaint);

    // Etiquetas de cuadrante y ejes.
    _paintText(canvas, 'Mayormente', 109.5, 28, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'negativa', 109.5, 45, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'Ambivalente', 228.5, 36, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'Baja intensidad', 109.5, 294, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'Mayormente', 228.5, 287, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'positiva', 228.5, 304, fontSize: 14, color: _chartMuted, anchor: TextAlign.center);
    _paintText(canvas, 'Positividad', 169, 343, color: _chartHeading, anchor: TextAlign.center);
    _paintText(canvas, 'Baja', 50, 273, color: _chartMuted);
    _paintText(canvas, 'Alta', 288, 273, color: _chartMuted, anchor: TextAlign.end);
    _paintText(canvas, 'Alta', 42, 78, color: _chartMuted, anchor: TextAlign.end);
    _paintText(canvas, 'Baja', 42, 256, color: _chartMuted, anchor: TextAlign.end);
    // "Negatividad" rotada -90.
    canvas.save();
    canvas.translate(16, 154);
    canvas.rotate(-90 * math.pi / 180);
    _paintText(canvas, 'Negatividad', 0, 4, color: _chartHeading, anchor: TextAlign.center);
    canvas.restore();

    final placed = <Offset>[];
    for (var index = 0; index < entries.length; index++) {
      final person = entries[index].key;
      final metrics = entries[index].value;
      var x = _clamp(_plotX + metrics.positivity * _plotW, _plotX + 12, _plotX + _plotW - 12);
      var y = _clamp(_plotY + (1 - metrics.negativity) * _plotH, _plotY + 12, _plotY + _plotH - 12);
      for (final prev in placed) {
        if ((prev.dx - x).abs() < 22 && (prev.dy - y).abs() < 22) {
          x = _clamp(x + (index % 2 == 0 ? 18 : -18), _plotX + 12, _plotX + _plotW - 12);
          y = _clamp(y + 17, _plotY + 12, _plotY + _plotH - 12);
        }
      }
      placed.add(Offset(x, y));
      final nodeSize = 8 + metrics.importance * 5;
      final useBelow = y < _plotY + 30;
      final labelY = _clamp(useBelow ? y + nodeSize + 16 : y - nodeSize - 7,
          _plotY + 14, _plotY + _plotH - 8);
      final anchor = x < _plotX + 38
          ? TextAlign.start
          : x > _plotX + _plotW - 38
              ? TextAlign.end
              : TextAlign.center;
      final labelX = _clamp(x, _plotX + 4, _plotX + _plotW - 4);

      // Conector tenue nodo→etiqueta.
      canvas.drawLine(
        Offset(x, y),
        Offset(labelX, labelY),
        Paint()
          ..color = _chartMuted.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      _paintNode(canvas, x, y, nodeSize, metrics);
      final name = person.name.length > 10 ? '${person.name.substring(0, 9)}…' : person.name;
      _paintText(canvas, name, labelX, labelY + 12, color: _chartHeading, anchor: anchor, haloed: true);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  @override
  List<Offset> nodePositions() {
    final placed = <Offset>[];
    for (var index = 0; index < entries.length; index++) {
      final metrics = entries[index].value;
      var x = _clamp(_plotX + metrics.positivity * _plotW, _plotX + 12, _plotX + _plotW - 12);
      var y = _clamp(_plotY + (1 - metrics.negativity) * _plotH, _plotY + 12, _plotY + _plotH - 12);
      for (final prev in placed) {
        if ((prev.dx - x).abs() < 22 && (prev.dy - y).abs() < 22) {
          x = _clamp(x + (index % 2 == 0 ? 18 : -18), _plotX + 12, _plotX + _plotW - 12);
          y = _clamp(y + 17, _plotY + 12, _plotY + _plotH - 12);
        }
      }
      placed.add(Offset(x, y));
    }
    return placed;
  }

  @override
  bool shouldRepaint(covariant QualityGridPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

/// Un marcador pequeño de leyenda (forma + color de una clasificación).
class LegendMarker extends StatelessWidget {
  const LegendMarker({super.key, required this.metrics, this.size = 19});

  final NetworkMetrics metrics;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LegendMarkerPainter(metrics),
    );
  }
}

class _LegendMarkerPainter extends CustomPainter {
  _LegendMarkerPainter(this.metrics);
  final NetworkMetrics metrics;

  @override
  void paint(Canvas canvas, Size size) {
    _paintNode(canvas, size.width / 2, size.height / 2, size.width * 5 / 19, metrics);
  }

  @override
  bool shouldRepaint(covariant _LegendMarkerPainter oldDelegate) =>
      oldDelegate.metrics != metrics;
}