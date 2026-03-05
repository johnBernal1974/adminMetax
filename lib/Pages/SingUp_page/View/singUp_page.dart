import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../common/main_layout.dart';
import '../../../src/color.dart';
import '../signUp_controller/signUp_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SingUpPageState();
}

class _SingUpPageState extends State<SignUpPage> {
  final SignUpController _controller = SignUpController();
  late FocusNode _nextFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _nextFieldFocusNode = FocusNode();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.init(context);
    });
  }

  @override
  void dispose() {
    _nextFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Registro",
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16),
            child: Card(
              color: blancoCards,
              surfaceTintColor: blancoCards,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Ingresar los datos del Operador",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: negro,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _nameImput(),
                    _lastNameImput(),
                    _identificationnumberImput(),
                    _celularNumberImput(),
                    _emailImput(),
                    _emailConfimImput(),
                    _passwordImput(),
                    _password2Imput(),

                    const SizedBox(height: 26),

                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 220,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _controller.signUp(),
                          icon: const Icon(Icons.save, color: Colors.white, size: 18),
                          label: const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================== TUS INPUTS (IGUAL QUE LOS TENÍAS) ==================

  Widget _nameImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.nombresController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: negro),
              Text('  Nombres', style: TextStyle(color: gris, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _lastNameImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.apellidosController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 18, color: negro),
              Text('  Apellidos', style: TextStyle(color: gris, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _identificationnumberImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        maxLength: 10,
        textCapitalization: TextCapitalization.characters,
        controller: _controller.numeroDocumentoController,
        style: const TextStyle(color: negroLetras, fontSize: 22, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.text,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          counterText: "", // ✅ para que no empuje el layout si quieres
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 18, color: negro),
              Text('  Número de identificación', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _celularNumberImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        focusNode: _nextFieldFocusNode,
        maxLength: 10,
        controller: _controller.celularController,
        style: const TextStyle(color: negroLetras, fontSize: 22, fontWeight: FontWeight.w800),
        keyboardType: TextInputType.phone,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          counterText: "",
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android_outlined, size: 20, color: negro),
              Text('  Número de celular', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _emailImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.emailController,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.emailAddress,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, size: 20, color: negro),
              Text('  Correo electrónico', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _emailConfimImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.emailConfirmarController,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.emailAddress,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_read, size: 20, color: negro),
              Text('  Confirmar Correo', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _passwordImput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.passwordController,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 20, color: negro),
              Text('  Crea una Contraseña', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }

  Widget _password2Imput() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _controller.passwordConfirmarController,
        style: const TextStyle(color: negroLetras, fontSize: 17, fontWeight: FontWeight.w700),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        cursorColor: const Color.fromARGB(255, 34, 110, 181),
        decoration: const InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_sharp, size: 20, color: negro),
              Text('  Confirmar Contraseña', style: TextStyle(color: negro, fontSize: 17, fontWeight: FontWeight.w400)),
            ],
          ),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: grisMedio, width: 1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: negro, width: 2)),
        ),
      ),
    );
  }
}