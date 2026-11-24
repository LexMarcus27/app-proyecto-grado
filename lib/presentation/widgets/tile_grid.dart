import 'package:flutter/widgets.dart';

/// Rejilla de dos columnas con filas de igual altura, equivalente a
/// `.home-tile-grid` / `.caregiver-grid` del prototipo
/// (`grid-template-columns: repeat(2, minmax(0, 1fr))`).
class ContigoTileGrid extends StatelessWidget {
  const ContigoTileGrid({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  /// Escala de texto a partir de la cual la rejilla usa una sola columna.
  static const double singleColumnTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    // Con fuente grande (≥ 150 %), dos columnas parten los títulos a mitad de
    // palabra («Aprendi / endo»): las tarjetas pasan a una sola columna
    // (verificación Android, sesión 4, G8).
    if (MediaQuery.textScalerOf(context).scale(1) >= singleColumnTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            // Alto propio acotado: las tarjetas reparten su espacio con
            // `Expanded`/`Spacer`, igual que en las filas de dos columnas.
            IntrinsicHeight(child: children[i]),
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: gap),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
