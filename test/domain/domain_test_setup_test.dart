// Pruebas del dominio con `dart test` (Dart puro, sin Flutter).
//
// La lógica de dominio portada del prototipo se prueba aquí como pruebas de
// ejemplo/unitarias, independientes de Flutter y Firebase. Este archivo verifica
// únicamente que el framework `dart test` está correctamente configurado; las
// suites de dominio reales (autorización, EMA, métricas, etc.) se agregan en las
// tareas posteriores.
import 'package:test/test.dart';

void main() {
  group('configuración de dart test para el dominio', () {
    test('el framework dart test está disponible', () {
      expect(true, isTrue);
    });
  });
}
