import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tay_rona_administrador/Pages/MotociclistasPage/moticlistas_page.dart';
import 'package:tay_rona_administrador/Pages/OperadoresPage/operadores_page.dart';
import 'package:tay_rona_administrador/Pages/PricesPage/prices_page.dart';
import 'package:tay_rona_administrador/Pages/UsuariosPage/usuarios_page.dart';
import 'package:tay_rona_administrador/providers/client_provider.dart';
import 'package:tay_rona_administrador/providers/operador_provider.dart';
import 'package:tay_rona_administrador/providers/prices_provider.dart';
import 'package:tay_rona_administrador/src/color.dart';
import 'Pages/Login_page/login_page.dart';
import 'Pages/ConductoresPage/conductores_page.dart';
import 'Pages/GeneralPage/general_page.dart';
import 'Pages/SingUp_page/View/singUp_page.dart';
import 'Pages/Splash/splash.dart';
import 'Pages/paginasExternasPage/verificacion_antecedentes_page.dart';
import 'controllers/menu_controller.dart';
import 'providers/driver_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Inicialización específica para la web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDgVNuJAV4Ocn2qq6FoZFVLOCOOm2kIPRE",
        authDomain: "tay-rona-flutter.firebaseapp.com",
        projectId: "tay-rona-flutter",
        storageBucket: "tay-rona-flutter.appspot.com",
        messagingSenderId: "427872411983",
        appId: "1:427872411983:web:69b8bf9abc898e2ff3a53a",
      ),
    );
  } else {
    // Inicialización para móvil
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyMenuController()),
        ChangeNotifierProvider(create: (context) => DriverProvider()), // Agregado aquí
        ChangeNotifierProvider(create: (context) => ClientProvider()), // Agregado aquí
        ChangeNotifierProvider(create: (context) => OperadorProvider()), // Agregado aquí

      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: primary,
            fontFamily: 'Poppins'
        ),
        // Establece la ruta inicial en la página de login
        initialRoute: 'splash',
        routes: {
          'login_page': (context) => LoginPage(),
          'signUp': (context) => SignUpPage(),
          'general_page': (context) => GeneralPage(),
          'conductores_page': (context) => ConductoresPage(),
          'motociclistas_page': (context) => MotociclistasPage(),
          'usuarios_page': (context) => const UsuariosPage(),
          'operadores_page': (context) => const OperadoresPage(),
          'antecedentes_page': (context) => const Paginaantecedentes(),
          'prices_page': (context) => PricesPage(),
          'splash': (context) => const Splash(),
          // Añade aquí otras rutas necesarias
        },
      ),
    );
  }
}
