import 'open_new_tab_stub.dart'
if (dart.library.html) 'open_new_tab_web.dart';

/// Abre una ruta de tu app en otra pestaña.
/// Ej: openNewTabRoute('map_drivers_admin_page');
void openNewTabRoute(String routeName) => openNewTabRouteImpl(routeName);
