import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;

/// Utilidades puras de contraste de color conforme a WCAG 2.x.
///
/// Se usan a nivel de tema para garantizar que los pares texto/fondo de las
/// tarjetas de notificación cumplan la relación de contraste mínima exigida por
/// el Requirement 12.5 (≥ 4.5:1). No dependen de Flutter salvo por el tipo
/// [Color], de modo que pueden probarse con `flutter test` sin montar widgets.
class Contrast {
  const Contrast._();

  /// Luminancia relativa de un canal sRGB (0..255) según la fórmula de WCAG.
  static double _channelLuminance(int channel8bit) {
    final c = channel8bit / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Luminancia relativa de un color (0.0 = negro, 1.0 = blanco).
  ///
  /// Definida en https://www.w3.org/TR/WCAG21/#dfn-relative-luminance.
  static double relativeLuminance(Color color) {
    final r = _channelLuminance((color.r * 255.0).round() & 0xff);
    final g = _channelLuminance((color.g * 255.0).round() & 0xff);
    final b = _channelLuminance((color.b * 255.0).round() & 0xff);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Relación de contraste entre dos colores, en el rango 1.0..21.0.
  ///
  /// `(L1 + 0.05) / (L2 + 0.05)` donde `L1` es la luminancia más clara.
  /// El orden de los argumentos no altera el resultado.
  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// `true` si el par texto/fondo cumple el mínimo WCAG AA para texto normal
  /// (≥ 4.5:1), que es el umbral exigido por el Requirement 12.5.
  static bool meetsAA(Color foreground, Color background) =>
      ratio(foreground, background) >= 4.5;
}
