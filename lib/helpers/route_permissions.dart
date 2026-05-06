class RoutePermissions {
  static const String masterRole = 'Master';

  static const Map<String, Set<String>> routePermissions = {

    // acceso total (para operadorFull + operador1)
    'general_page': {'operadorFull', 'operador1'},
    'usuarios_page': {'operadorFull', 'operador1'},

    // conductores
    'conductores_page': {'operadorFull', 'operadorSeguimientoMap', 'operador1'},

    'historial_viajes_page': {'operadorFull'},

    'detalle_vehiculo_page': {'operadorFull', 'operador1'},
    'campanas_whatsapp_page': {'operadorFull'},

    // mapa
    'map_drivers_admin_page': {'operadorFull', 'operadorSeguimientoMap', 'operador1'},

    // recargas
    'recarga_info_page': {'operadorFull', 'adminRecargas'},

    /// 🔥 portería
    'registro_porteria_page': {'operadorFull', 'operador_bases'},
    'porterias_page': {'operadorFull', 'operador_bases'},
    'editar_porteria_page': {'operadorFull', 'operador_bases'},

    'prices_page': {'operadorFull'},

    // 🔥 WhatsApp MetaX
    'whatsapp_metax_page': {'operadorFull', 'operador1'},
  };

  static bool canRoleAccess(String role, String routeName) {
    if (role == masterRole) return true;

    final allowed = routePermissions[routeName];
    if (allowed == null) return false;

    return allowed.contains(role);
  }
}