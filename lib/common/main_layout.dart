import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tay_rona_administrador/providers/auth_provider.dart';
import 'package:tay_rona_administrador/src/color.dart';
import '../Pages/widgets/side_bar_menu.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final String pageTitle; // Nuevo atributo para el título dinámico

  const MainLayout({Key? key, required this.content, required this.pageTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: grisMapa,
      drawer: MediaQuery.of(context).size.width < 800 ? const SideBar() : null,
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(color: blanco),),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: blanco),// Usar el atributo pageTitle para el título
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            const SizedBox(
              width: 300,
              child: SideBar(),
            ),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}
