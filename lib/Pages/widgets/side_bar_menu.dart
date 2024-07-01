import 'package:flutter/material.dart';

import '../../providers/auth_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {

  MyAuthProvider _authProvider = MyAuthProvider();
  OperadorProvider _operadorProvider = OperadorProvider();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 1,
      child: Container(
        color: grisMapa,
        child: (
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: const EdgeInsets.only(top: 35),
                    alignment: Alignment.center,
                    child: Image.asset("assets/logo_tayrona_solo.png", width: 30, height: 30,)
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  alignment: Alignment.center,
                  child: const Text('¡Tay-rona eres tú, soy yo,\nsomos todos!', style:  TextStyle(
                      fontSize: 10,
                      color: negroLetras,
                      fontWeight: FontWeight.w500
                  ),
                    textAlign: TextAlign.center,),
                ),
                const Divider(height: 1, color: gris),
                
                Container(
                  margin : const EdgeInsets.symmetric( horizontal: 20, vertical: 10),
                  child: const Text('Panel de control', style:  TextStyle(
                      fontSize: 20,
                      color: primary,
                      fontWeight: FontWeight.w500
                  ),),
                ),

                DrawerListTitle(
                  title: "General",
                  icon: Icons.info_outline, // Icono de información
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'general_page',
                          (Route<dynamic> route) => false,
                    );
                  },
                ),

                DrawerListTitle(
                  title: "Conductores",
                  icon: Icons.directions_car, // Icono de un carro
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'conductores_page',
                          (Route<dynamic> route) => false,
                    );

                  },
                ),

                DrawerListTitle(
                  title: "Motociclistas",
                  icon: Icons.motorcycle, // Icono de una motocicleta
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'motociclistas_page',
                          (Route<dynamic> route) => false,
                    );
                  },
                ),

                DrawerListTitle(
                  title: "Usuarios",
                  icon: Icons.person, // Icono de una persona
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'usuarios_page',
                          (Route<dynamic> route) => false,
                    );

                  },
                ),
                DrawerListTitle(
                    title: "Operadores",
                    icon: Icons.headphones,
                    press: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        'operadores_page',
                            (Route<dynamic> route) => false,
                      );

                    },
                  ),

                DrawerListTitle(
                  title: "Configuraciones",
                  icon: Icons.settings, // Icono de configuraciones
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'prices_page',
                          (Route<dynamic> route) => false,
                    );

                  },
                ),

                DrawerListTitle(
                  title: "Datos operación",
                  icon: Icons.date_range_outlined, // Icono de historial
                  press: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      'viajes_realizados_page',
                          (Route<dynamic> route) => false,
                    );
                  },
                ),
                DrawerListTitle(
                    title: "Registrar Operadores",
                    icon: Icons.app_registration,
                    press: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        'signUp',
                            (Route<dynamic> route) => false,
                      );
                   },
                ),

                DrawerListTitle(
                  title: "Cerrar sesión",
                  icon: Icons.exit_to_app,
                  press: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirmación"),
                          content: Text("¿Estás seguro de que deseas cerrar sesión?"),
                          actions: <Widget>[
                            TextButton(
                              child: Text("NO"),
                              onPressed: () {
                                Navigator.of(context).pop(); // Cierra el cuadro de diálogo
                              },
                            ),
                            TextButton(
                              child: Text("SI"),
                              onPressed: () async {
                                _authProvider.signOut();
                                Navigator.of(context).pop(); // Cierra el cuadro de diálogo
                                Navigator.pushNamedAndRemoveUntil(context, 'login_page', (Route<dynamic> route) => false);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const Spacer(),

              ],
            )
        ),

      ),
    );
  }
}

class DrawerListTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback press;

  const DrawerListTitle({
    Key? key,
    required this.title,
    required this.icon,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      leading: Icon(icon), // Usa el IconData para crear el Icono
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
    );
  }
}


