import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../journey/caregiver.dart';

/// Borrador de un mensaje de cuidado (portado de `CaringMessageDraft`,
/// `src/caring-messages.ts`).
///
/// Es un borrador **de sesión**: el texto, las preguntas de reflexión
/// seleccionadas y las notas privadas viven solo en memoria y **nunca** forman
/// parte del registro del mensaje enviado (Requirement 8.5).
class CaringMessageDraft extends Equatable {
  const CaringMessageDraft({
    this.text = '',
    this.selectedQuestions = const [],
    this.notes = const {},
  });

  /// Texto del mensaje en construcción.
  final String text;

  /// Índices de las preguntas de reflexión seleccionadas (orden ascendente).
  final List<int> selectedQuestions;

  /// Notas privadas por índice de pregunta. Nunca se incluyen en el registro.
  final Map<int, String> notes;

  CaringMessageDraft copyWith({
    String? text,
    List<int>? selectedQuestions,
    Map<int, String>? notes,
  }) {
    return CaringMessageDraft(
      text: text ?? this.text,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [text, selectedQuestions, notes];
}

/// Registro de un mensaje de cuidado "enviado" en la simulación (portado de
/// `SimulatedCaringMessage`, `src/caring-messages.ts`).
///
/// Conserva **solo** identificadores de la tupla de cuidado, el texto y el
/// estado de entrega simulado. **No** incluye notas privadas ni las preguntas de
/// reflexión (Requirement 8.5). La entrega es siempre `"simulated"`.
class SimulatedCaringMessage extends Equatable {
  const SimulatedCaringMessage({
    required this.id,
    required this.caregiverId,
    required this.caregiverName,
    required this.pcsId,
    required this.pcsName,
    required this.personId,
    required this.associationId,
    required this.text,
    this.delivery = 'simulated',
  });

  final String id;
  final String caregiverId;
  final String caregiverName;
  final String pcsId;
  final String pcsName;
  final String personId;
  final String associationId;
  final String text;

  /// Estado de entrega; en la Capa_Simulada siempre es `"simulated"`.
  final String delivery;

  @override
  List<Object?> get props => [
        id,
        caregiverId,
        caregiverName,
        pcsId,
        pcsName,
        personId,
        associationId,
        text,
        delivery,
      ];
}

/// Clave de borrador por tupla de cuidado (portado de `caringDraftKey`).
///
/// Serializa la tupla [caregiverId, pcsId, personId, associationId] igual que el
/// prototipo (`JSON.stringify` de una lista), de modo que cada vínculo mantiene
/// su propio borrador.
String caringDraftKey(CaregiverContext context) {
  return jsonEncode([
    context.caregiverId,
    context.pcsId,
    context.personId,
    context.associationId,
  ]);
}