
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/operador_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/operador_provider.dart';
import '../../../src/color.dart';

class SignUpController{

 late BuildContext  context;
 GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();

  TextEditingController nombresController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController numeroDocumentoController = TextEditingController();
  TextEditingController celularController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController emailConfirmarController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmarController = TextEditingController();


  String tipoDocumento= "";
  late MyAuthProvider _authProvider;
  late OperadorProvider _operadorProvider;

  Future? init (BuildContext context) {
  this.context = context;
  _authProvider = MyAuthProvider();
  _operadorProvider = OperadorProvider();
  return null;
  }

  void signUp() async {
    String nombres= nombresController.text;
    String apellidos= apellidosController.text;
    String numeroDocumento= numeroDocumentoController.text;
    String celular= celularController.text;
    String email= emailController.text.trim();
    String emailConfirmar= emailConfirmarController.text.trim();
    String password= passwordController.text.trim();
    String passwordConfirmar= passwordConfirmarController.text.trim();



    if(nombres.isEmpty && apellidos.isEmpty && numeroDocumento.isEmpty && celular.isEmpty && email.isEmpty
        && emailConfirmar.isEmpty && password.isEmpty && passwordConfirmar.isEmpty ){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos los campos estan vacios')),
      );
      return;
    }

    if(nombres.isEmpty ){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Nombres" está vacio')),
      );

      return;
    }

    if(apellidos.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Apellidos" está vacio')),
      );

      return;
    }

    if(numeroDocumento.isEmpty ){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Número de identificación" está vacio')),
      );
      return;
    }

    if(celular.isEmpty ){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Celular" está vacio')),
      );
      return;
    }


    if(email.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Correo electrónico" está vacio')),
      );
      return;
    }
    if(emailConfirmar.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Confirmar el Correo electrónico" está vacio')),
      );
      return;
    }

    if(password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Crear contraseña" está vacio')),
      );
      return;
    }

    if(passwordConfirmar.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El campo "Confirmar contraseña" está vacio')),
      );
      return;
    }

    if(passwordConfirmar != password){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    if(celular.length < 10){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El número de celular no es un número válido.')),
      );
      return;
    }
    if(numeroDocumento.length < 7){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El número de identidad no es un número válido.')),
      );
      return;
    }

    if(password.length < 6){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La contraseña debe tener mínimo 6 caracteres')),
      );
      return;
    }

    if(email != emailConfirmar){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las direcciones de correo no coinciden')),
      );
      return;
    }

    try{
     bool isSignUp =  await _authProvider.signUp(email, password);
     if(isSignUp){
        Operador operador = Operador(
            id: _authProvider.getUser()!.uid,
            the01Nombres: nombres,
            the02Apellidos: apellidos,
            the04NumeroDocumento: numeroDocumento,
            the05TipoDocumento: "",
            the06Email: email,
            the07Celular: celular,
            the11FechaActivacion: "",
            the12NombreActivador: "",
            the20Rol: "",
            image: "",
            verificacionStatus: "registrado",

        );
       await _operadorProvider.create(operador);
       print('El operador se registro correctamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El operador se registro correctamente')),
        );
        Navigator.of(context).pop();

     }else{
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('El operador no se pudo registrar')),
       );


     }

    }catch (error) {
      print('Error durante el registro***CONTROLLER: $error');

      if (error is FirebaseAuthException) {
        if (error.code == 'email-already-in-use') {
          print('Correo electrónico ya en uso XXXCONTROLLER');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El correo electrónico ya está en uso por otra cuenta.')),
          );

        } else {
          print('Otro tipo de error de autenticación: ${error.code}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ocurrió un error durante el registro. Por favor, inténtalo nuevamente.')),
          );

        }
      } else {
        print('Otro tipo de error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error durante el registro. Por favor, inténtalo nuevamente.')),
        );

      }
    }
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
}

