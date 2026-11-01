import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';

/// Pantalla de desarrollo "Ver componentes": una galería que muestra los
/// componentes reales de la Etapa 1 usando el tema real ([ContigoTheme.light]),
/// para revisarlos en el emulador.
///
/// No forma parte del producto: es una ayuda de revisión visual accesible desde
/// la pantalla de activación. Reutiliza los widgets existentes
/// (`lib/presentation/widgets`) tal cual, sin recrearlos, para que lo que se ve
/// aquí sea exactamente lo que renderiza la app.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StatusBar(showOnNative: true),
            // Encabezado con opción de volver a la activación.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed('activation');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ver componentes',
                      style: textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: const [
                  _Section(
                    title: 'Tipografía',
                    child: _TypographySample(),
                  ),
                  _Section(
                    title: 'Botones',
                    child: _ButtonsSample(),
                  ),
                  _Section(
                    title: 'Tarjetas',
                    child: _CardsSample(),
                  ),
                  _Section(
                    title: 'Indicador de simulación',
                    child: _SimulationIndicatorSample(),
                  ),
                  _Section(
                    title: 'CompanionNote',
                    child: _CompanionSample(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque con un título (en Lora, vía [TextTheme.headlineSmall]) y su muestra.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TypographySample extends StatelessWidget {
  const _TypographySample();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Título display (Lora)', style: t.displaySmall),
        const SizedBox(height: 8),
        Text('Encabezado (Lora)', style: t.headlineMedium),
        const SizedBox(height: 8),
        Text('Título de sección (Inter)', style: t.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Texto de cuerpo en Inter. Las palabras cotidianas se leen con '
          'comodidad; los títulos usan la serif Lora para dar calidez.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text('Texto pequeño y apagado (Inter).', style: t.bodySmall),
      ],
    );
  }
}

class _ButtonsSample extends StatelessWidget {
  const _ButtonsSample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ContigoButton(label: 'Primario', onPressed: () {}),
            ContigoButton(
              label: 'Secundario',
              variant: ContigoButtonVariant.secondary,
              onPressed: () {},
            ),
            ContigoButton(
              label: 'Terciario',
              variant: ContigoButtonVariant.tertiary,
              onPressed: () {},
            ),
            ContigoButton(
              label: 'Crítico',
              variant: ContigoButtonVariant.critical,
              onPressed: () {},
            ),
            ContigoButton(
              label: 'Fantasma',
              variant: ContigoButtonVariant.ghost,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        ContigoButton(
          label: 'Primario (ancho completo)',
          fullWidth: true,
          icon: const Icon(Icons.favorite_border),
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ContigoButton(label: 'Compacto', small: true, onPressed: () {}),
            const SizedBox(width: 10),
            const ContigoButton(label: 'Deshabilitado'),
          ],
        ),
      ],
    );
  }
}

class _CardsSample extends StatelessWidget {
  const _CardsSample();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        ContigoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarjeta de contenido', style: t.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Superficie blanca, borde sutil y sombra suave, como en el '
                'prototipo.',
                style: t.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ContigoActionCard(
          semanticLabel: 'Tarjeta de acción de ejemplo',
          onPressed: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarjeta de acción', style: t.titleMedium),
              const SizedBox(height: 6),
              Text('Toda la superficie es pulsable.', style: t.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimulationIndicatorSample extends StatelessWidget {
  const _SimulationIndicatorSample();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capa_Simulada: el indicador se muestra (Requirement 3.4).
        SimulationIndicator(layer: FeatureLayer.simulada),
        SizedBox(height: 10),
        SimulationIndicator(
          layer: FeatureLayer.simulada,
          label: 'Envío simulado: no se entrega a una persona real.',
        ),
      ],
    );
  }
}

class _CompanionSample extends StatelessWidget {
  const _CompanionSample();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CompanionNote(
          child: Text('Pose de bienvenida. Me alegra verte por aquí.'),
        ),
        SizedBox(height: 4),
        CompanionNote(
          affection: true,
          child: Text('Pose de afecto. Gracias por contarme cómo estás.'),
        ),
      ],
    );
  }
}

