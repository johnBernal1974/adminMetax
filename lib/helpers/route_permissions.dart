class RoutePermissions {
  static const String masterRole = 'Master';

  static const Map<String, Set<String>> routePermissions = {
    // acceso total (para operadorFull)
    'general_page': {'operadorFull'},
    'usuarios_page': {'operadorFull'},

    // ✅ AHORA también entra operadorSeguimientoMap
    'conductores_page': {'operadorFull', 'operadorSeguimientoMap'},

    'historial_viajes_page': {'operadorFull'},
    'detalle_vehiculo_page': {'operadorFull'},

    // mapa
    'map_drivers_admin_page': {'operadorFull', 'operadorSeguimientoMap'},

    // recargas
    'recarga_info_page': {'operadorFull', 'adminRecargas'},
  };

  static bool canRoleAccess(String role, String routeName) {
    if (role == masterRole) return true;

    final allowed = routePermissions[routeName];
    if (allowed == null) return false;

    return allowed.contains(role);
  }
}