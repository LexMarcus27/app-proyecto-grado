/// Roles de usuario soportados por la App_Contigo.
///
/// El alcance propuesto cubre **solo dos roles**: PCS (persona con conducta
/// suicida) y Cuidador. El panel del investigador/administrador queda fuera de
/// alcance y no tiene representación aquí ni ruta de navegación
/// (ver Requirement 1.2 y 1.4).
enum UserRole {
  /// Persona con conducta suicida.
  pcs,

  /// Usuario vinculado a un PCS mediante una asociación de cuidado.
  cuidador,
}
