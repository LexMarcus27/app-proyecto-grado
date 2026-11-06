import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/journey/demo_seeder.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';

/// Clave de escenario del plan de seguridad: el `name` del [DemoScenario]
/// activo. El almacén mantiene un borrador por clave, de modo que alternar de
/// escenario conserva cada plan por separado (aislamiento, Requirement 7.3).
final safetyPlanScenarioKeyProvider = Provider<String>((ref) {
  return ref.watch(demoScenarioControllerProvider).name;
});

/// Controlador del borrador del plan de seguridad para el escenario activo.
///
/// Carga el borrador del escenario actual desde el [safetyPlanStoreProvider]
/// (o uno vacío si aún no hay) y persiste cada edición **en el mismo escenario**,
/// sin afectar a los demás. El borrador vive solo en la sesión; nunca se escribe
/// en el almacenamiento local del PCS (Requirement 7.1, 7.5).
class SafetyPlanController extends AsyncNotifier<SafetyPlanDraft> {
  String get _scenario => ref.read(safetyPlanScenarioKeyProvider);

  @override
  Future<SafetyPlanDraft> build() async {
    // Reacciona al cambio de escenario recargando el borrador correspondiente.
    final scenario = ref.watch(safetyPlanScenarioKeyProvider);
    final store = ref.watch(safetyPlanStoreProvider);
    final existing = await store.loadDraft(scenario);
    return existing ?? createSafetyPlanDraft();
  }

  Future<void> _persist(SafetyPlanDraft draft) async {
    state = AsyncData(draft);
    await ref.read(safetyPlanStoreProvider).saveDraft(_scenario, draft);
  }

  /// Aplica una transformación al borrador actual y la persiste.
  Future<void> edit(
    SafetyPlanDraft Function(SafetyPlanDraft current) transform,
  ) async {
    final current = state.value ?? createSafetyPlanDraft();
    await _persist(transform(current));
  }

  /// Reemplaza el texto del paso [index].
  Future<void> setStepText(int index, String text) {
    return edit((current) {
      final texts = [...current.stepTexts];
      if (index >= 0 && index < texts.length) texts[index] = text.trim();
      return current.copyWith(stepTexts: texts);
    });
  }

  /// Agrega un contacto de apoyo.
  Future<void> addContact(SafetyPlanContact contact) {
    return edit(
      (current) => current.copyWith(contacts: [...current.contacts, contact]),
    );
  }

  /// Quita el contacto en la posición [index].
  Future<void> removeContact(int index) {
    return edit((current) {
      final contacts = [...current.contacts]..removeAt(index);
      return current.copyWith(contacts: contacts);
    });
  }

  /// Agrega una actividad.
  Future<void> addActivity(String activity) {
    final trimmed = activity.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return edit(
      (current) =>
          current.copyWith(activities: [...current.activities, trimmed]),
    );
  }

  /// Quita la actividad en la posición [index].
  Future<void> removeActivity(int index) {
    return edit((current) {
      final activities = [...current.activities]..removeAt(index);
      return current.copyWith(activities: activities);
    });
  }

  /// Fija la descripción del entorno más seguro.
  Future<void> setEnvironment(String environment) {
    return edit(
      (current) => current.copyWith(environment: environment.trim()),
    );
  }

  /// Reemplaza el borrador completo (simulación demo del estado del plan).
  Future<void> replaceWith(SafetyPlanDraft draft) => _persist(draft);
}

/// Provider del controlador del plan de seguridad del escenario activo.
final safetyPlanControllerProvider =
    AsyncNotifierProvider<SafetyPlanController, SafetyPlanDraft>(
  SafetyPlanController.new,
);