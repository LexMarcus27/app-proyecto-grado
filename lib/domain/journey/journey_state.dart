import 'package:equatable/equatable.dart';

import 'care_association.dart';
import 'network_person.dart';
import 'onboarding_status.dart';

/// Estado del recorrido del PCS.
///
/// Portado del prototipo (`src/journey.ts`, interfaz `JourneyState`). Modelo
/// inmutable con igualdad por valor que agrupa el mapa de red, las personas,
/// las asociaciones de cuidado y el estado del onboarding.
class JourneyState extends Equatable {
  const JourneyState({
    required this.mapStarted,
    required this.mapGenerated,
    required this.people,
    required this.selectedPersonId,
    required this.associations,
    required this.onboardingStatus,
    required this.onboardingWelcomeShown,
    required this.activityInProgress,
    required this.dailyCheckInPending,
  });

  /// `true` si el usuario comenzó a construir el mapa de red.
  final bool mapStarted;

  /// `true` si el mapa de red ya fue generado.
  final bool mapGenerated;

  /// Personas de la red de apoyo.
  final List<NetworkPerson> people;

  /// Persona seleccionada actualmente, o `null`.
  final String? selectedPersonId;

  /// Asociaciones de cuidado conocidas.
  final List<CareAssociation> associations;

  /// Estado del recorrido de onboarding.
  final OnboardingStatus onboardingStatus;

  /// `true` si ya se mostró la bienvenida del onboarding.
  final bool onboardingWelcomeShown;

  /// `true` si hay una actividad en progreso.
  final bool activityInProgress;

  /// `true` si el check-in diario está pendiente.
  final bool dailyCheckInPending;

  /// Devuelve una copia con los campos indicados reemplazados.
  ///
  /// Nota: `selectedPersonId` no puede borrarse (volverse `null`) con
  /// `copyWith`; omitir el parámetro conserva el valor actual.
  JourneyState copyWith({
    bool? mapStarted,
    bool? mapGenerated,
    List<NetworkPerson>? people,
    String? selectedPersonId,
    List<CareAssociation>? associations,
    OnboardingStatus? onboardingStatus,
    bool? onboardingWelcomeShown,
    bool? activityInProgress,
    bool? dailyCheckInPending,
  }) {
    return JourneyState(
      mapStarted: mapStarted ?? this.mapStarted,
      mapGenerated: mapGenerated ?? this.mapGenerated,
      people: people ?? this.people,
      selectedPersonId: selectedPersonId ?? this.selectedPersonId,
      associations: associations ?? this.associations,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      onboardingWelcomeShown:
          onboardingWelcomeShown ?? this.onboardingWelcomeShown,
      activityInProgress: activityInProgress ?? this.activityInProgress,
      dailyCheckInPending: dailyCheckInPending ?? this.dailyCheckInPending,
    );
  }

  @override
  List<Object?> get props => [
    mapStarted,
    mapGenerated,
    people,
    selectedPersonId,
    associations,
    onboardingStatus,
    onboardingWelcomeShown,
    activityInProgress,
    dailyCheckInPending,
  ];
}
