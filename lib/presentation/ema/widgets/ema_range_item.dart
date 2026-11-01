import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import 'ema_style.dart';

/// Textos del control de rango, portados verbatim del prototipo (`ema.tsx`).
class _EmaRangeText {
  const _EmaRangeText._();

  /// Etiqueta del extremo izquierdo (valor 0).
  static const String endpointLow = 'Nada cierta';

  /// Etiqueta del extremo derecho (valor 100).
  static const String endpointHigh = 'Completamente cierta';

  /// Valor accesible cuando aún no se ha respondido.
  static const String unansweredValue = 'Sin responder';

  /// Leyenda semántica del fieldset (`<legend className="sr-only">`).
  static const String semanticLabel = 'Indica qué tan cierta es esta frase';

  /// Ayuda visible cuando el ítem está sin responder.
  static const String helpUnanswered = 'Toca o mueve la barra para responder.';

  /// Ayuda visible una vez respondido.
  static const String helpAnswered =
      'Puedes ajustar tu respuesta antes de continuar.';

  /// Pista solo para lector de pantalla sobre el manejo con teclado.
  static const String keyboardHint =
      'Con teclado, usa las flechas para ajustar, Inicio para Nada cierta y '
      'Fin para Completamente cierta.';
}

/// Ítem de rango continuo del EMA (`daily-nine-v2`), portado del componente
/// `EmaRange` del prototipo (`src/screens/ema.tsx`).
///
/// Comportamiento y accesibilidad (Requirements 5.3 y 5.4):
///
/// - Barra **continua** con etiquetas únicamente en los extremos
///   ("Nada cierta" a la izquierda, "Completamente cierta" a la derecha).
///   **Nunca** se muestra un número de forma visible.
/// - **Sin preselección**: [value] `null` representa el estado *sin responder*
///   y la barra se pinta como pista plana (sin relleno). El rango interno es
///   `0..100` (entero).
/// - **Primera interacción asigna valor**: estando sin responder, un toque mapea
///   la posición `x` a `0..100` (redondeado y recortado) y una acción de teclado
///   asigna el valor inicial equivalente al prototipo (flecha izquierda/abajo →
///   49, derecha/arriba → 51, Inicio → 0, Fin → 100, RePág → 60, AvPág → 40,
///   Enter/Espacio → 50). Una vez respondido, las flechas ajustan ±1, Inicio/Fin
///   ponen 0/100 y RePág/AvPág ±10.
/// - **Accesibilidad nativa**: el control se envuelve en un [Semantics] marcado
///   como *slider* que expone el valor a las tecnologías de asistencia con un
///   texto hablado ("Sin responder" si es `null`, "Nada cierta" en 0,
///   "Completamente cierta" en 100, o "`v` de 100" en otro caso) **sin**
///   renderizarlo visiblemente, y ofrece acciones de incremento/decremento.
///
/// API: `EmaRangeItem({required int? value, required ValueChanged<int> onChanged})`.
class EmaRangeItem extends StatefulWidget {
  const EmaRangeItem({super.key, required this.value, required this.onChanged});

  /// Valor actual del ítem en `0..100`, o `null` si está sin responder.
  final int? value;

  /// Notifica el nuevo valor (`0..100`) tras cada interacción.
  final ValueChanged<int> onChanged;

  @override
  State<EmaRangeItem> createState() => _EmaRangeItemState();
}

class _EmaRangeItemState extends State<EmaRangeItem> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'EmaRangeItem');

  /// Alto táctil de la barra (zona de gesto). El relleno visual es más delgado;
  /// debe dejar espacio al indicador de 36px (`.ema-continuous-card input`).
  static const double _barHeight = 48;

  bool get _unanswered => widget.value == null;

  int _clamp(int v) => v < 0 ? 0 : (v > 100 ? 100 : v);

  void _emit(int v) => widget.onChanged(_clamp(v));

  /// Mapea la posición [dx] (relativa al inicio de la barra) a `0..100`.
  void _handleTapAt(double dx, double width) {
    if (width <= 0) {
      _emit(0);
      return;
    }
    final ratio = (dx / width).clamp(0.0, 1.0);
    _emit((ratio * 100).round());
  }

  /// Texto hablado de un valor concreto, nunca renderizado visiblemente.
  String _spoken(int? v) {
    if (v == null) return _EmaRangeText.unansweredValue;
    if (v <= 0) return _EmaRangeText.endpointLow;
    if (v >= 100) return _EmaRangeText.endpointHigh;
    return '$v de 100';
  }

  /// Valor accesible actual.
  String get _semanticsValue => _spoken(widget.value);

  /// Valor accesible tras un incremento (para `Semantics.increasedValue`).
  String get _increasedValue =>
      _spoken(_unanswered ? 51 : _clamp(widget.value! + 1));

  /// Valor accesible tras un decremento (para `Semantics.decreasedValue`).
  String get _decreasedValue =>
      _spoken(_unanswered ? 49 : _clamp(widget.value! - 1));

  void _onIncrease() {
    if (_unanswered) {
      _emit(51);
    } else {
      _emit(widget.value! + 1);
    }
  }

  void _onDecrease() {
    if (_unanswered) {
      _emit(49);
    } else {
      _emit(widget.value! - 1);
    }
  }

  /// Manejo de teclado equivalente al `onKeyDown` del prototipo.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (_unanswered) {
      // Primera interacción: asigna el valor inicial del prototipo
      // (flechas ±1 alrededor de 50, extremos, páginas y Enter/Espacio → 50).
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowDown) {
        _emit(49);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.arrowUp) {
        _emit(51);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.home) {
        _emit(0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.end) {
        _emit(100);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.pageDown) {
        _emit(40);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.pageUp) {
        _emit(60);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        _emit(50);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Ya respondido: ajuste libre.
    final v = widget.value!;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _emit(v - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _emit(v + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _emit(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _emit(100);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _emit(v + 10);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _emit(v - 10);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helpStyle = theme.textTheme.bodySmall?.copyWith(
      color: ContigoColors.inkMuted,
    );
    // Extremos "Nada cierta"/"Completamente cierta" en el gris del prototipo
    // (`.ema-thread-endpoints { color: #52555D }`).
    final endpointStyle = theme.textTheme.labelMedium?.copyWith(
      color: EmaStyle.muted,
    );

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _focusNode.requestFocus();
            _handleTapAt(details.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (details) {
            _focusNode.requestFocus();
            _handleTapAt(details.localPosition.dx, width);
          },
          child: SizedBox(
            height: _barHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _EmaRangeBarPainter(
                // Sin responder → pista plana (fillRatio nulo).
                fillRatio: _unanswered ? null : widget.value! / 100,
              ),
            ),
          ),
        );
      },
    );

    return Semantics(
      container: true,
      slider: true,
      label: _EmaRangeText.semanticLabel,
      value: _semanticsValue,
      increasedValue: _increasedValue,
      decreasedValue: _decreasedValue,
      hint: _EmaRangeText.keyboardHint,
      onIncrease: _onIncrease,
      onDecrease: _onDecrease,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tarjeta blanca de la escala (`.ema-continuous-card`): radio 23,
            // relleno ~16px, con la barra y los extremos dentro.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: ContigoColors.surface,
                borderRadius: BorderRadius.circular(EmaStyle.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // La etiqueta/leyenda y la pista de teclado solo para lector;
                  // el valor numérico nunca se expone visualmente.
                  bar,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          _EmaRangeText.endpointLow,
                          style: endpointStyle,
                        ),
                      ),
                      ExcludeSemantics(
                        child: Text(
                          _EmaRangeText.endpointHigh,
                          style: endpointStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Text(
                _unanswered
                    ? _EmaRangeText.helpUnanswered
                    : _EmaRangeText.helpAnswered,
                style: helpStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta la barra de rango EMA, fiel al prototipo (`.ema-continuous-card`):
///
/// - Pista de 6px en `#D0E3EE` (`EmaStyle.track`) y, si [fillRatio] no es nulo,
///   el tramo respondido en azul `#3174A1` (`EmaStyle.blue`).
/// - **Indicador (thumb)**: oculto mientras está sin responder
///   (`.is-unanswered ... thumb { opacity: 0 }`); tras responder, un círculo
///   blanco de 36px con borde azul de 9px centrado en la posición del valor
///   (`::-*-thumb { width/height: 36px; border: 9px solid #3174A1 }`). El centro
///   del indicador se mantiene dentro del ancho útil (reservando el radio del
///   indicador en cada extremo), replicando el `background-size: calc(100% -
///   36px)` del prototipo.
class _EmaRangeBarPainter extends CustomPainter {
  _EmaRangeBarPainter({required this.fillRatio});

  /// Proporción `0..1` del relleno, o `null` cuando está sin responder.
  final double? fillRatio;

  /// Grosor de la pista (6px, como `background-size: ... 6px` del prototipo).
  static const double _thickness = EmaStyle.trackThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final radius = Radius.circular(_thickness / 2);

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, midY - _thickness / 2, size.width, _thickness),
      radius,
    );
    final trackPaint = Paint()..color = EmaStyle.track;
    canvas.drawRRect(trackRect, trackPaint);

    final ratio = fillRatio;
    if (ratio == null) return;

    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped > 0) {
      final fillWidth = (size.width * clamped).clamp(0.0, size.width);
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, midY - _thickness / 2, fillWidth, _thickness),
        radius,
      );
      final fillPaint = Paint()..color = EmaStyle.blue;
      canvas.drawRRect(fillRect, fillPaint);
    }

    // Indicador tras responder: círculo blanco con borde azul de 9px. El centro
    // se reserva el radio del indicador en cada extremo (como el `calc(100% -
    // 36px)` del prototipo) para no salirse de la tarjeta.
    const r = EmaStyle.thumbDiameter / 2;
    final usable = (size.width - EmaStyle.thumbDiameter).clamp(0.0, size.width);
    final cx = r + usable * clamped;
    final center = Offset(cx, midY);

    final whitePaint = Paint()..color = ContigoColors.surface;
    canvas.drawCircle(center, r, whitePaint);
    final borderPaint = Paint()
      ..color = EmaStyle.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmaStyle.thumbBorder;
    // El borde se pinta hacia dentro del radio para mantener el diámetro de 36.
    canvas.drawCircle(center, r - EmaStyle.thumbBorder / 2, borderPaint);
  }

  @override
  bool shouldRepaint(_EmaRangeBarPainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio;
}
