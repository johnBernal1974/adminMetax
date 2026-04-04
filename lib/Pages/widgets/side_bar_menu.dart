import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import '../../helpers/route_permissions.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final MyAuthProvider _authProvider = MyAuthProvider();

  bool _canSee(String role, String routeName) {
    return RoutePermissions.canRoleAccess(role, routeName);
  }

  void _go(String routeName) {
    Navigator.pop(context); // ✅ cierra drawer
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperadorProvider>();

    final role = (op.rolActual ?? '').trim();
    final active = op.activoActual;

    // ✅ cuando aún no ha cargado rol o está inactivo
    final restricted = role.isEmpty;

    return Drawer(
      elevation: 1,
      child: Container(
        color: gris,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              alignment: Alignment.center,
              child: Image.asset(
                "assets/logo_metax_combinado.png",
                width: 150,
                height: 150,
              ),
            ),
            const Divider(height: 1, color: gris),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Panel de control',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            // ✅ Si no está autorizado, muestra aviso y solo logout
            if (restricted) ...[
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.lock, color: Colors.white),
                title: Text(
                  'Acceso restringido',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  'Inicia sesión con una cuenta habilitada.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const Divider(height: 10, color: Colors.white24),
            ] else ...[
              // =========================
              // ITEMS FILTRADOS POR ROL
              // =========================

              if (_canSee(role, 'map_drivers_admin_page'))
                DrawerListTitle(
                  title: "Mapa conductores",
                  icon: Icons.map_outlined,
                  press: () => _go('map_drivers_admin_page'),
                ),

              if (_canSee(role, 'general_page'))
                DrawerListTitle(
                  title: "General",
                  icon: Icons.dashboard_outlined,
                  press: () => _go('general_page'),
                ),

              if (_canSee(role, 'conductores_page'))
                DrawerListTitle(
                  title: "Conductores",
                  icon: Icons.person,
                  press: () => _go('conductores_page'),
                ),

              if (_canSee(role, 'usuarios_page'))
                DrawerListTitle(
                  title: "Usuarios",
                  icon: Icons.emoji_people,
                  press: () => _go('usuarios_page'),
                ),
              // if (_canSee(role, 'vehiculos_page'))
              //   DrawerListTitle(
              //     title: "Vehículos",
              //     icon: Icons.directions_car,
              //     press: () => _go('vehiculos_page'),
              //   ),

              // if (_canSee(role, 'prices_page'))
              //   DrawerListTitle(
              //     title: "Configuraciones",
              //     icon: Icons.settings,
              //     press: () => _go('prices_page'),
              //   ),

              if (_canSee(role, 'recarga_info_page'))
                DrawerListTitle(
                  title: "Info Recargas",
                  icon: Icons.payments_outlined,
                  press: () => _go('recarga_info_page'),
                ),

              if (_canSee(role, 'historial_viajes_page'))
                DrawerListTitle(
                  title: "Historial de viajes",
                  icon: Icons.list_alt_outlined,
                  press: () => _go('historial_viajes_page'),
                ),

              //MASTER

              if (role == 'Master')
                DrawerListTitle(
                  title: "Operadores",
                  icon: Icons.headphones,
                  press: () => _go('operadores_page'),
                ),

              if (role == 'Master')
                DrawerListTitle(
                  title: "Registrar Operadores",
                  icon: Icons.app_registration,
                  press: () => _go('signUp'),
                ),

              if (role == 'Master')
                DrawerListTitle(
                  title: "Porterías",
                  icon: Icons.apartment,
                  press: () => _go('porterias_page'),
                ),

              if (role == 'Master')
                DrawerListTitle(
                  title: "Registrar Porterías",
                  icon: Icons.apartment,
                  press: () => _go('registro_porteria_page'),
                ),

              if (role == 'Master')
                DrawerListTitle(
                  title: "Configuraciones",
                  icon: Icons.settings,
                  press: () => _go('prices_page'),
                ),

              if (role == 'Master')
                DrawerListTitle(
                  title: "Vehículos",
                  icon: Icons.directions_car,
                  press: () => _go('vehiculos_page'),
                ),
            ],

            const Divider(height: 10, color: Colors.white24),

            DrawerListTitle(
              title: "Cerrar sesión",
              icon: Icons.exit_to_app,
              press: () async {
                // ✅ guarda el root navigator ANTES de awaits
                final rootNav = Navigator.of(context, rootNavigator: true);

                final confirm = await showDialog<bool>(
                  context: context,
                  useRootNavigator: true,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text("Confirmación"),
                      content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
                      actions: <Widget>[
                        TextButton(
                          child: const Text("NO"),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                        TextButton(
                          child: const Text("SI"),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    );
                  },
                );

                if (confirm != true) return;

                // ✅ 1) cerrar sesión (espera)
                await _authProvider.signOut();

                // ✅ 2) limpia provider (si lo usas)
                if (context.mounted) {
                  context.read<OperadorProvider>().clearOperadorActual();
                }

                // ✅ 3) navega al login con root navigator
                rootNav.pushNamedAndRemoveUntil(
                  'login_page',
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerListTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback press;

  const DrawerListTitle({
    super.key,
    required this.title,
    required this.icon,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}