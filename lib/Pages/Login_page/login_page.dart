import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                        onPressed: () => login(emailController.text.trim(), passwordController.text.trim(), context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: amarilloOscuro,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Ingresar', style: TextStyle(
                          color: Colors.black
                        ),),
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
      // Realiza el inicio de sesión con email y contraseña
      bool isLoginSuccessful = await _authProvider.login(email, password, context);
      if (isLoginSuccessful) {
        // Obtiene el usuario operador si está disponible
        Operador? operador = await _operadorProvider.getById(_authProvider.getUser()!.uid);
        if (operador != null) {
          // Verifica el estado de verificación del operador
          String? verificationStatus = await _operadorProvider.getVerificationStatus();
          if (verificationStatus == 'Procesando') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('En el momento no tienes acceso a esta cuenta')),
            );
            await _authProvider.signOut();
            return false;
          } else if (verificationStatus == 'bloqueado') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Acceso denegado')),
            );
            await _authProvider.signOut();
            return false;
          } else if (verificationStatus == 'activado') {
            _authProvider.checkIfUserIsLoggedLoginPage(context);
            return true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cuenta en verificación')),
            );
            await _authProvider.signOut();
            return false;
          }
        } else {
          // Si no es un operador válido, muestra un mensaje y cierra sesión
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Este usuario no es válido')),
          );
          await _authProvider.signOut();
          return false;
        }
      }
      return false; // Devuelve falso si el inicio de sesión no fue exitoso
    } on MyAuthProvider catch (error) {
      // Captura y muestra cualquier error del provider de autenticación personalizado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      return false;
    }
  }

}
