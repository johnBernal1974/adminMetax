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
import 'Pages/SingUp_page/View/singUp_page.dart';
import 'Pages/Splash/splash.dart';
import 'Pages/UsuariosPage/usuarios_page.dart';
import 'Pages/paginasExternasPage/verificacion_antecedentes_page.dart';
import 'controllers/menu_controller.dart';
import 'providers/driver_provider.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('es_ES', null);
  if (kIsWeb) {
    // Inicialización específica para la web
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
        title: 'Metax Administrador',
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
          'usuarios_page': (context) => const UsuariosPage(),
          'operadores_page': (context) => const OperadoresPage(),
          'antecedentes_page': (context) => const Paginaantecedentes(),
          'prices_page': (context) => PricesPage(),
          'splash': (context) => const Splash(),
          'recarga_info_page': (context) => RecargaPage(),
          'historial_viajes_page': (context) => const TravelHistoryPage(),
          // Añade aquí otras rutas necesarias
        },
      ),
    );
  }
}
