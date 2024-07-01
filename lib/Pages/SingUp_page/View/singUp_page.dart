
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../src/color.dart';
import '../../../src/color.dart';
import '../../../src/color.dart';
import '../signUp_controller/signUp_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SingUpPageState();
}


class _SingUpPageState extends State<SignUpPage> {
  final SignUpController _controller = SignUpController();
  final TextEditingController _date = TextEditingController();
  late FocusNode _nextFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.init(context);
      _nextFieldFocusNode = FocusNode();
    });
  }

  @override
  void dispose() {
    _nextFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _controller.key,
      appBar: AppBar(
        backgroundColor: blancoCards,
        iconTheme: const IconThemeData(color: negro, size: 30),
        title: const Text('Registro', style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w500,
            color: negro
        )),

      ),
      body:
      SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.only(left: 30,bottom: 5),
                  child: const Text("Igresar los datos del Operador",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: negro
                    ),
                  ),
                ),
                _nameImput(),
                _lastNameImput(),
                _identificationnumberImput(),
                _celularNumberImput(),
                _emailImput(),
                _emailConfimImput(),
                _passwordImput(),
                _password2Imput(),
                SizedBox(height: 50),
                Container(
                  width: 200,
                  margin: EdgeInsets.only(bottom: 30),
                  child: ElevatedButton(
                    onPressed: () {
                      _controller.signUp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        controller: _controller.nombresController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: negro),
              Text('  Nombres', style: TextStyle(color: gris,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),

      ),
    );
  }

  Widget _lastNameImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child:TextField(
        controller: _controller.apellidosController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 18, color: negro),
              Text('  Apellidos', style: TextStyle(color: gris,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2),

          ),
        ),

      ),
    );
  }

  Widget _identificationnumberImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        maxLength: 10,
        textCapitalization: TextCapitalization.characters,
        controller: _controller.numeroDocumentoController,
        style: const TextStyle(
            color: negroLetras, fontSize: 22, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 18, color: negro),
              Text('  Número de identificación', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),


        ),

      ),
    );
  }


  Widget _celularNumberImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        focusNode: _nextFieldFocusNode,
        maxLength: 10,
        controller: _controller.celularController,
        style: const TextStyle(
            color: negroLetras, fontSize: 22, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.phone,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android_outlined, size: 20, color: negro),
              Text('  Número de celular', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),

      ),
    );
  }

  Widget _emailImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        controller: _controller.emailController,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.emailAddress,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, size: 20, color: negro),
              Text('  Correo electrónico', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),

      ),
    );
  }

  Widget _emailConfimImput() {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        controller: _controller.emailConfirmarController,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.emailAddress,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_read, size: 20, color: negro),
              Text('  Confirmar Correo', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),

      ),
    );
  }

  Widget _passwordImput (){
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        controller: _controller.passwordController,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 20, color: negro),
              Text('  Crea una Contraseña', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),

      ),
    );
  }

  Widget _password2Imput (){
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, top: 20),
      child: TextField(
        controller: _controller.passwordConfirmarController,
        style: const TextStyle(
            color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),

        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_sharp, size: 20, color: negro),
              Text('  Confirmar Contraseña', style: TextStyle(color: negro,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),)
            ],
          ),
          prefixIconColor: negro,
          border:  OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: grisMedio, width: 1)
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: negro, width: 2)
          ),
        ),
      ),
    );
  }


}

