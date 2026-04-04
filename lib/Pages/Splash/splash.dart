import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/auth_provider.dart';
import '../../src/color.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import '../../providers/operador_provider.dart';
import '../../helpers/route_permissions.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late MyAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "login_page",
            (_) => false,
      );
      return;
    }

    final operadorProvider = context.read<OperadorProvider>();

    /// 🔥 cargar datos del operador
    await operadorProvider.fetchOperadorActual();

    if (!mounted) return;

    final role = (operadorProvider.rolActual ?? '').trim();
    final active = operadorProvider.activoActual;

    /// ❌ sin permisos
    if (!active || role.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "sin_permisos_page",
            (_) => false,
      );
      return;
    }

    /// 🔥 ruta según rol
    final homeRoute = _getHomeRouteByRole(role);

    /// 🔥 validar acceso real
    if (!RoutePermissions.canRoleAccess(role, homeRoute)) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "sin_permisos_page",
            (_) => false,
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
          (_) => false,
    );
  }

  String _getHomeRouteByRole(String role) {
    switch (role) {
      case 'adminRecargas':
        return 'recarga_info_page';

      case 'operadorSeguimientoMap':
        return 'map_drivers_admin_page';

      case 'operadorFull':
        return 'general_page';

      case 'Master':
        return 'general_page';

      default:
        return 'login_page';
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return  Scaffold(
      backgroundColor: gris,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              alignment: Alignment.center,
              child:  const Image(
                  height: 200.0,
                  width: 200.0,
                  image: AssetImage('assets/logo_metax_combinado.png'))),

          const Text("Administrador", style: TextStyle(
              fontFamily: 'Gilroy',
              color: negroLetras,
              fontSize: 24,
              fontWeight: FontWeight.w600
          )),
        ],
      ),
    );
  }
}
