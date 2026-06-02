class RoutePermissions {
  static const String masterRole = 'Master';

  static const Map<String, Set<String>> routePermissions = {

    // acceso total (para operadorFull + operador1)
    'general_page': {'operadorFull', 'operador1'},
    'usuarios_page': {'operadorFull', 'operador1'},

    // conductores
    'conductores_page': {'operadorFull', 'operadorSeguimientoMap', 'operador1'},

    'drivers_activity_admin_page': {
      'operadorFull',
      'operadorSeguimientoMap',
      'operador1',
    },

    'historial_viajes_page': {'operadorFull' , 'operador1'},

    'detalle_vehiculo_page': {'operadorFull', 'operador1'},
    'campanas_whatsapp_page': {'operadorFull'},
    'campanas_whatsapp_clientes_page': {'operadorFull'},

    // mapa
    'map_drivers_admin_page': {'operadorFull', 'operadorSeguimientoMap', 'operador1', 'operador2'},

    // recargas
    'recarga_info_page': {'operadorFull', 'adminRecargas' , 'contador'},

    /// 🔥 portería
    'registro_porteria_page': {'operadorFull', 'operador_bases'},
    'porterias_page': {'operadorFull', 'operador_bases'},
    'editar_porteria_page': {'operadorFull', 'operador_bases'},

    'prices_page': {'operadorFull'},
    'bonos_admin_page': {'operadorFull', 'contador'},
    'detalle_bonos_driver': {'operadorFull', 'contador'},
    'historial_bonos_page': {'operadorFull', 'contador'},

    // 🔥 WhatsApp MetaX
    'whatsapp_metax_page': {'operadorFull', 'operador1', 'operador2' },
  };

  static bool canRoleAccess(
      String role,
      String routeName,
      ) {

    final cleanRole =

    role
        .trim()
        .toLowerCase();

    if (cleanRole ==
        masterRole.toLowerCase()) {

      return true;
    }

    final allowed =
    routePermissions[routeName];

    if (allowed == null) return false;

    return allowed.any(

          (r) =>

      r.toLowerCase() ==
          cleanRole,
    );
  }
}