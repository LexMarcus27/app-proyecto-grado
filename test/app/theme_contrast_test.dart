import 'package:contigo/app/contrast.dart';
import 'package:contigo/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contrast utility (WCAG)', () {
    test('negro sobre blanco da el máximo 21:1', () {
      final r = Contrast.ratio(
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      );
      expect(r, closeTo(21.0, 0.01));
    });

    test('un color consigo mismo da 1:1', () {
      final r = Contrast.ratio(
        const Color(0xFF536B50),
        const Color(0xFF536B50),
      );
      expect(r, closeTo(1.0, 0.0001));
    });

    test('el orden de los argumentos no altera la relación', () {
      const a = Color(0xFF3A3238);
      const b = Color(0xFFE5EDE2);
      expect(Contrast.ratio(a, b), closeTo(Contrast.ratio(b, a), 1e-9));
    });

    test('meetsAA concuerda con el umbral 4.5:1', () {
      // Par cómodo (texto oscuro sobre fondo claro).
      expect(
        Contrast.meetsAA(const Color(0xFF3A3238), const Color(0xFFE5EDE2)),
        isTrue,
      );
      // Par insuficiente (gris medio sobre blanco ~ 2.8:1).
      expect(
        Contrast.meetsAA(const Color(0xFF999999), const Color(0xFFFFFFFF)),
        isFalse,
      );
    });
  });

  group('Tarjetas de notificación: contraste WCAG >= 4.5:1 (Req. 12.5)', () {
    final theme = ContigoTheme.light();
    final notif = theme.extension<ContigoNotificationTheme>();

    test('el tema expone la extensión de notificaciones', () {
      expect(notif, isNotNull);
      expect(notif!.all, hasLength(6));
    });

    test('cada par texto/fondo cumple >= 4.5:1', () {
      for (final palette in notif!.all) {
        final ratio = Contrast.ratio(palette.text, palette.background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'texto ${palette.text} sobre fondo ${palette.background} '
              'da ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('cada par acento/fondo (etiqueta de tipo) cumple >= 4.5:1', () {
      for (final palette in notif!.all) {
        final ratio = Contrast.ratio(palette.accent, palette.background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'acento ${palette.accent} sobre fondo ${palette.background} '
              'da ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });
  });
}
