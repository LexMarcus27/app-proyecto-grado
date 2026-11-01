import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Barra de estado móvil equivalente a `StatusBar` del prototipo (`ui.tsx`).
///
/// Replica la maqueta del prototipo: una barra de 47px de alto con la hora a la
/// izquierda y los glifos de señal y batería a la derecha, pintados con el color
/// de tinta del tema ([ContigoColors.ink]). Es puramente presentacional (parte
/// del "chrome" del dispositivo simulado) y no consume colores literales.
///
/// Es decorativa: se marca con [ExcludeSemantics] para no introducir ruido en
/// los lectores de pantalla, igual que los glifos `aria-hidden` del prototipo.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, this.time = '9:41', this.showOnNative = false});

  /// Hora mostrada a la izquierda. El prototipo usa el valor fijo `9:41`.
  final String time;

  /// Si es `true`, dibuja la maqueta también en dispositivos nativos. Por
  /// defecto es `false`: en la app nativa (Android/iOS) la maqueta `9:41`
  /// **no** se dibuja y se usa la barra de estado real del sistema (hallazgo
  /// E2-04); solo se muestra en web/escritorio y en pruebas, donde no hay una
  /// barra del sistema que duplicar. Los flujos de pantalla la usan con el valor
  /// por defecto; una pantalla de desarrollo puede forzarla con `showOnNative`.
  final bool showOnNative;

  /// `true` en plataformas móviles nativas (Android/iOS), donde ya existe la
  /// barra de estado del sistema.
  static bool get _isNativeMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    // En móvil nativo se evita duplicar la barra del sistema: no se dibuja la
    // maqueta `9:41` (E2-04). SafeArea, aportado por las pantallas, sigue
    // protegiendo el contenido bajo la barra real.
    if (_isNativeMobile && !showOnNative) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: 47,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ContigoColors.ink,
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SignalGlyph(),
                  SizedBox(width: 6),
                  _BatteryGlyph(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glifo de intensidad de señal (cuatro barras ascendentes), portado del SVG del
/// prototipo. La última barra queda tenue, igual que el `opacity 0.3` original.
class _SignalGlyph extends StatelessWidget {
  const _SignalGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 12,
      child: CustomPaint(painter: _SignalPainter(ContigoColors.ink)),
    );
  }
}

class _SignalPainter extends CustomPainter {
  const _SignalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // viewBox 0 0 16 12 → el widget mide 16x12, no requiere escala.
    void bar(double x, double y, double w, double h, double opacity) {
      paint.color = color.withValues(alpha: opacity);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(0.5),
      );
      canvas.drawRRect(rrect, paint);
    }

    bar(0, 6, 3, 6, 1);
    bar(4.5, 4, 3, 8, 1);
    bar(9, 2, 3, 10, 1);
    bar(13.5, 0, 2.5, 12, 0.3);
  }

  @override
  bool shouldRepaint(_SignalPainter oldDelegate) => oldDelegate.color != color;
}

/// Glifo de batería portado del SVG del prototipo: un contorno redondeado con el
/// borne a la derecha y el nivel de carga relleno.
class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 12,
      child: CustomPaint(painter: _BatteryPainter(ContigoColors.ink)),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 24 12 escalado al ancho real (16px).
    final scale = size.width / 24.0;
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = color;

    // Contorno.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 1, 22, 10),
        const Radius.circular(2),
      ),
      stroke,
    );
    // Borne.
    fill.color = color.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 4, 2, 4),
        const Radius.circular(1),
      ),
      fill,
    );
    // Nivel de carga.
    fill.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.5, 2.5, 16, 7),
        const Radius.circular(1),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_BatteryPainter oldDelegate) => oldDelegate.color != color;
}

