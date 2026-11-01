import 'package:flutter/material.dart';

/// Constantes de estilo específicas del hilo EMA ("Tu tejido de hoy"), portadas
/// del prototipo (`src/index.css`, reglas `.ema-*`).
///
/// La paleta azul del EMA (banner, barra de rango, pastillas binarias, botón
/// primario azul y chip de contexto de referencia) **no** tiene equivalente en
/// los tokens globales de marca ([ContigoColors], centrados en la terracota del
/// PCS), por lo que se concentra aquí como estilo local del EMA —consistente con
/// cómo [EmaRangeItem] ya definía `#3174A1`/`#D0E3EE`—. No se altera el tema
/// global; solo las pantallas/ítems del EMA consumen estas constantes.
class EmaStyle {
  const EmaStyle._();

  // --- Paleta azul del EMA ---
  /// Azul primario del EMA: relleno de barra, pastilla seleccionada, botón azul
  /// y borde del indicador (`#3174A1`).
  static const Color blue = Color(0xFF3174A1);

  /// Azul de texto del banner/eyebrow y chip de contexto (`#2B6087`).
  static const Color blueText = Color(0xFF2B6087);

  /// Pista de fondo del rango y borde de pastilla sin seleccionar (`#D0E3EE`).
  static const Color track = Color(0xFFD0E3EE);

  /// Fondo celeste del banner, chip de contexto y fondo de pastilla (`#E4F0F7`).
  static const Color bannerBg = Color(0xFFE4F0F7);

  /// Fondo muy claro de la pastilla binaria sin seleccionar (`#F4F9FC`).
  static const Color binaryBg = Color(0xFFF4F9FC);

  /// Borde de la pastilla binaria/punto sin seleccionar (`#9EBFD4`).
  static const Color binaryBorder = Color(0xFF9EBFD4);

  /// Texto secundario/apagado del EMA: extremos, "Hilo N de M", enlaces
  /// secundarios (`#52555D`).
  static const Color muted = Color(0xFF52555D);

  // --- Geometría portada del CSS ---
  /// Radio de las tarjetas de ítem (`.ema-continuous-card`/`.ema-binary-card`,
  /// `border-radius: 23px`).
  static const double cardRadius = 23;

  /// Radio del banner (`.ema-thread-banner`, `border-radius: 24px`).
  static const double bannerRadius = 24;

  /// Grosor de la pista del rango (`.ema-thread-track { height: 4px }` y
  /// `.ema-continuous-card input { background-size: ... 6px }`): 6px.
  static const double trackThickness = 6;

  /// Diámetro del indicador (thumb) tras responder (`36x36`).
  static const double thumbDiameter = 36;

  /// Grosor del borde azul del indicador (`border: 9px solid #3174A1`).
  static const double thumbBorder = 9;

  /// Alto mínimo del botón primario azul del hilo (`min-height: 54px`).
  static const double primaryButtonHeight = 54;

  /// Opacidad del botón primario deshabilitado (`opacity: .45`).
  static const double disabledOpacity = 0.45;
}
