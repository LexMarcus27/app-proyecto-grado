import '../../domain/repositories/repositories.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';

/// Implementación simulada de [ContactsService] (Capa_Simulada).
///
/// Reproduce el flujo del prototipo (`MobileScreen05`): "Permitir acceso"
/// concede el permiso **fingido** y agrega un contacto ficticio
/// ("Dra. Valentina Ríos"); no se accede a los contactos reales del dispositivo
/// ni se agrega ninguno real (Requirement 7.4). La pantalla muestra el indicador
/// de simulación persistente.
class SimulatedContactsService implements ContactsService {
  SimulatedContactsService({this.grantPermission = true});

  /// Si el permiso simulado se concede. Configurable para pruebas/escenarios.
  final bool grantPermission;

  @override
  Future<bool> requestPermission() async => grantPermission;

  @override
  Future<List<SafetyPlanContact>> importContacts() async {
    return const [
      SafetyPlanContact(
        name: 'Dra. Valentina Ríos',
        label: 'Terapeuta',
        phone: '+57 300 000 0003',
      ),
    ];
  }
}