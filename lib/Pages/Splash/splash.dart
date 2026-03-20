import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/auth_provider.dart';
import '../../src/color.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late MyAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "general_page",
            (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "login_page",
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return  Scaffold(
      backgroundColor: gris,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              alignment: Alignment.center,
              child:  const Image(
                  height: 200.0,
                  width: 200.0,
                  image: AssetImage('assets/logo_metax_combinado.png'))),

          const Text("Administrador", style: TextStyle(
              fontFamily: 'Gilroy',
              color: negroLetras,
              fontSize: 24,
              fontWeight: FontWeight.w600
          )),
        ],
      ),
    );
  }
}
