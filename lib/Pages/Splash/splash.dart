import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/auth_provider.dart';
import '../../src/color.dart';

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
    var d = const Duration(seconds: 4);
    Future.delayed(d, (){
      Navigator.pushNamedAndRemoveUntil(context, "login_page", (route) => false);
    });
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
