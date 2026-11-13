import 'package:flutter/material.dart';

/// Paleta y tipografía portadas del prototipo "Contigo" (React/Vite + Tailwind v4).
///
/// Fuente autoritativa: el prototipo revisado (`src/index.css` y
/// `src/notifications.ts`). Preserva disposición, paleta y tipografía conforme
/// al Requirement 2.3, y define a nivel de tema los pares texto/fondo de las
/// tarjetas de notificación con contraste WCAG ≥ 4.5:1 (Requirement 12.5).
class ContigoColors {
  const ContigoColors._();

  // --- Lienzo y texto base (body del prototipo) ---
  /// Fondo cálido principal (`body { background-color: #F7F1E8 }`).
  static const Color canvas = Color(0xFFF7F1E8);

  /// Variante más clara del lienzo usada en el inicio (`.home-screen`).
  static const Color canvasLight = Color(0xFFFBF9F6);

  /// Color de texto principal (`body { color: #3A3238 }`). También es el color
  /// de texto de las tarjetas de notificación.
  static const Color ink = Color(0xFF3A3238);

  /// Texto secundario/apagado (`.ema-note`, `.caregiver-note`, etc.).
  static const Color inkMuted = Color(0xFF62575E);

  /// Superficie blanca de tarjetas y barras (`background: #FFFFFF`).
  static const Color surface = Color(0xFFFFFFFF);

  // --- Acentos de marca ---
  /// Verde salvia: foco, recordatorios, acción del cuidador (`#536B50`).
  static const Color sage = Color(0xFF536B50);

  /// Verde salvia más suave usado en bordes punteados demo (`#7C9473`).
  static const Color sageSoft = Color(0xFF7C9473);

  /// Arcilla/rosa: ayuda y énfasis cálido del EMA (`#8D4541`).
  static const Color clay = Color(0xFF8D4541);

  /// Terracota primaria de acciones del PCS (`.pcs-primary #AA461D`).
  static const Color terracotta = Color(0xFFAA461D);

  /// Rosa de marca del `Btn` general del prototipo (`C.brand = #A85550`).
  static const Color brand = Color(0xFFA85550);

  /// Fondo suave de marca (`C.brandSoft = #F2E3E0`).
  static const Color brandSoft = Color(0xFFF2E3E0);

  /// Rojo de las acciones críticas generales (`C.critical = #A3474A`).
  static const Color critical = Color(0xFFA3474A);

  /// Borde neutro habitual (`C.border = #DFD4C9`).
  static const Color border = Color(0xFFDFD4C9);

  /// Violeta de navegación/enlaces del inicio (`#5D49A5`).
  static const Color violet = Color(0xFF5D49A5);

  // --- Pares de tarjetas de notificación (de NOTIFICATION_STYLES) ---
  // El color de texto de toda tarjeta de notificación es [ink] (#3A3238);
  // el acento (etiqueta de tipo) y el fondo varían por tipo. Todos los pares
  // acento/fondo y texto/fondo verifican contraste ≥ 4.5:1 (ver contrast_test).
  static const Color notifReminderBg = Color(0xFFE5EDE2);
  static const Color notifReminderAccent = Color(0xFF536B50);

  static const Color notifQuestionsBg = Color(0xFFF1E9DF);
  static const Color notifQuestionsAccent = Color(0xFF75634E);

  static const Color notifIntimateBg = Color(0xFFEEE6F2);
  static const Color notifIntimateAccent = Color(0xFF735D83);

  static const Color notifSocialBg = Color(0xFFE9EEF5);
  static const Color notifSocialAccent = Color(0xFF506A87);

  static const Color notifMeetingBg = Color(0xFFF2E3E0);
  static const Color notifMeetingAccent = Color(0xFF8D4541);

  static const Color notifClosenessBg = Color(0xFFF8ECD4);
  static const Color notifClosenessAccent = Color(0xFF805C1D);
}

/// Un par de colores texto/fondo de una tarjeta de notificación del prototipo.
///
/// El texto del cuerpo usa [text]; la etiqueta de tipo usa [accent]. Ambos se
/// pintan sobre [background]. Modelado a nivel de tema para que las pantallas de
/// notificación no codifiquen colores a mano (Requirement 12.5).
@immutable
class NotificationPalette {
  const NotificationPalette({
    required this.background,
    required this.accent,
    required this.text,
  });

  /// Fondo de la tarjeta.
  final Color background;

  /// Color del acento: borde izquierdo y etiqueta de tipo.
  final Color accent;

  /// Color del texto del cuerpo de la notificación.
  final Color text;
}

/// Extensión de tema que expone los pares de color de las tarjetas de
/// notificación por tipo. Al vivir en el [ThemeData], las pantallas los leen con
/// `Theme.of(context).extension<ContigoNotificationTheme>()` en lugar de
/// codificar colores, y el contraste queda garantizado por el tema.
@immutable
class ContigoNotificationTheme
    extends ThemeExtension<ContigoNotificationTheme> {
  const ContigoNotificationTheme({
    required this.reminder,
    required this.questions,
    required this.intimate,
    required this.social,
    required this.meeting,
    required this.closeness,
  });

  final NotificationPalette reminder;
  final NotificationPalette questions;
  final NotificationPalette intimate;
  final NotificationPalette social;
  final NotificationPalette meeting;
  final NotificationPalette closeness;

  /// Pares de color portados verbatim de `NOTIFICATION_STYLES` del prototipo.
  /// El texto del cuerpo es siempre [ContigoColors.ink] (#3A3238).
  static const ContigoNotificationTheme prototype = ContigoNotificationTheme(
    reminder: NotificationPalette(
      background: ContigoColors.notifReminderBg,
      accent: ContigoColors.notifReminderAccent,
      text: ContigoColors.ink,
    ),
    questions: NotificationPalette(
      background: ContigoColors.notifQuestionsBg,
      accent: ContigoColors.notifQuestionsAccent,
      text: ContigoColors.ink,
    ),
    intimate: NotificationPalette(
      background: ContigoColors.notifIntimateBg,
      accent: ContigoColors.notifIntimateAccent,
      text: ContigoColors.ink,
    ),
    social: NotificationPalette(
      background: ContigoColors.notifSocialBg,
      accent: ContigoColors.notifSocialAccent,
      text: ContigoColors.ink,
    ),
    meeting: NotificationPalette(
      background: ContigoColors.notifMeetingBg,
      accent: ContigoColors.notifMeetingAccent,
      text: ContigoColors.ink,
    ),
    closeness: NotificationPalette(
      background: ContigoColors.notifClosenessBg,
      accent: ContigoColors.notifClosenessAccent,
      text: ContigoColors.ink,
    ),
  );

  /// Todos los pares como lista, útil para validar contraste de forma uniforme.
  List<NotificationPalette> get all => [
    reminder,
    questions,
    intimate,
    social,
    meeting,
    closeness,
  ];

  @override
  ContigoNotificationTheme copyWith({
    NotificationPalette? reminder,
    NotificationPalette? questions,
    NotificationPalette? intimate,
    NotificationPalette? social,
    NotificationPalette? meeting,
    NotificationPalette? closeness,
  }) {
    return ContigoNotificationTheme(
      reminder: reminder ?? this.reminder,
      questions: questions ?? this.questions,
      intimate: intimate ?? this.intimate,
      social: social ?? this.social,
      meeting: meeting ?? this.meeting,
      closeness: closeness ?? this.closeness,
    );
  }

  @override
  ContigoNotificationTheme lerp(
    ThemeExtension<ContigoNotificationTheme>? other,
    double t,
  ) {
    if (other is! ContigoNotificationTheme) return this;
    NotificationPalette lerpPair(
      NotificationPalette a,
      NotificationPalette b,
    ) => NotificationPalette(
      background: Color.lerp(a.background, b.background, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      text: Color.lerp(a.text, b.text, t)!,
    );
    return ContigoNotificationTheme(
      reminder: lerpPair(reminder, other.reminder),
      questions: lerpPair(questions, other.questions),
      intimate: lerpPair(intimate, other.intimate),
      social: lerpPair(social, other.social),
      meeting: lerpPair(meeting, other.meeting),
      closeness: lerpPair(closeness, other.closeness),
    );
  }
}

/// Tema de la app "Contigo", portado del prototipo.
class ContigoTheme {
  const ContigoTheme._();

  /// Familia tipográfica base del prototipo (`font-family: 'Inter', ...`).
  /// Inter se empaca con la app (assets/fonts/Inter-Variable.ttf) para no
  /// depender de que el sistema la provea; en Android no está disponible y
  /// caería a un fallback silencioso.
  static const String bodyFontFamily = 'Inter';
  static const List<String> bodyFontFallback = <String>[
    'system-ui',
    'sans-serif',
  ];

  // SUSTITUCIÓN DE FUENTE (títulos): el prototipo usa Georgia para las
  // cabeceras (`font: 700 .. Georgia, serif`). Georgia NO se distribuye en
  // Android, por lo que allí el título caería a la serif por defecto. Se empaca
  // **Lora** (serif OFL de trazo cálido y legible, cercana al carácter de
  // Georgia) como familia de títulos. Se conserva la cadena de respaldo
  // Georgia → Times New Roman → serif para iOS/web, donde Georgia sí existe y
  // mantiene la equivalencia visual del prototipo; en Android, si por algún
  // motivo Lora no cargara, degrada a la serif del sistema.
  static const String displayFontFamily = 'Lora';
  static const List<String> displayFontFallback = <String>[
    'Georgia',
    'Times New Roman',
    'serif',
  ];

  /// [ThemeData] claro con la paleta y la tipografía del prototipo.
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ContigoColors.terracotta,
      onPrimary: ContigoColors.surface,
      secondary: ContigoColors.sage,
      onSecondary: ContigoColors.surface,
      tertiary: ContigoColors.violet,
      onTertiary: ContigoColors.surface,
      error: ContigoColors.clay,
      onError: ContigoColors.surface,
      surface: ContigoColors.canvas,
      onSurface: ContigoColors.ink,
    );

    // Tipografía: cuerpo en Inter, títulos (display/headline) en serif Georgia,
    // reflejando el contraste tipográfico del prototipo.
    final textTheme = TextTheme(
      displayLarge: _display(52, FontWeight.w700, letterSpacing: -1.8),
      displayMedium: _display(48, FontWeight.w700, letterSpacing: -1.5),
      displaySmall: _display(30, FontWeight.w700, letterSpacing: -0.4),
      headlineLarge: _display(29, FontWeight.w700),
      headlineMedium: _display(26, FontWeight.w700),
      headlineSmall: _display(24, FontWeight.w700),
      titleLarge: _body(21, FontWeight.w700),
      titleMedium: _body(18, FontWeight.w700),
      titleSmall: _body(15, FontWeight.w600),
      bodyLarge: _body(17, FontWeight.w400, height: 24 / 17),
      bodyMedium: _body(16, FontWeight.w400, height: 25 / 16),
      bodySmall: _body(13, FontWeight.w400, height: 20 / 13),
      labelLarge: _body(15, FontWeight.w700),
      labelMedium: _body(13, FontWeight.w500),
      labelSmall: _body(12, FontWeight.w700),
    ).apply(bodyColor: ContigoColors.ink, displayColor: ContigoColors.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ContigoColors.canvas,
      canvasColor: ContigoColors.canvas,
      fontFamily: bodyFontFamily,
      fontFamilyFallback: bodyFontFallback,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: ContigoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ContigoNotificationTheme.prototype,
      ],
    );
  }

  static TextStyle _body(
    double size,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontFamilyFallback: bodyFontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _display(
    double size,
    FontWeight weight, {
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontFamilyFallback: displayFontFallback,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }
}
