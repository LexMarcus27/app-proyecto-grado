import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'ema_style.dart';

/// Textos del ítem binario, portados verbatim del prototipo (`ema.tsx`).
class _EmaBinaryText {
  const _EmaBinaryText._();

  /// Leyenda semántica del fieldset (`<legend className="sr-only">`).
  static const String semanticLabel = 'Responde Sí o No';

  /// Etiqueta de la opción afirmativa.
  static const String yes = 'Sí';

  /// Etiqueta de la opción negativa.
  static const String no = 'No';
}

/// Ítem binario Sí/No del EMA (`daily-nine-v2`), portado del `fieldset` binario
/// del prototipo (`src/screens/ema.tsx`).
///
/// Comportamiento y accesibilidad (Requirement 5.2):
///
/// - Dos opciones seleccionables: "Sí" (`true`) y "No" (`false`), renderizadas
///   como chips/radio. Comienza con **ninguna** opción seleccionada ([value]
///   `null`).
/// - Se expone como un **grupo de radios**: cada opción es un [Semantics] con
///   `inMutuallyExclusiveGroup` y `checked` según la selección. La opción
///   marcada se resalta visualmente (equivalente a `is-selected` del prototipo).
/// - Al tocar una opción se notifica [onChanged] con `true`/`false`.
///
/// API: `EmaBinaryItem({required bool? value, required ValueChanged<bool> onChanged})`.
class EmaBinaryItem extends StatelessWidget {
  const EmaBinaryItem({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Opción seleccionada (`true`/`false`), o `null` si no se ha respondido.
  final bool? value;

  /// Notifica la opción elegida.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _EmaBinaryText.semanticLabel,
      child: Row(
        children: [
          Expanded(
            child: _EmaBinaryOption(
              label: _EmaBinaryText.yes,
              selected: value == true,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EmaBinaryOption(
              label: _EmaBinaryText.no,
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opción Sí/No, presentada como chip seleccionable y expuesta como radio.
class _EmaBinaryOption extends StatelessWidget {
  const _EmaBinaryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Pastilla azul del prototipo (`.ema-binary-card label`):
    // - sin seleccionar: fondo `#F4F9FC`, borde `#9EBFD4`, texto `#2B6087`.
    // - seleccionada (`.is-selected`): relleno `#3174A1`, texto blanco, borde
    //   `#3174A1`.
    final background = selected ? EmaStyle.blue : EmaStyle.binaryBg;
    final foreground = selected ? ContigoColors.surface : EmaStyle.blueText;
    final borderColor = selected ? EmaStyle.blue : EmaStyle.binaryBorder;
    // Radio de pastilla (`border-radius: 999px`).
    const pill = BorderRadius.all(Radius.circular(999));

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      button: true,
      child: Material(
        color: background,
        borderRadius: pill,
        child: InkWell(
          onTap: onTap,
          borderRadius: pill,
          child: Container(
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: pill,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
