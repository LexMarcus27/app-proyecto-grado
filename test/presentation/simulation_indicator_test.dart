import 'package:contigo/app/theme.dart';
import 'package:contigo/presentation/feature_layer.dart';
import 'package:contigo/presentation/widgets/simulation_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Envuelve el widget bajo prueba con el tema de la app para que las lecturas de
/// `Theme.of(context)` funcionen igual que en la app real.
Widget _host(Widget child) {
  return MaterialApp(
    theme: ContigoTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('FeatureLayer (metadato de capa de madurez)', () {
    test('solo Capa_Simulada muestra el indicador de simulación', () {
      expect(FeatureLayer.local.showsSimulationIndicator, isFalse);
      expect(FeatureLayer.simulada.showsSimulationIndicator, isTrue);
      expect(FeatureLayer.firebase.showsSimulationIndicator, isFalse);
    });

    test('FeatureLayerInfo delega la decisión en su capa', () {
      const simulada = FeatureLayerInfo(
        featureId: 'caring-messages',
        layer: FeatureLayer.simulada,
      );
      const firebase = FeatureLayerInfo(
        featureId: 'caring-messages',
        layer: FeatureLayer.firebase,
      );
      expect(simulada.showsSimulationIndicator, isTrue);
      expect(firebase.showsSimulationIndicator, isFalse);
    });
  });

  group('SimulationIndicator (Req. 3.4 / 3.6)', () {
    testWidgets('se muestra para Capa_Simulada', (tester) async {
      await tester.pumpWidget(
        _host(const SimulationIndicator(layer: FeatureLayer.simulada)),
      );

      expect(find.textContaining('simulada'), findsOneWidget);
      // El indicador ocupa espacio visible (no es un shrink vacío).
      final size = tester.getSize(find.byType(SimulationIndicator));
      expect(size.height, greaterThan(0));
    });

    testWidgets('está ausente para Capa_Local', (tester) async {
      await tester.pumpWidget(
        _host(const SimulationIndicator(layer: FeatureLayer.local)),
      );

      expect(find.textContaining('simulada'), findsNothing);
      final size = tester.getSize(find.byType(SimulationIndicator));
      expect(size.height, 0);
    });

    testWidgets('está ausente para Capa_Firebase (promoción retira el indicador)',
        (tester) async {
      await tester.pumpWidget(
        _host(const SimulationIndicator(layer: FeatureLayer.firebase)),
      );

      expect(find.textContaining('simulada'), findsNothing);
      final size = tester.getSize(find.byType(SimulationIndicator));
      expect(size.height, 0);
    });

    testWidgets('usa el label propio de la feature cuando se construye con forFeature',
        (tester) async {
      const info = FeatureLayerInfo(
        featureId: 'activation',
        layer: FeatureLayer.simulada,
        label: 'Activación simulada',
      );
      await tester.pumpWidget(
        _host(SimulationIndicator.forFeature(info)),
      );

      expect(find.text('Activación simulada'), findsOneWidget);
    });

    testWidgets('forFeature con Capa_Firebase no renderiza nada', (tester) async {
      const info = FeatureLayerInfo(
        featureId: 'activation',
        layer: FeatureLayer.firebase,
        label: 'Activación simulada',
      );
      await tester.pumpWidget(
        _host(SimulationIndicator.forFeature(info)),
      );

      expect(find.text('Activación simulada'), findsNothing);
      final size = tester.getSize(find.byType(SimulationIndicator));
      expect(size.height, 0);
    });
  });
}
