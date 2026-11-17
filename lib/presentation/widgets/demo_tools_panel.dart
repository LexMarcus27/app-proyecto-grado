import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dashed_border.dart';

/// Panel plegable «Herramientas de demostración» de los inicios (propuestas
/// visuales A): recuadro con borde punteado salvia, triángulo y título verde.
/// Agrupa las simulaciones y accesos de desarrollo para que no dominen la
/// pantalla de uso; empieza plegado.
class DemoToolsPanel extends StatefulWidget {
  const DemoToolsPanel({
    super.key,
    required this.children,
    this.title = 'Herramientas de demostración',
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<DemoToolsPanel> createState() => _DemoToolsPanelState();
}

class _DemoToolsPanelState extends State<DemoToolsPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: ContigoColors.sageSoft,
      radius: 16,
      child: Material(
        color: ContigoColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: ContigoColors.sage,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: ContigoTheme.bodyFontFamily,
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w700,
                            color: ContigoColors.sage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.children,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
