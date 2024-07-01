
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tay_rona_administrador/providers/operador_provider.dart';

import '../models/operador_model.dart';
import '../src/color.dart';

class MyAuthProvider {
  late FirebaseAuth _firebaseAuth;
  OperadorProvider _operadorProvider = OperadorProvider(); // Instancia de OperadorProvider



  MyAuthProvider(){
    _firebaseAuth = FirebaseAuth.instance;
  }

  BuildContext? get context => null;



  Future<bool> login(String email, String password, BuildContext context) async {
    String? errorMessage;

    try{
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    }on FirebaseAuthException catch (error){
      print('Errorxxx: ${error.code} \n ${error.message}');
      errorMessage = _getErrorMessage(error.code);
      showSnackbar(context!, errorMessage);
      return false;
    }
    return true;
  }

  String _getErrorMessage(String errorCode) {
    // Mapeo de los códigos de error a mensajes en español
    Map<String, String> errorMessages = {
      'user-not-found': 'Usuario no encontrado. Verifica tu correo electrónico.',
      'wrong-password': 'Contraseña incorrecta. Inténtalo de nuevo.',
      'invalid-email': 'La dirección de correo electrónico no tiene el formato correcto.',
      'user-disabled': 'La cuenta de usuario ha sido deshabilitada.',
      'invalid-credential': 'Las credenciales proporcionadas no son válidas.',
      'network-request-failed': 'Sin señal. Revisa tu conexión de INTERNET.',
    };

    return errorMessages[errorCode] ?? 'Error desconocido';
  }

  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: rojo,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  User? getUser(){
    return _firebaseAuth.currentUser;
  }

  void checkIfUserIsLogged(BuildContext? context) {
    if (context != null) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          print('El operador está logueado');

          Operador? operador = await _operadorProvider.getById(user.uid);
          if (operador != null) {
            String? verificationStatus = await _operadorProvider.getVerificationStatus();
            if (verificationStatus == 'Procesando') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('En el momento no tienes acceso a esta cuenta')),
              );
              return;
            } else if (verificationStatus == 'bloqueado') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Acceso denegado')),
              );
              return;
            } else if (verificationStatus == 'activado') {
              Navigator.pushNamedAndRemoveUntil(context, 'general_page', (route) => false);
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cuenta en verificación')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Este usuario no es válido')),
            );
            await signOut();
          }
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "login", (route) => false);
          print('El usuario NO está logueado');
        }
      });
    }
  }


  void checkIfUserIsLoggedLoginPage(BuildContext context){
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if(user != null){
        print('El usuario esta logueado');
        Navigator.pushNamedAndRemoveUntil(context, "general_page", (route) => false);
      }
    });
  }

  Future<bool> signUp(String email, String password) async {
    String? errorMessage;

    try{
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    }on FirebaseAuthException catch(error){
      errorMessage = error.code;
      print('ErrorMessage2: $errorMessage');
      rethrow;
    }
    return true;
  }

  Future<Future<List<void>>> signOut() async {
    return Future.wait([_firebaseAuth.signOut()]);

  }

}
