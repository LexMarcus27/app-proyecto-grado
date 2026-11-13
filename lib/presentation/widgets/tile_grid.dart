import 'package:flutter/widgets.dart';

/// Rejilla de dos columnas con filas de igual altura, equivalente a
/// `.home-tile-grid` / `.caregiver-grid` del prototipo
/// (`grid-template-columns: repeat(2, minmax(0, 1fr))`).
class ContigoTileGrid extends StatelessWidget {
  const ContigoTileGrid({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
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
