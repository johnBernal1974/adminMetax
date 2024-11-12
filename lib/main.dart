import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zafiro_administrador/Pages/InfoRecargas/info_recargas.dart';
import 'package:zafiro_administrador/providers/client_provider.dart';
import 'package:zafiro_administrador/providers/operador_provider.dart';
import 'package:zafiro_administrador/src/color.dart';
import 'Pages/Login_page/login_page.dart';
import 'Pages/ConductoresPage/conductores_page.dart';
import 'Pages/GeneralPage/general_page.dart';
import 'Pages/MotociclistasPage/moticlistas_page.dart';
import 'Pages/OperadoresPage/operadores_page.dart';
import 'Pages/PricesPage/prices_page.dart';
import 'Pages/SingUp_page/View/singUp_page.dart';
import 'Pages/Splash/splash.dart';
import 'Pages/UsuariosPage/usuarios_page.dart';
import 'Pages/paginasExternasPage/verificacion_antecedentes_page.dart';
import 'controllers/menu_controller.dart';
import 'providers/driver_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Inicialización específica para la web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDZyI0VVcdENZoRTwW5Ze3bQYRLQgp_Xl0",
          authDomain: "transport-f7c79.firebaseapp.com",
          projectId: "transport-f7c79",
          storageBucket: "transport-f7c79.appspot.com",
          messagingSenderId: "776719847961",
          appId: "1:776719847961:web:2f69301d843863172a5088",
          measurementId: "G-0P5JXEVERY"
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
        title: 'Zafiro Administrador',
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
          'recarga_info_page': (context) => RecargaPage(),
          // Añade aquí otras rutas necesarias
        },
      ),
    );
  }
}
