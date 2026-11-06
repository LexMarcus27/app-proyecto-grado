import '../../domain/repositories/repositories.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';

/// Implementación en memoria de [SafetyPlanStore] (sesión).
///
/// El borrador del plan de seguridad vive solo en memoria: no se escribe en el
/// almacenamiento local del PCS (Requirement 7.1, 7.5). Mantiene un borrador
/// **independiente por escenario** (clave [String]); modificar uno no altera
/// los demás (aislamiento entre escenarios de demostración, Requirement 7.3).
class InMemorySafetyPlanStore implements SafetyPlanStore {
  final Map<String, SafetyPlanDraft> _draftsByScenario = {};

  @override
  Future<SafetyPlanDraft?> loadDraft(String scenario) async {
    return _draftsByScenario[scenario];
  }

  @override
  Future<void> saveDraft(String scenario, SafetyPlanDraft draft) async {
    _draftsByScenario[scenario] = draft;
  }

  @override
  Future<void> clear(String scenario) async {
    _draftsByScenario.remove(scenario);
  }
}