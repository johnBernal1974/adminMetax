import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/operador_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final MyAuthProvider _authProvider = MyAuthProvider();
  final OperadorProvider _operadorProvider = OperadorProvider();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gris,
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(
          color: Colors.black, fontWeight: FontWeight.bold
        ),),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Espacio entre la imagen y el formulario
                const SizedBox(height: 50.0),

                // Imagen en la parte superior
                Container(
                  alignment: Alignment.topCenter,
                  margin: const EdgeInsets.only(top: 16.0),
                  child: Image.asset(
                    'assets/logo_metax_combinado.png', // Ajusta la ruta según la ubicación de tu imagen
                    height: 50.0,
                    fit: BoxFit.contain,
                  ),
                ),

                // Formulario de login
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () async {
                          final ok = await login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                            context,
                          );

                          if (!context.mounted) return;

                          if (!ok) return;

                          final operadorProvider = context.read<OperadorProvider>();

                          // ✅ Carga rol/activo del operador logueado
                          await operadorProvider.fetchOperadorActual();
                          if (!context.mounted) return;

                          final role = (operadorProvider.rolActual ?? '').trim();
                          final active = operadorProvider.activoActual;

                          // ✅ Si no está activo o no tiene rol
                          if (!active || role.isEmpty) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              'sin_permisos_page',
                                  (_) => false,
                            );
                            return;
                          }

                          // ✅ Decide a qué página llevarlo según el rol
                          String homeRoute;
                          if (role == 'Master' || role == 'operadorFull') {
                            homeRoute = 'general_page';
                          } else if (role == 'adminRecargas') {
                            homeRoute = 'recarga_info_page';
                          } else if (role == 'operadorSeguimientoMap') {
                            homeRoute = 'map_drivers_admin_page';
                          } else {
                            homeRoute = 'sin_permisos_page';
                          }

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            homeRoute,
                                (_) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: amarilloOscuro,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> login(String email, String password, BuildContext context) async {
    try {
      final isLoginSuccessful = await _authProvider.login(email, password, context);
      if (!isLoginSuccessful) return false;

      print("UID AUTH******************: ${FirebaseAuth.instance.currentUser?.uid}");

      final uid = _authProvider.getUser()?.uid;
      if (uid == null) return false;

      final operador = await _operadorProvider.getById(uid);
      if (operador == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este usuario no es válido')),
          );
        }
        await _authProvider.signOut();
        return false;
      }

      final verificationStatus = await _operadorProvider.getVerificationStatus();

      // ✅ OJO: después de await, valida context
      if (!context.mounted) return false;

      if (verificationStatus == 'Procesando') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En el momento no tienes acceso a esta cuenta')),
        );
        await _authProvider.signOut();
        return false;
      }

      if (verificationStatus == 'bloqueado') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso denegado')),
        );
        await _authProvider.signOut();
        return false;
      }

      if (verificationStatus == 'activado') {
        // ✅ Aquí ya NO navegamos desde provider
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta en verificación')),
      );
      await _authProvider.signOut();
      return false;

    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
      return false;
    }
  }

  String _homeByRole(String role) {
    if (role == 'Master') return 'general_page';
    if (role == 'operadorFull') return 'general_page';
    if (role == 'adminRecargas') return 'recarga_info_page';
    if (role == 'operadorSeguimientoMap') return 'map_drivers_admin_page';

    // si cae aquí, no tiene home definido
    return 'sin_permisos_page'; // o login_page
  }

}
