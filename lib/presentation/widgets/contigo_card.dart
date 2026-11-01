import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Tarjeta de contenido equivalente al componente `Card` del prototipo
/// (`ui.tsx`): superficie blanca, radio 16, relleno 20, borde sutil y sombra
/// suave. Preserva el estilo del prototipo (Requirement 2.3) tomando los colores
/// del tema, sin literales.
///
/// Si se pasa [onTap], se vuelve pulsable (equivalente al `onClick` del
/// prototipo). Para una tarjeta cuya superficie entera es un botón con etiqueta
/// de accesibilidad, usar [ContigoActionCard].
class ContigoCard extends StatelessWidget {
  const ContigoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: ContigoColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ContigoColors.notifQuestionsBg),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12_3A3238),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tarjeta cuya superficie completa es un botón, equivalente al `ActionCard` del
/// prototipo: misma apariencia que [ContigoCard] pero con rol de botón y
/// etiqueta de accesibilidad obligatoria ([semanticLabel] ≈ `aria-label`).
class ContigoActionCard extends StatelessWidget {
  const ContigoActionCard({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback onPressed;
  final String semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: ContigoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ContigoColors.notifQuestionsBg),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12_3A3238),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: ContigoColors.ink),
                child: ExcludeSemantics(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
