import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metax_administrador/providers/client_provider.dart';
import 'package:metax_administrador/providers/operador_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metax_administrador/Pages/HistorialViajesPage/historia_viajes_page.dart';
import 'package:metax_administrador/Pages/InfoRecargas/info_recargas.dart';
import 'package:metax_administrador/src/color.dart';
import 'Pages/Login_page/login_page.dart';
import 'Pages/ConductoresPage/conductores_page.dart';
import 'Pages/GeneralPage/general_page.dart';
import 'Pages/OperadoresPage/operadores_page.dart';
import 'Pages/PricesPage/prices_page.dart';
import 'Pages/SinPermisos/sin_permisos_page.dart';
import 'Pages/SingUp_page/View/singUp_page.dart';
import 'Pages/Splash/splash.dart';
import 'Pages/UsuariosPage/usuarios_page.dart';
import 'Pages/adminMapDriversPage/adminMapDriversPage.dart';
import 'Pages/paginasExternasPage/verificacion_antecedentes_page.dart';
import 'controllers/menu_controller.dart';
import 'providers/driver_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ IMPORTA el guard (debes crear este archivo)
import 'helpers/admin_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('es_ES', null);

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCXELqMHM7D8lT-0kexYu4jfqehfLNoRC0',
        appId: '1:632604677797:web:1fb92982ee10663c3d1f4c',
        messagingSenderId: '632604677797',
        projectId: 'apptaxi-e641d',
        authDomain: 'apptaxi-e641d.firebaseapp.com',
        storageBucket: 'apptaxi-e641d.firebasestorage.app',
        measurementId: 'G-VBGVGQZ8KG',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Ruta normal (sin guard)
  Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  // 🔒 Ruta protegida: si no es operador permitido -> Login
  Route<dynamic> _guardedRoute(Widget page, RouteSettings settings) {
    final raw = settings.name ?? '';
    final routeName = raw.startsWith('/') ? raw.substring(1) : raw;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        return FutureBuilder<bool>(
          future: AdminGuard.canAccess(routeName),
          builder: (context, snap) {

            if (snap.connectionState != ConnectionState.done) {
              return const Splash();
            }

            if (snap.data != true) {
              return const SinPermisosPage(); // 🔥 mejor UX
            }

            return page;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyMenuController()),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
        ChangeNotifierProvider(create: (context) => OperadorProvider()),
      ],
      child: MaterialApp(
        title: 'Metax Administrador',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primaryColor: primary, fontFamily: 'Poppins'),

        // ✅ se mantiene tu inicial
        initialRoute: 'splash',

        // ✅ Reemplaza routes: {} por onGenerateRoute (para poder proteger)
        onGenerateRoute: (settings) {
          final raw = settings.name ?? '';
          final name = raw.startsWith('/') ? raw.substring(1) : raw;

          // =========================
          // RUTAS PÚBLICAS
          // =========================
          if (name == 'splash') return _buildRoute(const Splash(), settings);
          if (name == 'login_page') return _buildRoute(LoginPage(), settings);
          if (name == 'signUp') return _buildRoute(SignUpPage(), settings);

          // =========================
          // RUTAS PROTEGIDAS (ADMIN)
          // =========================
          if (name == 'general_page') return _guardedRoute(GeneralPage(), settings);
          if (name == 'conductores_page') return _guardedRoute(ConductoresPage(), settings);
          if (name == 'usuarios_page') return _guardedRoute(const UsuariosPage(), settings);
          if (name == 'operadores_page') return _guardedRoute(const OperadoresPage(), settings);
          if (name == 'antecedentes_page') return _guardedRoute(const Paginaantecedentes(), settings);
          if (name == 'prices_page') return _guardedRoute(PricesPage(), settings);
          if (name == 'recarga_info_page') return _guardedRoute(AdminTransaccionesPage(), settings);
          if (name == 'historial_viajes_page') return _guardedRoute(const TravelHistoryPage(), settings);
          if (name == 'map_drivers_admin_page') return _guardedRoute(const AdminDriversMapPage(), settings);

          // =========================
          // DEFAULT
          // =========================
          return _buildRoute(LoginPage(), settings);
        },

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'CO'),
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}